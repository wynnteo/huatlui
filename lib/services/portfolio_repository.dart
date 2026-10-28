import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/dividend.dart';
import '../models/holding_record.dart';
import '../models/price_point.dart';
import '../models/trade.dart';
import 'csv_import.dart';
import 'activity.dart';
import 'demo_data.dart';

/// Local storage for the POC. Everything is saved as plain JSON maps in
/// Hive boxes (no type adapters, so no build_runner step), and kept in
/// memory as lists that screens listen to.
///
/// Later, an API-backed implementation can replace this class without the
/// screens changing: they only ever read the lists and call these methods.
class PortfolioRepository extends ChangeNotifier {
  late final Box<dynamic> _accountsBox;
  late final Box<dynamic> _holdingsBox;
  late final Box<dynamic> _tradesBox;
  late final Box<dynamic> _dividendsBox;
  late final Box<dynamic> _priceBox;

  List<Account> accounts = [];
  List<HoldingRecord> holdings = [];
  List<Trade> trades = [];
  List<Dividend> dividends = [];

  /// Daily closing prices per symbol (upper-case), oldest first. Stocks get
  /// the full history from Yahoo; unit trusts build up one snapshot per refresh.
  Map<String, List<PricePoint>> priceHistory = {};

  Future<void> init() async {
    await Hive.initFlutter();
    _accountsBox = await Hive.openBox<dynamic>('accounts');
    _holdingsBox = await Hive.openBox<dynamic>('holdings');
    _tradesBox = await Hive.openBox<dynamic>('trades');
    _dividendsBox = await Hive.openBox<dynamic>('dividends');
    _priceBox = await Hive.openBox<dynamic>('price_history');
    _reload();
    _reloadPrices();
  }

  Map<String, dynamic> _asMap(dynamic v) => Map<String, dynamic>.from(v as Map);

  void _reload() {
    accounts = _accountsBox.values.map((e) => Account.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    holdings = _holdingsBox.values.map((e) => HoldingRecord.fromJson(_asMap(e))).toList();
    trades = _tradesBox.values.map((e) => Trade.fromJson(_asMap(e))).toList();
    dividends = _dividendsBox.values.map((e) => Dividend.fromJson(_asMap(e))).toList();
  }

  void _reloadPrices() {
    final map = <String, List<PricePoint>>{};
    for (final k in _priceBox.keys) {
      final raw = _priceBox.get(k);
      if (raw is! List) continue;
      final list = <PricePoint>[];
      for (final e in raw) {
        list.add(PricePoint.fromJson(e));
      }
      list.sort((a, b) => a.date.compareTo(b.date));
      map[k as String] = list;
    }
    priceHistory = map;
  }

  /// Saves a whole price refresh in one go: new prices on the holdings, and
  /// the day-by-day history merged into what is already stored (newer wins).
  Future<void> applyPriceRefresh(List<HoldingRecord> updatedHoldings, Map<String, List<PricePoint>> history) async {
    for (final h in updatedHoldings) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final e in history.entries) {
      final merged = <int, double>{};
      for (final p in priceHistory[e.key] ?? const <PricePoint>[]) {
        merged[p.date.millisecondsSinceEpoch] = p.price;
      }
      for (final p in e.value) {
        merged[p.date.millisecondsSinceEpoch] = p.price;
      }
      final days = merged.keys.toList()..sort();
      await _priceBox.put(e.key, [
        for (final d in days) [d, merged[d]!],
      ]);
    }
    _reloadPrices();
    await _changed();
  }

  Future<void> _changed() async {
    _reload();
    notifyListeners();
  }

  HoldingRecord? holdingFor(String accountId, String symbol) {
    final key = HoldingRecord.keyOf(accountId, symbol);
    for (final h in holdings) {
      if (h.key == key) return h;
    }
    return null;
  }

  /// Writes everything from a CSV import in one go (one reload, one notify).
  Future<void> applyImport(ImportPlan plan) async {
    // Validate the complete post-import history before making any writes.
    if (!tradesAreConsistent([...trades, ...plan.trades])) {
      throw StateError('Import would create a sale exceeding available shares');
    }
    for (final a in plan.newAccounts) {
      await _accountsBox.put(a.id, a.toJson());
    }
    for (final h in plan.holdingUpserts) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final t in plan.trades) {
      await _tradesBox.put(t.id, t.toJson());
    }
    for (final d in plan.dividends) {
      await _dividendsBox.put(d.id, d.toJson());
    }
    await _changed();
  }

  Future<void> putAccount(Account a) async {
    await _accountsBox.put(a.id, a.toJson());
    await _changed();
  }

  Future<void> putHolding(HoldingRecord h) async {
    await _holdingsBox.put(h.id, h.toJson());
    await _changed();
  }

  Future<void> putTrade(Trade t) async {
    await _tradesBox.put(t.id, t.toJson());
    await _changed();
  }

  Future<void> putDividend(Dividend d) async {
    await _dividendsBox.put(d.id, d.toJson());
    await _changed();
  }

  Future<void> deleteTrade(String id) async {
    await _tradesBox.delete(id);
    await _changed();
  }

  Future<void> deleteDividend(String id) async {
    await _dividendsBox.delete(id);
    await _changed();
  }

  Future<void> loadDemo() async {
    final demo = DemoData.build();
    for (final a in demo.accounts) {
      await _accountsBox.put(a.id, a.toJson());
    }
    for (final h in demo.holdings) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final t in demo.trades) {
      await _tradesBox.put(t.id, t.toJson());
    }
    for (final d in demo.dividends) {
      await _dividendsBox.put(d.id, d.toJson());
    }
    await _changed();
  }

  Future<void> clearAll() async {
    await _accountsBox.clear();
    await _holdingsBox.clear();
    await _tradesBox.clear();
    await _dividendsBox.clear();
    await _priceBox.clear();
    _reloadPrices();
    await _changed();
  }
}
