import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/trade.dart';
import '../services/history_service.dart';
import '../services/insights_service.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/chart_palette.dart';
import '../widgets/currency_display.dart';
import '../widgets/donut_chart.dart';
import '../widgets/insight_line.dart';
import '../widgets/line_chart.dart';
import '../widgets/mini_charts.dart';
import '../widgets/price_status.dart';
import '../widgets/ui_helpers.dart';
import 'allocation_screen.dart';

/// Where the numbers get explained: what is driving your capital gain, what
/// your dividends are doing, and how the portfolio is spread. Aggregate view,
/// so everything is in the base currency.
///
/// Performance and Income can be narrowed to one asset class (stocks, ETFs,
/// unit trusts...) with the pills at the top; "All" is the overview.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _tab = 0;
  HistoryRange _range = HistoryRange.y1;
  AssetClass? _class; // null = All
  int? _year; // income year; null = this year

  AssetClass _classOf(String accountId, String symbol) =>
      repo.holdingFor(accountId, symbol)?.assetClass ?? AssetClass.other;

  List<Widget> _lines(List<Insight> all, Set<InsightKind> kinds, String base) {
    final picked = all.where((i) => kinds.contains(i.kind)).toList();
    if (picked.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      for (final i in picked) InsightLine(insight: i, base: base),
    ];
  }

  /// "All | Stocks | ETF | Unit Trusts ..." (only classes you actually hold).
  Widget _classPills(AppLocalizations t, List<AssetClass> present, AssetClass? selected) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoicePill(label: t.filterAll, selected: selected == null, onTap: () => setState(() => _class = null)),
            for (final c in present)
              ChoicePill(label: assetClassLabel(t, c), selected: selected == c, onTap: () => setState(() => _class = c)),
          ],
        ),
      ),
    );
  }

  void _showHow(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.colors;
        Widget block(String title, String body) => Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(fontSize: 13, height: 1.5, color: c.textSecondary)),
                ],
              ),
            );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.chartHowTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
                block(t.chartHowCostTitle, t.chartHowCostBody),
                block(t.chartHowValueTitle, t.chartHowValueBody),
                block(t.chartHowGapTitle, t.chartHowGapBody),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- performance

  List<Widget> _performance(
    BuildContext context, {
    required List<Position> positionsAll,
    required List<Position> positions,
    required List<AssetClass> present,
    required AssetClass? cls,
    required List<Trade> trades,
    required PortfolioSummary s,
    required List<Insight> all,
    required InsightsService ins,
    required String base,
  }) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    final returns = ins.returnsBySymbol(positions);
    final List<SymbolReturn> shown = returns.length <= 10 ? returns : [...returns.take(6), ...returns.skip(returns.length - 4)];
    final maxAbs = returns.fold<double>(0, (m, r) => math.max(m, r.returnBase.abs()));
    final open = positions.where((p) => p.isOpen).toList();
    final winners = open.where((p) => p.unrealizedBase > 0).length;
    final fees = ins.feesBase(trades);

    final series = HistoryService(fx: fx, baseCurrency: base).portfolioSeries(
      trades: trades,
      holdings: repo.holdings,
      history: repo.priceHistory,
      range: _range,
    );
    const ranges = [HistoryRange.m1, HistoryRange.m3, HistoryRange.m6, HistoryRange.y1, HistoryRange.all];

    // Overview by asset class (only on "All", and only if there is more than one).
    final byClass = <AssetClass, List<Position>>{};
    for (final p in positionsAll) {
      byClass.putIfAbsent(p.assetClass, () => []).add(p);
    }

    final breakdownTitle = cls == null ? t.breakdown : '${t.breakdown} · ${assetClassLabel(t, cls)}';

    return [
      SectionLabel(t.chartValueVsCost, padding: const EdgeInsets.only(top: 24, bottom: 12)),
      if (series.length >= 2) ...[
        PortfolioLineChart(data: series, base: base, valueLabel: t.chartValue, costLabel: t.chartCost),
        const SizedBox(height: 16),
        Center(
          child: AppSegmented(
            labels: ['1M', '3M', '6M', '1Y', t.rangeAll],
            selected: ranges.indexOf(_range),
            onChanged: (i) => setState(() => _range = ranges[i]),
          ),
        ),
        const SizedBox(height: 12),
        Text(t.chartNote, style: TextStyle(fontSize: 11, height: 1.4, color: c.textTertiary)),
        TextButton(
          onPressed: () => _showHow(context),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(t.chartHowLink),
        ),
      ] else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text(t.chartNeedsData, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5))),
        ),
      const SizedBox(height: 4),
      const PriceStatus(),
      ..._lines(all, {InsightKind.topContributor, InsightKind.biggestDrag, InsightKind.fees}, base),

      if (cls == null && byClass.length >= 2) ...[
        SectionLabel(t.byAssetClass),
        const HairlineDivider(),
        for (final k in present)
          _ClassRow(
            label: assetClassLabel(t, k),
            valueText: CurrencyText.formatAmount(byClass[k]!.fold<double>(0, (a, p) => a + p.marketValueBase), base),
            gain: byClass[k]!.fold<double>(0, (a, p) => a + p.unrealizedBase + p.realizedBase),
            base: base,
            onTap: () => setState(() => _class = k),
          ),
      ],

      SectionLabel(t.returnByHolding),
      for (final r in shown)
        BarRow(
          label: r.symbol,
          sublabel: r.name,
          valueText: CurrencyText.formatSigned(r.returnBase, base),
          fraction: maxAbs > 0 ? r.returnBase.abs() / maxAbs : 0,
          barColor: signColor(context, r.returnBase),
          valueColor: signColor(context, r.returnBase),
        ),
      const SizedBox(height: 4),
      BaseCurrencyNote(t.shownInBaseCurrency(base)),

      SectionLabel(t.investedByMonth),
      MonthlyBars(data: ins.investedByMonth(trades), format: (v) => CurrencyText.formatAmount(v, base)),

      SectionLabel(breakdownTitle),
      const HairlineDivider(),
      _KeyValue(label: t.unrealisedGain, text: CurrencyText.formatSigned(s.unrealizedBase, base), color: signColor(context, s.unrealizedBase)),
      _KeyValue(label: t.realisedGain, text: CurrencyText.formatSigned(s.realizedBase, base), color: signColor(context, s.realizedBase)),
      _KeyValue(label: t.dividendIncome, text: CurrencyText.formatSigned(s.dividendsBase, base), color: signColor(context, s.dividendsBase)),
      _KeyValue(label: t.feesPaid, text: CurrencyText.formatAmount(fees, base), color: c.textPrimary),
      if (open.isNotEmpty)
        _KeyValue(label: t.holdingsInProfit, text: t.winRateValue(winners.toString(), open.length.toString()), color: c.textPrimary),
    ];
  }

  // --------------------------------------------------------------------- income

  List<Widget> _income(
    BuildContext context, {
    required List<Dividend> dividends,
    required List<Position> positions,
    required PortfolioSummary s,
    required InsightsService ins,
    required String base,
    required List<Insight> all,
  }) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    final thisYear = DateTime.now().year;

    if (dividends.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Center(child: Text(t.incomeEmpty, style: TextStyle(color: c.textSecondary))),
        ),
      ];
    }

    // Years that have dividends, newest first, always including this year.
    final years = <int>{thisYear, for (final d in dividends) d.paymentDate.year}.toList()..sort((a, b) => b.compareTo(a));
    final year = (_year != null && years.contains(_year)) ? _year! : thisYear;

    final yoy = ins.dividendsYoY(dividends, now: DateTime(year));
    final yearTotal = yoy.thisYear.fold<double>(0, (a, v) => a + v);
    final prevTotal = yoy.lastYear.fold<double>(0, (a, v) => a + v);
    final inYear = [for (final d in dividends) if (d.paymentDate.year == year) d];
    final payers = ins.dividendsBySymbol(inYear);
    final maxPay = payers.isEmpty ? 0.0 : payers.first.amountBase;
    final yieldPct = (year == thisYear && s.costBase > 0) ? yearTotal / s.costBase * 100 : null;

    // Donut: five biggest payers that year, the rest folded into "Other".
    final donut = <DonutSlice>[];
    for (var i = 0; i < payers.length && i < 5; i++) {
      donut.add(DonutSlice(
        label: payers[i].symbol,
        value: payers[i].amountBase,
        color: ChartPalette.color(context, i),
        detail: yearTotal > 0 ? '${(payers[i].amountBase / yearTotal * 100).toStringAsFixed(1)}%' : '',
      ));
    }
    if (payers.length > 5) {
      final rest = payers.skip(5).fold<double>(0, (a, p) => a + p.amountBase);
      donut.add(DonutSlice(
        label: t.othersLabel,
        value: rest,
        color: c.textTertiary,
        detail: yearTotal > 0 ? '${(rest / yearTotal * 100).toStringAsFixed(1)}%' : '',
      ));
    }

    return [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final y in years) ChoicePill(label: '$y', selected: y == year, onTap: () => setState(() => _year = y)),
            ],
          ),
        ),
      ),
      SectionLabel(t.incomeYearLabel('$year'), padding: const EdgeInsets.only(top: 24, bottom: 8)),
      Text(CurrencyText.formatAmount(yearTotal, base), style: AppTheme.numeral(context, size: 32, weight: FontWeight.w600).copyWith(letterSpacing: -0.6)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 14,
        children: [
          Text(t.incomeLastYear(CurrencyText.formatAmount(prevTotal, base)), style: TextStyle(fontSize: 13, color: c.textSecondary)),
          if (yieldPct != null) Text('${t.yieldOnCost}  ${yieldPct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
      SectionLabel(t.dividendsYoY),
      YoYBars(thisYear: yoy.thisYear, lastYear: yoy.lastYear, year: year, format: (v) => CurrencyText.formatAmount(v, base)),
      if (payers.isNotEmpty) ...[
        SectionLabel(t.incomeSources),
        DonutChart(slices: donut, totalText: CurrencyText.formatAmount(yearTotal, base), totalCaption: t.chartTotal),
        SectionLabel(t.byHolding),
        for (final p in payers)
          BarRow(
            label: p.symbol,
            valueText: CurrencyText.formatAmount(p.amountBase, base),
            fraction: maxPay > 0 ? p.amountBase / maxPay : 0,
            barColor: c.accent,
          ),
        const SizedBox(height: 4),
        BaseCurrencyNote(t.shownInBaseCurrency(base)),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Center(child: Text(t.incomeEmptyYear('$year'), style: TextStyle(color: c.textSecondary))),
        ),
    ];
  }

  // ---------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([repo, settings]),
        builder: (context, _) {
          final base = settings.baseCurrency;

          if (repo.trades.isEmpty && repo.dividends.isEmpty) {
            return Center(child: Text(t.insightsEmpty, style: TextStyle(color: c.textSecondary)));
          }

          final svc = PortfolioService(fx: fx, baseCurrency: base);
          final ins = InsightsService(fx: fx, baseCurrency: base);
          final positionsAll = svc.positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings);

          // Asset-class filter: everything on Performance / Income follows it.
          final present = [for (final k in AssetClass.values) if (positionsAll.any((p) => p.assetClass == k)) k];
          final AssetClass? cls = (_class != null && present.contains(_class)) ? _class : null;
          final positions = cls == null ? positionsAll : [for (final p in positionsAll) if (p.assetClass == cls) p];
          final trades = cls == null ? repo.trades : [for (final x in repo.trades) if (_classOf(x.accountId, x.symbol) == cls) x];
          final dividends = cls == null ? repo.dividends : [for (final d in repo.dividends) if (_classOf(d.accountId, d.symbol) == cls) d];

          final s = svc.summary(positions);
          final all = ins.insights(positions, trades, dividends);

          final List<Widget> body;
          switch (_tab) {
            case 0:
              body = _performance(
                context,
                positionsAll: positionsAll,
                positions: positions,
                present: present,
                cls: cls,
                trades: trades,
                s: s,
                all: all,
                ins: ins,
                base: base,
              );
              break;
            case 1:
              body = _income(context, dividends: dividends, positions: positions, s: s, ins: ins, base: base, all: all);
              break;
            default:
              body = [
                ..._lines(all, {InsightKind.concentration, InsightKind.currency}, base),
                const AllocationView(),
              ];
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              ScreenTitle(t.navInsights),
              TextTabs(
                labels: [t.tabPerformance, t.tabIncome, t.navAllocation],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              if (_tab != 2 && present.length >= 2) _classPills(t, present, cls),
              ...body,
            ],
          );
        },
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double gain;
  final String base;
  final VoidCallback onTap;
  const _ClassRow({required this.label, required this.valueText, required this.gain, required this.base, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(valueText, style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(CurrencyText.formatSigned(gain, base), style: AppTheme.numeral(context, size: 12, weight: FontWeight.w500, color: signColor(context, gain))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const HairlineDivider(),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _KeyValue({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.textSecondary))),
              Text(text, style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500, color: color)),
            ],
          ),
        ),
        const HairlineDivider(),
      ],
    );
  }
}
