import 'dart:convert';

import '../models/account.dart';
import '../models/dividend.dart';
import '../models/holding_record.dart';
import '../models/price_point.dart';
import '../models/trade.dart';
import 'activity.dart';

/// Portable, versioned user-data snapshot. CSV remains a separate interchange
/// format; JSON preserves IDs, fees, FX, account metadata, and price histories.
class PortfolioBackup {
  static const int version = 1;
  static const String format = 'huatlui-portfolio';

  final List<Account> accounts;
  final List<HoldingRecord> holdings;
  final List<Trade> trades;
  final List<Dividend> dividends;
  final Map<String, List<PricePoint>> priceHistory;
  final String baseCurrency;
  final String locale;
  final String themeMode;

  const PortfolioBackup({
    required this.accounts,
    required this.holdings,
    required this.trades,
    required this.dividends,
    required this.priceHistory,
    required this.baseCurrency,
    required this.locale,
    required this.themeMode,
  });

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': format,
    'version': version,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'accounts': [for (final a in accounts) a.toJson()],
    'holdings': [for (final h in holdings) h.toJson()],
    'trades': [for (final t in trades) t.toJson()],
    'dividends': [for (final d in dividends) d.toJson()],
    'priceHistory': {
      for (final e in priceHistory.entries)
        e.key: [for (final p in e.value) p.toJson()],
    },
    'preferences': {
      'baseCurrency': baseCurrency,
      'locale': locale,
      'themeMode': themeMode,
    },
  });

  static PortfolioBackup decode(String raw) {
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != format || decoded['version'] != version) {
      throw const FormatException('Unsupported HuatLui backup format or version');
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is! Map) throw const FormatException('Invalid backup record');
      return Map<String, dynamic>.from(value);
    }

    List<T> records<T>(String key, T Function(Map<String, dynamic>) decodeRecord) {
      final values = decoded[key];
      if (values is! List) throw FormatException('Missing or invalid $key');
      return [for (final value in values) decodeRecord(asMap(value))];
    }

    final accounts = records('accounts', Account.fromJson);
    final holdings = records('holdings', HoldingRecord.fromJson);
    final trades = records('trades', Trade.fromJson);
    final dividends = records('dividends', Dividend.fromJson);
    final prefs = asMap(decoded['preferences']);
    final base = prefs['baseCurrency'];
    final locale = prefs['locale'];
    final theme = prefs['themeMode'];
    if (base is! String || !const ['SGD', 'USD', 'MYR', 'HKD', 'CNY', 'GBP', 'EUR'].contains(base) ||
        locale is! String || !const ['en', 'zh'].contains(locale) ||
        theme is! String || !const ['system', 'light', 'dark'].contains(theme)) {
      throw const FormatException('Unsupported backup preferences');
    }

    final historyRaw = decoded['priceHistory'];
    if (historyRaw is! Map) throw const FormatException('Invalid price history');
    final history = <String, List<PricePoint>>{};
    for (final entry in historyRaw.entries) {
      if (entry.key is! String || entry.value is! List) {
        throw const FormatException('Invalid price history entry');
      }
      final points = <PricePoint>[];
      for (final item in entry.value as List) {
        final point = PricePoint.fromJson(item);
        if (!point.price.isFinite || point.price <= 0) {
          throw const FormatException('Invalid historical price');
        }
        points.add(point);
      }
      history[entry.key as String] = points;
    }

    final backup = PortfolioBackup(
      accounts: accounts, holdings: holdings, trades: trades,
      dividends: dividends, priceHistory: history,
      baseCurrency: base, locale: locale, themeMode: theme,
    );
    backup.validate();
    return backup;
  }

  void validate() {
    void unique(List<String> values, String type) {
      if (values.any((x) => x.trim().isEmpty) || values.toSet().length != values.length) {
        throw FormatException('Duplicate or empty $type ID');
      }
    }
    unique([for (final x in accounts) x.id], 'account');
    unique([for (final x in holdings) x.id], 'holding');
    unique([for (final x in holdings) x.key], 'holding key');
    unique([for (final x in trades) x.id], 'trade');
    unique([for (final x in dividends) x.id], 'dividend');
    final accountIds = {for (final x in accounts) x.id};
    final holdingKeys = {for (final x in holdings) x.key};
    for (final h in holdings) {
      if (!accountIds.contains(h.accountId) ||
          h.symbol.trim().isEmpty || h.currency.trim().isEmpty ||
          !h.currentPrice.isFinite || h.currentPrice < 0 ||
          (h.targetPct != null && (!h.targetPct!.isFinite || h.targetPct! < 0 || h.targetPct! > 100))) {
        throw const FormatException('Invalid holding in backup');
      }
    }
    for (final t in trades) {
      if (!accountIds.contains(t.accountId) ||
          !holdingKeys.contains(HoldingRecord.keyOf(t.accountId, t.symbol)) ||
          t.quantity <= 0 || !t.quantity.isFinite ||
          t.price < 0 || !t.price.isFinite ||
          t.fees < 0 || !t.fees.isFinite ||
          t.fxRate <= 0 || !t.fxRate.isFinite ||
          t.currency.trim().isEmpty || t.fxBase.trim().isEmpty) {
        throw const FormatException('Invalid trade in backup');
      }
    }
    for (final d in dividends) {
      if (!accountIds.contains(d.accountId) ||
          d.grossAmount <= 0 || !d.grossAmount.isFinite ||
          d.withholdingTax < 0 || !d.withholdingTax.isFinite ||
          d.withholdingTax > d.grossAmount ||
          d.fxRate <= 0 || !d.fxRate.isFinite ||
          d.currency.trim().isEmpty || d.fxBase.trim().isEmpty) {
        throw const FormatException('Invalid dividend in backup');
      }
    }
    if (!tradesAreConsistent(trades)) {
      throw const FormatException('Backup contains sales exceeding available units');
    }
  }
}
