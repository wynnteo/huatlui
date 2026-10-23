import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_point.dart';

class PriceRequest {
  final String symbol;
  final String name;
  final String currency; // the holding's own currency
  final DateTime since; // earliest trade date: how far back history is wanted

  const PriceRequest({required this.symbol, required this.name, required this.currency, required this.since});
}

/// One source of prices. The app has two: Yahoo (stocks, ETFs, REITs...)
/// and the fund API (unit trusts). Adding another source later means one
/// more class here; nothing else changes.
abstract class PriceProvider {
  Future<PriceQuote?> fetch(PriceRequest request);
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Yahoo Finance chart endpoint, the same one the web app's /api/quote uses,
/// but with a date range so one call returns the latest price AND the daily
/// history needed for the portfolio line chart.
class YahooPriceProvider implements PriceProvider {
  final http.Client _client;
  YahooPriceProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
    'Accept': 'application/json',
  };

  @override
  Future<PriceQuote?> fetch(PriceRequest r) async {
    final now = DateTime.now();
    final from = r.since.subtract(const Duration(days: 7));
    final spanDays = now.difference(from).inDays;
    final uri = Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/${r.symbol}', {
      'period1': '${from.millisecondsSinceEpoch ~/ 1000}',
      'period2': '${now.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000}',
      'interval': spanDays > 900 ? '1wk' : '1d', // keep long histories small
    });
    final res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    return parseChart(jsonDecode(res.body), r.symbol);
  }

  /// Pure parsing, kept separate so it can be unit-tested with a saved response.
  static PriceQuote? parseChart(dynamic decoded, String symbol) {
    if (decoded is! Map) return null;
    final chart = decoded['chart'];
    if (chart is! Map) return null;
    final results = chart['result'];
    if (results is! List || results.isEmpty || results.first is! Map) return null;
    final first = results.first as Map;

    final meta = first['meta'] is Map ? first['meta'] as Map : const {};
    var currency = meta['currency'] as String?;

    // London lines are often quoted in pence (GBp / GBX): convert to pounds.
    var scale = 1.0;
    if (currency == 'GBp' || currency == 'GBX') {
      currency = 'GBP';
      scale = 0.01;
    }

    final timestamps = first['timestamp'] is List ? first['timestamp'] as List : const [];
    List closes = const [];
    final indicators = first['indicators'];
    if (indicators is Map) {
      final q = indicators['quote'];
      if (q is List && q.isNotEmpty && q.first is Map) {
        final c = (q.first as Map)['close'];
        if (c is List) closes = c;
      }
    }

    final history = <PricePoint>[];
    for (var i = 0; i < timestamps.length && i < closes.length; i++) {
      final t = timestamps[i];
      final c = closes[i];
      if (t is num && c is num) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000);
        history.add(PricePoint(_dayOf(d), c.toDouble() * scale));
      }
    }

    double? price = (meta['regularMarketPrice'] as num?)?.toDouble();
    if (price != null) price *= scale;
    price ??= history.isNotEmpty ? history.last.price : null;
    if (price == null) return null;

    final ts = meta['regularMarketTime'];
    final asOf = ts is num ? DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000) : null;

    // Make sure the history ends on the latest price.
    final lastDay = _dayOf(asOf ?? DateTime.now());
    if (history.isEmpty || history.last.date.isBefore(lastDay)) {
      history.add(PricePoint(lastDay, price));
    }

    return PriceQuote(symbol: symbol, price: price, currency: currency, asOf: asOf, history: history);
  }
}

/// Unit trusts. Prices are scraped from FT / Aberdeen / OCBC by the web
/// app's server (/api/fund-quote), which a phone can't do itself, so this
/// calls that endpoint. It has no history, so each refresh is stored as one
/// snapshot and the chart fills in over time.
class FundPriceProvider implements PriceProvider {
  final http.Client _client;
  final String Function() _baseUrl; // read lazily so Settings changes apply immediately

  FundPriceProvider({required String Function() baseUrl, http.Client? client})
      : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  @override
  Future<PriceQuote?> fetch(PriceRequest r) async {
    final base = _baseUrl().trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return null;

    // The endpoint wants "ISIN:CCY" (e.g. LU0320765646:SGD).
    final s = r.symbol.contains(':') ? r.symbol : '${r.symbol}:${r.currency}';
    final uri = Uri.parse('$base/api/fund-quote').replace(queryParameters: {'s': s, 'name': r.name});

    final res = await _client.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) return null;
    return parseFundQuote(jsonDecode(res.body), r.symbol, r.currency);
  }

  static PriceQuote? parseFundQuote(dynamic decoded, String symbol, String currency) {
    if (decoded is! Map) return null;
    final price = decoded['price'];
    if (price is! num || price <= 0) return null;
    final asOf = _parseLooseDate(decoded['lastUpdated']) ?? DateTime.now();
    return PriceQuote(
      symbol: symbol,
      price: price.toDouble(),
      currency: currency,
      asOf: asOf,
      history: [PricePoint(_dayOf(DateTime.now()), price.toDouble())],
    );
  }

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// FT says "Dec 10 2025", others use ISO or dd/mm/yyyy. Best effort; null if unsure.
  static DateTime? _parseLooseDate(dynamic raw) {
    if (raw is! String) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final named = RegExp(r'([A-Za-z]{3})[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})').firstMatch(raw);
    if (named != null) {
      final m = _months[named.group(1)!.toLowerCase()];
      if (m != null) return DateTime(int.parse(named.group(3)!), m, int.parse(named.group(2)!));
    }
    final slashed = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(raw);
    if (slashed != null) {
      return DateTime(int.parse(slashed.group(3)!), int.parse(slashed.group(2)!), int.parse(slashed.group(1)!));
    }
    return null;
  }
}
