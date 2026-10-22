import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../services/activity.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_tile.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';
import 'entry_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: c.textTertiary),
                    const SizedBox(height: 16),
                    Text(t.dashboardEmptyTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 8),
                    Text(t.dashboardEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5)),
                    const SizedBox(height: 20),
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
          final recent = buildActivity(repo.trades, repo.dividends).take(5).toList();
          final accountNames = {for (final a in repo.accounts) a.id: a.name};

          final ret = s.totalReturnBase;
          final retColor = signColor(context, ret);
          final pctText = '${s.returnPct > 0 ? '+' : ''}${s.returnPct.toStringAsFixed(2)}%';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ScreenTitle(t.appTitle),

              // Hero: Total Return = capital gain + dividends. Dividends are
              // one part of it, shown as a chip beside capital gain.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.totalReturn, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                    const SizedBox(height: 8),
                    Text(CurrencyText.formatSigned(ret, base),
                        style: AppTheme.numeral(context, size: 32, weight: FontWeight.w700, color: retColor)),
                    const SizedBox(height: 8),
                    _Pill(text: pctText, color: retColor),
                    const SizedBox(height: 18),
                    const HairlineDivider(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _Stat(label: t.capitalGain, text: CurrencyText.formatSigned(s.capitalGainBase, base), color: signColor(context, s.capitalGainBase))),
                        Expanded(child: _Stat(label: t.dividendIncome, text: CurrencyText.formatSigned(s.dividendsBase, base), color: signColor(context, s.dividendsBase))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BaseCurrencyNote(t.shownInBaseCurrency(base)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _Stat(label: t.portfolioValue, text: CurrencyText.formatAmount(s.marketValueBase, base), color: c.textPrimary)),
                  Expanded(child: _Stat(label: t.totalInvested, text: CurrencyText.formatAmount(s.costBase, base), color: c.textPrimary)),
                ],
              ),

              const SizedBox(height: 28),
              Text(t.recentTransactions, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 4),
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const HairlineDivider(),
                ActivityTile(activity: recent[i], accountName: accountNames[recent[i].accountId] ?? ''),
              ],
            ],
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
        Text(label, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
        const SizedBox(height: 4),
        Text(text, style: AppTheme.numeral(context, size: 16, color: color)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: AppTheme.numeral(context, size: 13, color: color)),
    );
  }
}
