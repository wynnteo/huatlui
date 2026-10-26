import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';
import 'holding_detail_screen.dart';

/// Per-item screen, so every amount here is in the holding's OWN currency.
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  /// A holding whose price was never fetched (or is a week old) is flagged,
  /// because its gain/loss is only as good as that price.
  String? _priceNote(AppLocalizations t, Position p) {
    if (p.assetClass == AssetClass.cash) return null;
    final updated = repo.holdingFor(p.accountId, p.symbol)?.priceUpdatedAt;
    if (updated == null) return t.priceNotUpdated;
    if (DateTime.now().difference(updated).inDays >= 7) return t.priceAsOf(fmtDate(updated));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([repo, settings]),
        builder: (context, _) {
          final svc = PortfolioService(fx: fx, baseCurrency: settings.baseCurrency);
          final open = svc
              .positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings)
              .where((p) => p.isOpen)
              .toList();

          return RefreshIndicator(
            onRefresh: () => prices.refreshAll(),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            children: [
              ScreenTitle(t.navHoldings),
              if (open.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(t.holdingsTapHint, style: TextStyle(fontSize: 12, color: c.textTertiary)),
                ),
              if (open.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text(t.holdingsEmpty, style: TextStyle(color: c.textSecondary))),
                ),
              for (final account in repo.accounts) ...[
                if (open.any((p) => p.accountId == account.id)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(account.name.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: c.textTertiary)),
                  ),
                  const HairlineDivider(),
                  for (final p in open.where((p) => p.accountId == account.id)) ...[
                    _HoldingRow(
                      position: p,
                      priceNote: _priceNote(t, p),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HoldingDetailScreen(accountId: p.accountId, symbol: p.symbol)),
                      ),
                    ),
                    const HairlineDivider(),
                  ],
                ],
              ],
            ],
          ),
          );
        },
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final Position position;
  final String? priceNote;
  final VoidCallback onTap;
  const _HoldingRow({required this.position, required this.priceNote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = position;
    final gainColor = signColor(context, p.unrealizedLocal);
    final pct = '${p.unrealizedPct > 0 ? '+' : ''}${p.unrealizedPct.toStringAsFixed(1)}%';

    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.symbol, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                const SizedBox(height: 2),
                Text('${fmtQty(p.quantity)} @ ${CurrencyText.formatPrice(p.avgCostLocal, p.currency)}',
                    style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyText.formatAmount(p.marketValueLocal, p.currency), style: AppTheme.numeral(context, size: 15)),
              const SizedBox(height: 2),
              Text('${CurrencyText.formatSigned(p.unrealizedLocal, p.currency)}  $pct',
                  style: AppTheme.numeral(context, size: 11, weight: FontWeight.w500, color: gainColor)),
              if (priceNote != null) ...[
                const SizedBox(height: 2),
                Text(priceNote!, style: TextStyle(fontSize: 11, color: c.warning)),
              ] else if (p.assetClass != AssetClass.cash && p.currentPrice > 0) ...[
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context)!.latestPrice(CurrencyText.formatPrice(p.currentPrice, p.currency)),
                    style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ],
          ),
        ],
      ),
    ),
    );
  }
}
