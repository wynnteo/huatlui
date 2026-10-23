import '../models/enums.dart';
import '../models/dividend.dart';
import '../models/trade.dart';
import 'fx_service.dart';
import 'portfolio_service.dart';

class MonthValue {
  final DateTime month;
  final double value; // base currency
  const MonthValue(this.month, this.value);
}

/// Price gain/loss one symbol has produced so far (across accounts):
/// unrealised + realised. Dividends are left out on purpose, so income can't
/// hide a loss; they have their own Income tab.
class SymbolReturn {
  final String symbol;
  final String name;
  final double returnBase;
  final double boughtBase;
  const SymbolReturn({required this.symbol, required this.name, required this.returnBase, required this.boughtBase});

  double get pct => boughtBase > 0 ? returnBase / boughtBase * 100 : 0;
}

class DividendPayer {
  final String symbol;
  final double amountBase;
  const DividendPayer(this.symbol, this.amountBase);
}

/// This year's and last year's dividends, month by month (index 0 = January).
class DividendYoY {
  final int year;
  final List<double> thisYear;
  final List<double> lastYear;
  const DividendYoY({required this.year, required this.thisYear, required this.lastYear});

  bool get isEmpty => thisYear.every((v) => v == 0) && lastYear.every((v) => v == 0);
}

enum InsightKind { topContributor, biggestDrag, concentration, dividends, currency, fees }

/// Plain facts about the portfolio. The UI turns each one into a sentence
/// in the current language; nothing here is text.
class Insight {
  final InsightKind kind;
  final String label; // symbol or currency code, where relevant
  final double amount; // base currency
  final double pct;
  final int count;
  const Insight({required this.kind, this.label = '', this.amount = 0, this.pct = 0, this.count = 0});
}

/// Derived numbers for the Insights screen. Pure calculation: no state, no UI.
class InsightsService {
  final FxService fx;
  final String baseCurrency;
  const InsightsService({required this.fx, required this.baseCurrency});

  double _hist(double amount, double fxRate, String fxBase) =>
      fx.toBaseHistorical(amount: amount, fxRate: fxRate, fxBase: fxBase, targetBase: baseCurrency);

  int _monthKey(DateTime d) => d.year * 12 + d.month;

  List<DateTime> _lastMonths(int n, DateTime now) => [for (var i = n - 1; i >= 0; i--) DateTime(now.year, now.month - i)];

  /// Best to worst. A symbol held in two accounts counts once.
  List<SymbolReturn> returnsBySymbol(List<Position> positions) {
    final ret = <String, double>{};
    final bought = <String, double>{};
    final names = <String, String>{};
    for (final p in positions) {
      ret[p.symbol] = (ret[p.symbol] ?? 0) + p.unrealizedBase + p.realizedBase;
      bought[p.symbol] = (bought[p.symbol] ?? 0) + p.totalBoughtBase;
      names[p.symbol] = p.name;
    }
    final list = [
      for (final k in ret.keys)
        SymbolReturn(symbol: k, name: names[k] ?? k, returnBase: ret[k]!, boughtBase: bought[k] ?? 0),
    ];
    list.sort((a, b) => b.returnBase.compareTo(a.returnBase));
    return list;
  }

  List<MonthValue> dividendsByMonth(List<Dividend> dividends, {int months = 12, DateTime? now}) {
    final list = _lastMonths(months, now ?? DateTime.now());
    final totals = {for (final m in list) _monthKey(m): 0.0};
    for (final d in dividends) {
      final k = _monthKey(d.paymentDate);
      if (totals.containsKey(k)) totals[k] = totals[k]! + _hist(d.netAmount, d.fxRate, d.fxBase);
    }
    return [for (final m in list) MonthValue(m, totals[_monthKey(m)]!)];
  }

  DividendYoY dividendsYoY(List<Dividend> dividends, {DateTime? now}) {
    final year = (now ?? DateTime.now()).year;
    final cur = List<double>.filled(12, 0);
    final prev = List<double>.filled(12, 0);
    for (final d in dividends) {
      final amt = _hist(d.netAmount, d.fxRate, d.fxBase);
      final m = d.paymentDate.month - 1;
      if (d.paymentDate.year == year) {
        cur[m] += amt;
      } else if (d.paymentDate.year == year - 1) {
        prev[m] += amt;
      }
    }
    return DividendYoY(year: year, thisYear: cur, lastYear: prev);
  }

  /// Money put into buys each month (fees included).
  List<MonthValue> investedByMonth(List<Trade> trades, {int months = 12, DateTime? now}) {
    final list = _lastMonths(months, now ?? DateTime.now());
    final totals = {for (final m in list) _monthKey(m): 0.0};
    for (final t in trades) {
      if (t.type != TradeType.buy) continue;
      final k = _monthKey(t.tradeDate);
      if (totals.containsKey(k)) totals[k] = totals[k]! + _hist(t.netAmount, t.fxRate, t.fxBase);
    }
    return [for (final m in list) MonthValue(m, totals[_monthKey(m)]!)];
  }

  double feesBase(List<Trade> trades) {
    var sum = 0.0;
    for (final t in trades) {
      sum += _hist(t.fees, t.fxRate, t.fxBase);
    }
    return sum;
  }

  /// All-time net dividends per symbol, largest first.
  List<DividendPayer> dividendsBySymbol(List<Dividend> dividends) {
    final map = <String, double>{};
    for (final d in dividends) {
      map[d.symbol] = (map[d.symbol] ?? 0) + _hist(d.netAmount, d.fxRate, d.fxBase);
    }
    final list = [for (final e in map.entries) DividendPayer(e.key, e.value)];
    list.sort((a, b) => b.amountBase.compareTo(a.amountBase));
    return list;
  }

  /// Only says something when there is something worth saying, so a quiet
  /// portfolio gets few lines rather than filler.
  List<Insight> insights(List<Position> positions, List<Trade> trades, List<Dividend> dividends) {
    final svc = PortfolioService(fx: fx, baseCurrency: baseCurrency);
    final summary = svc.summary(positions);
    final out = <Insight>[];

    final bySymbol = returnsBySymbol(positions);
    if (bySymbol.length >= 2) {
      final gains = bySymbol.where((r) => r.returnBase > 0).toList();
      final gainSum = gains.fold<double>(0, (s, r) => s + r.returnBase);
      if (gains.isNotEmpty && gainSum > 0) {
        out.add(Insight(
          kind: InsightKind.topContributor,
          label: gains.first.symbol,
          amount: gains.first.returnBase,
          pct: gains.first.returnBase / gainSum * 100,
        ));
      }
      final worst = bySymbol.last;
      if (worst.returnBase < 0) {
        out.add(Insight(kind: InsightKind.biggestDrag, label: worst.symbol, amount: worst.returnBase));
      }
    }

    final holdingSlices = svc.allocation(positions, AllocationGroup.holding);
    if (holdingSlices.length >= 4) {
      final top3 = holdingSlices.take(3).fold<double>(0, (s, x) => s + x.currentPct);
      out.add(Insight(kind: InsightKind.concentration, count: 3, pct: top3));
    }

    // Dividends received so far this calendar year (not a rolling 12 months).
    final ytd = dividendsYoY(dividends).thisYear.fold<double>(0, (s, v) => s + v);
    if (ytd > 0 && summary.costBase > 0) {
      out.add(Insight(kind: InsightKind.dividends, amount: ytd, pct: ytd / summary.costBase * 100));
    }

    final ccySlices = svc.allocation(positions, AllocationGroup.currency);
    if (ccySlices.isNotEmpty) {
      final top = ccySlices.first;
      if (top.key != baseCurrency && top.currentPct >= 40) {
        out.add(Insight(kind: InsightKind.currency, label: top.key, pct: top.currentPct));
      }
    }

    final fees = feesBase(trades);
    if (fees > 0 && summary.totalBoughtBase > 0) {
      out.add(Insight(kind: InsightKind.fees, amount: fees, pct: fees / summary.totalBoughtBase * 100));
    }

    return out;
  }
}
