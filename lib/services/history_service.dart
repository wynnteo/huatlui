import 'dart:math' as math;
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/price_point.dart';
import '../models/trade.dart';
import 'fx_service.dart';

enum HistoryRange { m1, m3, m6, y1, all }

class SeriesPoint {
  final DateTime date;
  final double value; // what the open positions were worth, base currency
  final double invested; // what they cost, base currency
  const SeriesPoint(this.date, this.value, this.invested);

  double get gain => value - invested;
  double get gainPct => invested > 0 ? gain / invested * 100 : 0;
}

/// Rebuilds "what was my portfolio worth on each day" from the trades and
/// the stored daily prices. Nothing here is saved: it is recomputed from the
/// transaction log, so it can never drift out of sync.
///
/// How a day is valued:
///  - quantity held that day comes from replaying the trades up to it;
///  - price that day is the stored close (carried forward over weekends);
///    where a symbol has no price history (unit trusts, or before the first
///    refresh) it uses the trade prices and the latest known price instead;
///  - amounts convert to the base currency at TODAY's exchange rate for the
///    value, and at each trade's own rate for the cost. Same rule as the
///    rest of the app.
class HistoryService {
  final FxService fx;
  final String baseCurrency;
  const HistoryService({required this.fx, required this.baseCurrency});

  static int? rangeDays(HistoryRange r) {
    switch (r) {
      case HistoryRange.m1:
        return 30;
      case HistoryRange.m3:
        return 91;
      case HistoryRange.m6:
        return 182;
      case HistoryRange.y1:
        return 365;
      case HistoryRange.all:
        return null;
    }
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  List<SeriesPoint> portfolioSeries({
    required List<Trade> trades,
    required List<HoldingRecord> holdings,
    required Map<String, List<PricePoint>> history,
    HistoryRange range = HistoryRange.all,
    DateTime? now,
    int maxPoints = 120,
  }) {
    if (trades.isEmpty) return const [];
    final today = _day(now ?? DateTime.now());

    final sorted = [...trades]..sort((a, b) {
        final c = a.tradeDate.compareTo(b.tradeDate);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    final firstDay = _day(sorted.first.tradeDate);
    if (firstDay.isAfter(today)) return const [];

    var start = firstDay;
    final days = rangeDays(range);
    if (days != null) {
      final s = DateTime(today.year, today.month, today.day - days);
      if (s.isAfter(start)) start = s;
    }

    // Sample dates: daily for short ranges, every few days for long ones.
    final totalDays = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    final step = math.max(1, (totalDays / (maxPoints - 1)).ceil());
    final dates = <DateTime>[
      for (var i = 0; i <= totalDays; i += step) DateTime(start.year, start.month, start.day + i),
    ];
    if (dates.isEmpty || dates.last != today) dates.add(today);

    // Price series per symbol.
    final latestHolding = <String, HoldingRecord>{for (final h in holdings) h.symbol.toUpperCase(): h};
    final tradePoints = <String, List<PricePoint>>{};
    final currencyOf = <String, String>{};
    for (final t in sorted) {
      final sym = t.symbol.toUpperCase();
      tradePoints.putIfAbsent(sym, () => []).add(PricePoint(_day(t.tradeDate), t.price));
      currencyOf.putIfAbsent(sym, () => t.currency);
    }
    final series = <String, List<PricePoint>>{};
    for (final sym in tradePoints.keys) {
      final stored = history[sym];
      if (stored != null && stored.isNotEmpty) {
        series[sym] = stored;
      } else {
        final pts = [...tradePoints[sym]!];
        final h = latestHolding[sym];
        if (h != null && h.currentPrice > 0) pts.add(PricePoint(today, h.currentPrice));
        series[sym] = pts;
      }
    }
    final cursor = <String, int>{};
    double? priceAt(String sym, DateTime date) {
      final list = series[sym];
      if (list == null || list.isEmpty) return null;
      var i = cursor[sym] ?? 0;
      while (i + 1 < list.length && !list[i + 1].date.isAfter(date)) {
        i++;
      }
      cursor[sym] = i;
      return list[i].price; // before the first point, the first point stands in
    }

    // Replay the trades in date order while walking the dates.
    final qty = <String, double>{};
    final cost = <String, double>{}; // base currency, historical rates
    final symbolOf = <String, String>{};

    void apply(Trade t) {
      final key = HoldingRecord.keyOf(t.accountId, t.symbol);
      symbolOf[key] = t.symbol.toUpperCase();
      final q = qty[key] ?? 0.0;
      final c = cost[key] ?? 0.0;
      if (t.type == TradeType.buy) {
        final cashBase = fx.toBaseHistorical(
          amount: t.quantity * t.price + t.fees,
          fxRate: t.fxRate,
          fxBase: t.fxBase,
          targetBase: baseCurrency,
        );
        qty[key] = q + t.quantity;
        cost[key] = c + cashBase;
      } else {
        if (q <= 1e-9) return;
        final sellQty = math.min(t.quantity, q);
        final share = sellQty / q;
        qty[key] = q - sellQty;
        cost[key] = c - c * share;
        if ((qty[key] ?? 0) <= 1e-9) {
          qty[key] = 0;
          cost[key] = 0;
        }
      }
    }

    final out = <SeriesPoint>[];
    var ti = 0;
    for (final date in dates) {
      while (ti < sorted.length && !_day(sorted[ti].tradeDate).isAfter(date)) {
        apply(sorted[ti]);
        ti++;
      }
      var value = 0.0;
      var invested = 0.0;
      qty.forEach((key, q) {
        if (q <= 1e-9) return;
        final sym = symbolOf[key]!;
        final p = priceAt(sym, date);
        if (p != null) value += fx.convert(q * p, currencyOf[sym] ?? baseCurrency, baseCurrency);
        invested += cost[key] ?? 0;
      });
      out.add(SeriesPoint(date, value, invested));
    }
    return out;
  }
}
