import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/holding_record.dart';
import '../services/parse_utils.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';

/// Per-item screen, so every amount here is in the holding's OWN currency.
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  Future<void> _edit(BuildContext context, Position p) async {
    final t = AppLocalizations.of(context)!;
    final existing = repo.holdingFor(p.accountId, p.symbol);
    final priceCtrl = TextEditingController(text: p.currentPrice.toString());
    final targetCtrl = TextEditingController(text: existing?.targetPct?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.editHoldingTitle(p.symbol)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.currentPriceLabel(p.currency)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.targetPctLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
        ],
      ),
    );
    if (ok != true) return;

    final price = parseNumber(priceCtrl.text);
    if (price == null || price < 0) return;
    final target = parseNumber(targetCtrl.text);

    final record = existing ??
        HoldingRecord(
          id: const Uuid().v4(),
          accountId: p.accountId,
          symbol: p.symbol,
          name: p.name,
          assetClass: p.assetClass,
          currency: p.currency,
          currentPrice: price,
        );
    await repo.putHolding(record.copyWith(
      currentPrice: price,
      priceUpdatedAt: DateTime.now(),
      targetPct: target,
      clearTarget: target == null,
    ));
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    _HoldingRow(position: p, onTap: () => _edit(context, p)),
                    const HairlineDivider(),
                  ],
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final Position position;
  final VoidCallback onTap;
  const _HoldingRow({required this.position, required this.onTap});

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
                Text('${fmtQty(p.quantity)} @ ${CurrencyText.formatAmount(p.avgCostLocal, p.currency)}',
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
            ],
          ),
        ],
      ),
    ),
    );
  }
}
