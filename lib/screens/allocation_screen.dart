import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/chart_palette.dart';
import '../widgets/donut_chart.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';

/// Current vs target weights, with concentration-risk flags. This is an
/// aggregate view, so everything is converted to the base currency.
///
/// It is a plain widget (no Scaffold / title) because it now lives inside
/// the Insights screen.
class AllocationView extends StatefulWidget {
  const AllocationView({super.key});

  @override
  State<AllocationView> createState() => _AllocationViewState();
}

class _AllocationViewState extends State<AllocationView> {
  AllocationGroup _group = AllocationGroup.assetClass;

  String _groupLabel(AppLocalizations t, AllocationGroup g) {
    switch (g) {
      case AllocationGroup.assetClass:
        return t.groupAssetClass;
      case AllocationGroup.account:
        return t.groupAccount;
      case AllocationGroup.currency:
        return t.groupCurrency;
      case AllocationGroup.holding:
        return t.groupHolding;
    }
  }

  String _sliceLabel(AppLocalizations t, AllocationSlice s) {
    if (_group == AllocationGroup.assetClass) {
      return assetClassLabel(t, enumByName(AssetClass.values, s.key, AssetClass.other));
    }
    return s.label;
  }

  String? _message(AppLocalizations t, AllocationSlice s, String label) {
    final cur = s.currentPct.toStringAsFixed(1);
    final tgt = s.targetPct?.toStringAsFixed(0) ?? '';
    switch (s.reason) {
      case RiskReason.none:
        return null;
      case RiskReason.singleHolding:
        return t.concentrationRiskAbsolute(label, cur);
      case RiskReason.overTarget:
        return t.concentrationRiskOverTarget(label, cur, tgt);
      case RiskReason.underTarget:
        return t.concentrationRiskUnderTarget(label, cur, tgt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return ListenableBuilder(
      listenable: Listenable.merge([repo, settings]),
      builder: (context, _) {
        final base = settings.baseCurrency;
        final svc = PortfolioService(fx: fx, baseCurrency: base);
        final positions = svc.positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings);
        final accountNames = {for (final a in repo.accounts) a.id: a.name};
        final slices = svc.allocation(positions, _group, accountNames: accountNames);
        final highCount = slices.where((s) => s.risk == RiskLevel.high).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppSegmented(
                labels: [for (final g in AllocationGroup.values) _groupLabel(t, g)],
                selected: AllocationGroup.values.indexOf(_group),
                onChanged: (i) => setState(() => _group = AllocationGroup.values[i]),
              ),
            ),
            const SizedBox(height: 10),
            BaseCurrencyNote(t.shownInBaseCurrency(base)),
            const SizedBox(height: 8),

            if (slices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: Text(t.allocationEmpty, style: TextStyle(color: c.textSecondary))),
              ),

            if (slices.isNotEmpty) ...[
              const SizedBox(height: 20),
              DonutChart(
                totalText: CurrencyText.formatAmount(slices.fold<double>(0, (a, x) => a + x.valueBase), base),
                totalCaption: t.chartTotal,
                slices: [
                  for (var i = 0; i < slices.length; i++)
                    DonutSlice(
                      label: _sliceLabel(t, slices[i]),
                      value: slices[i].valueBase,
                      color: ChartPalette.color(context, i),
                      detail: '${slices[i].currentPct.toStringAsFixed(1)}%',
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (highCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c.loss, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('${t.concentrationRiskTitle} · ${t.needAttention(highCount.toString())}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.loss)),
                  ],
                ),
              ),

            for (var i = 0; i < slices.length; i++) ...[
              _SliceRow(
                slice: slices[i],
                label: _sliceLabel(t, slices[i]),
                base: base,
                dot: ChartPalette.color(context, i),
                message: _message(t, slices[i], _sliceLabel(t, slices[i])),
              ),
              const HairlineDivider(),
            ],
          ],
        );
      },
    );
  }
}

class _SliceRow extends StatelessWidget {
  final AllocationSlice slice;
  final String label;
  final String base;
  final String? message;
  final Color dot;

  const _SliceRow({required this.slice, required this.label, required this.base, required this.message, required this.dot});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    final s = slice;

    final Color barColor;
    switch (s.risk) {
      case RiskLevel.high:
        barColor = c.loss;
        break;
      case RiskLevel.warning:
        barColor = c.warning;
        break;
      case RiskLevel.none:
        barColor = c.accent;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary))),
              Text('${s.currentPct.toStringAsFixed(1)}%',
                  style: AppTheme.numeral(context, size: 15, weight: FontWeight.w500, color: s.risk == RiskLevel.none ? c.textPrimary : barColor)),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(current: s.currentPct, target: s.targetPct, color: barColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(CurrencyText.formatAmount(s.valueBase, base), style: TextStyle(fontSize: 11, color: c.textTertiary)),
              const Spacer(),
              Text(
                s.targetPct != null ? t.targetPct(s.targetPct!.toStringAsFixed(0)) : t.noTargetSet,
                style: TextStyle(fontSize: 11, color: c.textTertiary),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: TextStyle(fontSize: 12, height: 1.4, color: s.risk == RiskLevel.high ? c.loss : c.warning)),
          ],
        ],
      ),
    );
  }
}

/// A thin track with a filled "current" bar and a small tick for the target.
class _Bar extends StatelessWidget {
  final double current;
  final double? target;
  final Color color;

  const _Bar({required this.current, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final fillW = w * (current / 100).clamp(0.0, 1.0).toDouble();
        return SizedBox(
          height: 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2))),
              Container(width: fillW, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              if (target != null)
                Positioned(
                  left: w * (target! / 100).clamp(0.0, 1.0).toDouble() - 1,
                  top: -4,
                  bottom: -4,
                  child: Container(width: 2, color: c.textPrimary),
                ),
            ],
          ),
        );
      },
    );
  }
}
