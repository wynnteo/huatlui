import 'dart:async';
import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
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

class _Found {
  final double price;
  final DateTime? asOf;
  const _Found(this.price, this.asOf);
}

/// Unit trusts. There is no price API for these, so the pages are fetched and
/// read directly on the phone, with the same selectors as the web app's
/// /api/fund-quote:
///   1. "ABRDN Global Dynamic Dividend" -> Aberdeen's fund page
///   2. any other fund                  -> FT Markets, using "ISIN:CCY"
///   3. if that finds nothing           -> OCBC's fund page, symbol as fund code
/// Pages are requested at most ~1.4 times a second, like the web app does.
/// There is no price history, so each fetch is stored as one dated snapshot
/// and the chart fills in over time.
///
/// These are web pages, not APIs: if a site changes its layout the price
/// stops coming through, and the holding is flagged "Price not updated" until
/// the parser is adjusted (or you type the price in by hand).
class FundPriceProvider implements PriceProvider {
  final http.Client _client;
  FundPriceProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _aberdeenUrl =
      'https://www.aberdeeninvestments.com/en-sg/investor/funds/view-all-funds/abrdn-global-dynamic-dividend-fund-sgxz84873520?subTab=keyInformationTab';
  static const _desktopAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36';

  // ---- politeness: one request at a time, 700 ms apart -------------------
  Future<void> _tail = Future.value();

  Future<T> _throttled<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await job());
      } catch (e, st) {
        done.completeError(e, st);
      }
      await Future.delayed(const Duration(milliseconds: 700));
    });
    return done.future;
  }

  Future<String?> _get(String url, {String referer = 'https://markets.ft.com/'}) {
    return _throttled<String?>(() async {
      final res = await _client.get(Uri.parse(url), headers: {
        'User-Agent': _desktopAgent,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': referer,
      }).timeout(const Duration(seconds: 15));
      return res.statusCode == 200 ? res.body : null;
    });
  }

  @override
  Future<PriceQuote?> fetch(PriceRequest r) async {
    final upperName = r.name.toUpperCase();
    final isAbrdn = upperName.startsWith('ABRDN');
    // FT wants "ISIN:CCY"; add the holding's currency if the symbol has none.
    final ftSymbol = r.symbol.contains(':') ? r.symbol : '${r.symbol}:${r.currency}';
    final fundCode = r.symbol.split(':').first;

    _Found? found;
    try {
      if (isAbrdn) {
        // Only this one Aberdeen page is known; another ABRDN fund would get
        // the wrong price, so it goes straight to the OCBC fallback instead.
        if (upperName.contains('GLOBAL DYNAMIC DIVIDEND')) {
          final html = await _get(_aberdeenUrl, referer: 'https://www.aberdeeninvestments.com/en-sg/investor/funds/');
          if (html != null) found = parseAberdeen(html);
        }
      } else {
        final html = await _get('https://markets.ft.com/data/funds/tearsheet/summary?s=${Uri.encodeComponent(ftSymbol)}');
        if (html != null) found = parseFt(html);
      }
    } catch (_) {
      found = null;
    }

    if (found == null) {
      try {
        final html = await _get(
          'https://www.ocbc.com/personal-banking/investments/unit-trusts/funds-details?fundCode=${Uri.encodeComponent(fundCode)}',
          referer: 'https://www.ocbc.com/',
        );
        if (html != null) found = parseOcbc(html);
      } catch (_) {
        found = null;
      }
    }
    if (found == null) return null;

    // Store the snapshot under the date the price is FOR, so refreshing twice
    // on the same NAV doesn't add duplicate points.
    final today = _dayOf(DateTime.now());
    var snapshotDay = found.asOf == null ? today : _dayOf(found.asOf!);
    if (snapshotDay.isAfter(today)) snapshotDay = today;

    return PriceQuote(
      symbol: r.symbol,
      price: found.price,
      currency: r.currency,
      asOf: found.asOf ?? DateTime.now(),
      history: [PricePoint(snapshotDay, found.price)],
    );
  }

  // ---- page readers (pure, so they can be tested with saved pages) --------

  static double? _toPrice(String? raw) {
    if (raw == null) return null;
    final v = double.tryParse(raw.replaceAll(RegExp(r'[,$\s—]'), ''));
    return (v != null && v > 0) ? v : null;
  }

  /// FT Markets fund "tearsheet": a "Price" row in the data list, plus a
  /// disclaimer like "Data delayed at least 15 minutes, as of Dec 10 2025."
  static _Found? parseFt(String html) {
    final doc = html_parser.parse(html);
    String? priceText;
    for (final dl in doc.querySelectorAll('dl.mod-ui-data-list')) {
      final label = dl.querySelector('dt')?.text.trim().toLowerCase() ?? '';
      if (label.contains('price') && priceText == null) {
        priceText = dl.querySelector('dd.mod-ui-data-list__value')?.text.trim();
      }
    }
    if (priceText == null || priceText.isEmpty) {
      priceText = doc.querySelector('.mod-ui-data-list__value')?.text.trim();
    }
    final price = _toPrice(priceText);
    if (price == null) return null;

    final disclaimer = doc.querySelector('div.mod-disclaimer')?.text.trim() ?? '';
    final m = RegExp(r'as of\s+(.+?)\.', caseSensitive: false).firstMatch(disclaimer);
    return _Found(price, _parseLooseDate(m?.group(1) ?? disclaimer));
  }

  /// Aberdeen fund page: the block headed "Daily price" holds the value (an h4)
  /// and the date (a "body-small" element).
  static _Found? parseAberdeen(String html) {
    final doc = html_parser.parse(html);
    for (final el in doc.querySelectorAll('[class]')) {
      if (!el.className.contains('section-header-small')) continue;
      if (el.text.trim().toLowerCase() != 'daily price') continue;
      final parent = el.parent;
      if (parent == null) continue;
      final valueEl = parent.querySelector('.h4') ?? parent.querySelector('h4');
      final price = _toPrice(valueEl?.text);
      if (price == null) continue;
      dom.Element? dateEl;
      for (final d in parent.querySelectorAll('[class]')) {
        if (d.className.contains('body-small')) {
          dateEl = d;
          break;
        }
      }
      return _Found(price, _parseLooseDate(dateEl?.text.trim()));
    }
    return null;
  }

  /// OCBC fund page: the block titled "Indicative price", value in <strong>,
  /// date in "Updated as of ...".
  static _Found? parseOcbc(String html) {
    final doc = html_parser.parse(html);
    for (final block in doc.querySelectorAll('.inner-content .block')) {
      final title = block.querySelector('h4.title-text')?.text.trim().toLowerCase() ?? '';
      if (!title.contains('indicative price')) continue;
      final price = _toPrice(block.querySelector('.value-text strong')?.text);
      if (price == null) continue;
      final dateRaw = block.querySelector('p.small')?.text.replaceAll('Updated as of', '').trim();
      return _Found(price, _parseLooseDate(dateRaw));
    }
    return null;
  }

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// "Dec 10 2025", "10 Dec 2025", ISO, or dd/mm/yyyy. Best effort; null if unsure.
  static DateTime? _parseLooseDate(String? raw) {
    if (raw == null) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final named = RegExp(r'([A-Za-z]{3})[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})').firstMatch(raw);
    if (named != null) {
      final m = _months[named.group(1)!.toLowerCase()];
      if (m != null) return DateTime(int.parse(named.group(3)!), m, int.parse(named.group(2)!));
    }
    final dayFirst = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\.?,?\s+(\d{4})').firstMatch(raw);
    if (dayFirst != null) {
      final m = _months[dayFirst.group(2)!.toLowerCase()];
      if (m != null) return DateTime(int.parse(dayFirst.group(3)!), m, int.parse(dayFirst.group(1)!));
    }
    final slashed = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(raw);
    if (slashed != null) {
      return DateTime(int.parse(slashed.group(3)!), int.parse(slashed.group(2)!), int.parse(slashed.group(1)!));
    }
    return null;
  }
}
