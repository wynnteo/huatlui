import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

/// SGD value of one unit of each currency. Fresh values come from Frankfurter
/// daily *reference* rates, never intraday executable quotes.
class FxService extends ChangeNotifier {
  static const _boxName = 'fx_rates_v1';
  static const _quotes = ['USD', 'MYR', 'HKD', 'CNY', 'GBP', 'EUR'];

  Map<String, double> _toSgd;
  Box<dynamic>? _box;
  final http.Client _client;
  bool _refreshing = false;
  bool _hasLiveData = false;
  DateTime? _asOf;
  DateTime? _lastFetched;
  String? _lastError;

  FxService([Map<String, double>? toSgd, http.Client? client])
      : _toSgd = Map.unmodifiable(_normalize(toSgd ?? defaultToSgd)),
        _client = client ?? http.Client() {
    _validate(_toSgd);
  }

  static const Map<String, double> defaultToSgd = {
    'SGD': 1.0, 'USD': 1.34, 'MYR': 0.30,
    'HKD': 0.172, 'CNY': 0.185, 'GBP': 1.70, 'EUR': 1.46,
  };

  static Map<String, double> _normalize(Map<String, double> entries) => {
    for (final e in entries.entries) e.key.trim().toUpperCase(): e.value,
  };

  static void _validate(Map<String, double> rates) {
    for (final e in rates.entries) {
      if (e.key.isEmpty || !e.value.isFinite || e.value <= 0) {
        throw ArgumentError.value(e.value, e.key, 'FX rates must be finite and positive');
      }
    }
  }

  List<String> get supportedCurrencies => _toSgd.keys.toList();
  bool get refreshing => _refreshing;
  bool get hasLiveData => _hasLiveData;
  DateTime? get asOf => _asOf;
  DateTime? get lastFetched => _lastFetched;
  String? get lastError => _lastError;
  bool get isStale => !_hasLiveData || _lastFetched == null ||
      DateTime.now().difference(_lastFetched!) >= const Duration(hours: 24);

  /// Read last successfully fetched data before the first screen is built.
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    try {
      final raw = _box!.get('rates');
      final dateRaw = _box!.get('asOf');
      final fetchedRaw = _box!.get('fetched');
      if (raw is Map && dateRaw is String && fetchedRaw is String) {
        final parsed = <String, double>{};
        for (final e in raw.entries) {
          if (e.key is! String || e.value is! num) throw const FormatException('Invalid FX cache');
          parsed[e.key as String] = (e.value as num).toDouble();
        }
        final checked = _normalize(parsed);
        _validate(checked);
        if (!_quotes.every(checked.containsKey) || checked['SGD'] != 1.0) {
          throw const FormatException('Incomplete FX cache');
        }
        _toSgd = Map.unmodifiable(checked);
        _asOf = DateTime.parse(dateRaw);
        _lastFetched = DateTime.parse(fetchedRaw);
        _hasLiveData = true;
      }
    } catch (_) {
      // Corrupt cache is ignored; indicative rates are visibly labeled.
      _hasLiveData = false;
    }
    notifyListeners();
  }

  /// Parse Frankfurter v2 list of {date, base, quote, rate}. Response quotes
  /// are units of foreign currency per SGD; invert for this service's format.
  @visibleForTesting
  static Map<String, double> parseFrankfurterRates(dynamic response) {
    if (response is! List) throw const FormatException('Expected FX rate list');
    final rates = <String, double>{'SGD': 1.0};
    DateTime? day;
    for (final item in response) {
      if (item is! Map || item['base']?.toString().toUpperCase() != 'SGD') {
        throw const FormatException('Unexpected FX base');
      }
      final quote = item['quote']?.toString().toUpperCase();
      final value = item['rate'];
      final rawDay = item['date']?.toString();
      if (quote == null || value is! num || !value.toDouble().isFinite ||
          value <= 0 || rawDay == null) throw const FormatException('Invalid FX quote');
      final date = DateTime.tryParse(rawDay);
      if (date == null || (day != null && day != date)) {
        throw const FormatException('Inconsistent FX date');
      }
      day = date;
      rates[quote] = 1 / value.toDouble();
    }
    if (!_quotes.every(rates.containsKey)) throw const FormatException('Missing required FX quotes');
    _validate(rates);
    return rates;
  }

  /// Update at most daily unless explicitly requested by the user.
  /// When offline, keep the last successful cache; never overwrite with a
  /// failed or partial response.
  Future<bool> refresh({bool force = false}) async {
    if (_refreshing) return false;
    if (!force && !isStale) return true;
    _refreshing = true;
    _lastError = null;
    notifyListeners();
    try {
      final uri = Uri.https('api.frankfurter.dev', '/v2/rates', {
        'base': 'SGD', 'quotes': _quotes.join(','),
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw FormatException('FX API HTTP ${res.statusCode}');
      final json = jsonDecode(res.body);
      final rates = parseFrankfurterRates(json);
      final asOf = DateTime.parse((json as List).first['date'] as String);
      final fetched = DateTime.now();
      // Persist a complete consistent snapshot before switching active rates.
      final box = _box;
      if (box == null) throw StateError('FX cache not initialized');
      await box.putAll({
        'rates': rates, 'asOf': asOf.toIso8601String(),
        'fetched': fetched.toIso8601String(),
      });
      _toSgd = Map.unmodifiable(rates);
      _asOf = asOf;
      _lastFetched = fetched;
      _hasLiveData = true;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  double rate(String from, String to) {
    final source = from.trim().toUpperCase();
    final target = to.trim().toUpperCase();
    final f = _toSgd[source];
    final t = _toSgd[target];
    if (f == null) throw ArgumentError.value(from, 'from', 'Unsupported currency');
    if (t == null) throw ArgumentError.value(to, 'to', 'Unsupported currency');
    if (source == target) return 1.0;
    return f / t;
  }

  double convert(double amount, String from, String to) => amount * rate(from, to);

  double toBaseHistorical({
    required double amount,
    required double fxRate,
    required String fxBase,
    required String targetBase,
  }) {
    if (!fxRate.isFinite || fxRate <= 0) {
      throw ArgumentError.value(fxRate, 'fxRate', 'Historical FX rate must be finite and positive');
    }
    final recorded = amount * fxRate;
    if (fxBase.trim().toUpperCase() == targetBase.trim().toUpperCase()) return recorded;
    return recorded * rate(fxBase, targetBase);
  }
}
