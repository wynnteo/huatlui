import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../services/activity.dart';
import '../services/insights_service.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_tile.dart';
import '../widgets/currency_display.dart';
import '../widgets/insight_line.dart';
import '../widgets/mini_charts.dart';
import '../widgets/price_status.dart';
import '../widgets/ui_helpers.dart';
import 'entry_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  /// Lets the "more insights" link switch tabs without this screen knowing
  /// anything about the shell.
  final VoidCallback? onOpenInsights;
  const DashboardScreen({super.key, this.onOpenInsights});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([repo, settings, fx]),
        builder: (context, _) {
          final base = settings.baseCurrency;

          if (repo.trades.isEmpty && repo.dividends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, size: 40, color: c.textTertiary),
                    const SizedBox(height: 16),
                    Text(t.dashboardEmptyTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
                    const SizedBox(height: 8),
                    Text(t.dashboardEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5)),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen())),
                      child: Text(t.addEntry),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => repo.loadDemo(), child: Text(t.loadDemoData)),
                  ],
                ),
              ),
            );
          }

          final svc = PortfolioService(fx: fx, baseCurrency: base);
          final positions = svc.positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings);
          final s = svc.summary(positions);
          final slices = svc.allocation(positions, AllocationGroup.assetClass);
          final highlights = InsightsService(fx: fx, baseCurrency: base).insights(positions, repo.trades, repo.dividends).take(2).toList();
          final recent = buildActivity(repo.trades, repo.dividends).take(5).toList();
          final accountNames = {for (final a in repo.accounts) a.id: a.name};

          // Headline is price gain/loss only. Dividends are shown on their own
          // below, never blended in, so a loss is never hidden by income.
          final ret = s.capitalGainBase;
          final retColor = signColor(context, ret);
          final pctText = '${s.capitalGainPct > 0 ? '+' : ''}${s.capitalGainPct.toStringAsFixed(2)}%';

          return RefreshIndicator(
            onRefresh: () => prices.refreshAll(),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            children: [
              Text(t.portfolioValue, style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyText.formatAmount(s.marketValueBase, base),
                  style: AppTheme.numeral(context, size: 40, weight: FontWeight.w600).copyWith(letterSpacing: -1),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(CurrencyText.formatSigned(ret, base), style: AppTheme.numeral(context, size: 15, color: retColor)),
                  Text(pctText, style: AppTheme.numeral(context, size: 15, weight: FontWeight.w500, color: retColor)),
                  Text(t.capitalGain, style: TextStyle(fontSize: 13, color: c.textTertiary)),
                ],
              ),
              const SizedBox(height: 6),
              BaseCurrencyNote(t.shownInBaseCurrency(base)),
              const SizedBox(height: 2),
              const PriceStatus(),
              const SizedBox(height: 4),
              Text(
                !fx.hasLiveData
                    ? 'FX: indicative offline rates (not current market data)'
                    : 'FX: ${fx.isStale ? 'cached' : 'daily reference'} rates as of '
                        '${fx.asOf?.year}-${fx.asOf?.month.toString().padLeft(2, '0')}-'
                        '${fx.asOf?.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: c.textTertiary),
              ),

              const SizedBox(height: 28),
              const HairlineDivider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Stat(label: t.totalInvested, text: CurrencyText.formatAmount(s.costBase, base), color: c.textPrimary)),
                  Expanded(child: _Stat(label: t.dividendIncome, text: CurrencyText.formatSigned(s.dividendsBase, base), color: signColor(context, s.dividendsBase))),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _Stat(label: t.unrealisedGain, text: CurrencyText.formatSigned(s.unrealizedBase, base), color: signColor(context, s.unrealizedBase))),
                  Expanded(child: _Stat(label: t.realisedGain, text: CurrencyText.formatSigned(s.realizedBase, base), color: signColor(context, s.realizedBase))),
                ],
              ),
              const SizedBox(height: 16),
              const HairlineDivider(),

              if (slices.isNotEmpty) ...[
                SectionLabel(t.navAllocation),
                StackedStrip(weights: [for (final x in slices) x.currentPct]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < slices.length && i < 4; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: StackedStrip.shade(context, i, slices.length), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${assetClassLabel(t, enumByName(AssetClass.values, slices[i].key, AssetClass.other))} ${slices[i].currentPct.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ],

              if (highlights.isNotEmpty) ...[
                SectionLabel(t.insightsHighlights),
                for (final h in highlights) InsightLine(insight: h, base: base),
                if (onOpenInsights != null)
                  TextButton(
                    onPressed: onOpenInsights,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('${t.insightsMore}  →'),
                  ),
              ],

              SectionLabel(t.recentTransactions),
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const HairlineDivider(),
                ActivityTile(activity: recent[i], accountName: accountNames[recent[i].accountId] ?? ''),
              ],
            ],
          ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _Stat({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.colors.textTertiary)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: AppTheme.numeral(context, size: 15, weight: FontWeight.w500, color: color)),
        ),
      ],
    );
  }
}
