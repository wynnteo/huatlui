import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/price_point.dart';
import 'portfolio_repository.dart';
import 'price_providers.dart';

class PriceRefreshResult {
  final int updated;
  final int failed;
  final List<String> failedSymbols;
  const PriceRefreshResult({this.updated = 0, this.failed = 0, this.failedSymbols = const []});
}

class _Target {
  final String symbol;
  final String name;
  final String currency;
  final AssetClass assetClass;
  final DateTime since;
  const _Target(this.symbol, this.name, this.currency, this.assetClass, this.since);
}

/// Pulls fresh prices and stores them. Screens only listen to [repo] (for the
/// numbers) and to this (for the "updating..." state).
///
/// One request per symbol, not per holding: the same ticker held in two
/// brokers is fetched once and applied to both.
class PriceController extends ChangeNotifier {
  final PortfolioRepository repo;
  final PriceProvider stocks;
  final PriceProvider funds;

  PriceController({
    required this.repo,
    PriceProvider? stocks,
    PriceProvider? funds,
  })  : stocks = stocks ?? YahooPriceProvider(),
        funds = funds ?? FundPriceProvider();

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  /// The most recent time any holding's price was refreshed.
  DateTime? get lastUpdated {
    DateTime? latest;
    for (final h in repo.holdings) {
      final t = h.priceUpdatedAt;
      if (t != null && (latest == null || t.isAfter(latest))) latest = t;
    }
    return latest;
  }

  /// Called on app start: only hits the network if prices are old.
  Future<void> refreshIfStale({Duration maxAge = const Duration(minutes: 15)}) async {
    if (repo.trades.isEmpty) return;
    final last = lastUpdated;
    if (last != null && DateTime.now().difference(last) < maxAge) return;
    await refreshAll();
  }

  Future<PriceRefreshResult?> refreshAll() async {
    if (_refreshing) return null;
    _refreshing = true;
    notifyListeners();
    try {
      return await _refresh();
    } catch (_) {
      return const PriceRefreshResult(failed: 1);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<PriceRefreshResult> _refresh() async {
    final trades = repo.trades;
    if (trades.isEmpty) return const PriceRefreshResult();

    // 1. Work out what to fetch: one target per distinct symbol.
    final targets = <String, _Target>{};
    for (final t in trades) {
      final key = t.symbol.toUpperCase();
      final existing = targets[key];
      if (existing != null) {
        if (t.tradeDate.isBefore(existing.since)) {
          targets[key] = _Target(existing.symbol, existing.name, existing.currency, existing.assetClass, t.tradeDate);
        }
        continue;
      }
      HoldingRecord? meta;
      for (final h in repo.holdings) {
        if (h.symbol.toUpperCase() == key) {
          meta = h;
          break;
        }
      }
      targets[key] = _Target(
        t.symbol,
        meta?.name ?? t.symbol,
        meta?.currency ?? t.currency,
        meta?.assetClass ?? AssetClass.stock,
        t.tradeDate,
      );
    }
    targets.removeWhere((_, tg) => tg.assetClass == AssetClass.cash); // nothing to price

    // 2. Fetch, a few at a time so we stay polite to the sources.
    final results = <String, PriceQuote>{};
    var failed = 0;
    final failedNames = <String>[];
    final list = targets.entries.toList();
    for (var i = 0; i < list.length; i += 4) {
      final chunk = list.sublist(i, math.min(i + 4, list.length));
      await Future.wait(chunk.map((e) async {
        final tg = e.value;
        final isFund = tg.assetClass == AssetClass.unitTrust;
        try {
          final q = await (isFund ? funds : stocks).fetch(
            PriceRequest(symbol: tg.symbol, name: tg.name, currency: tg.currency, since: tg.since),
          );
          if (q == null) {
            failed++;
            failedNames.add(tg.symbol);
            return;
          }
          // Never apply a price quoted in a different currency than the holding.
          if (!isFund && q.currency != null && q.currency!.toUpperCase() != tg.currency.toUpperCase()) {
            failed++;
            failedNames.add(tg.symbol);
            return;
          }
          results[e.key] = q;
        } catch (_) {
          failed++;
          failedNames.add(tg.symbol);
        }
      }));
    }

    // 3. Save everything in one write.
    final now = DateTime.now();
    final updates = <HoldingRecord>[];
    final seen = <String>{};
    for (final t in trades) {
      final recKey = HoldingRecord.keyOf(t.accountId, t.symbol);
      if (!seen.add(recKey)) continue;
      final q = results[t.symbol.toUpperCase()];
      if (q == null) continue;
      final tg = targets[t.symbol.toUpperCase()]!;
      final record = repo.holdingFor(t.accountId, t.symbol) ??
          HoldingRecord(
            id: const Uuid().v4(),
            accountId: t.accountId,
            symbol: t.symbol,
            name: tg.name,
            assetClass: tg.assetClass,
            currency: tg.currency,
            currentPrice: q.price,
          );
      updates.add(record.copyWith(currentPrice: q.price, priceUpdatedAt: now));
    }
    final history = {for (final e in results.entries) e.key: e.value.history};
    await repo.applyPriceRefresh(updates, history);

    return PriceRefreshResult(updated: results.length, failed: failed, failedSymbols: failedNames);
  }
}
