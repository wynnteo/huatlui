import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../services/activity.dart';
import '../services/parse_utils.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_actions.dart';
import '../widgets/activity_tile.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';
import 'entry_form_screen.dart';
import 'investment_review_editor.dart';
import 'what_if_buy_screen.dart';

/// One holding in full: the facts about it at the top, then every buy, sell
/// and dividend that makes it up. Amounts are in the holding's own currency
/// (the base-currency equivalent is shown once, under the value).
///
/// The latest price is never typed in here: it always comes from the
/// price refresh.
class HoldingDetailScreen extends StatelessWidget {
  final String accountId;
  final String symbol;
  const HoldingDetailScreen({super.key, required this.accountId, required this.symbol});

  Future<void> _editTarget(BuildContext context, HoldingRecord? record, Position p) async {
    final t = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: record?.targetPct?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.detailTarget),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.targetPctLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
        ],
      ),
    );
    if (ok != true || record == null) return;
    final target = parseNumber(ctrl.text);
    await repo.putHolding(record.copyWith(targetPct: target, clearTarget: target == null));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(symbol),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.addEntry,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EntryFormScreen(prefillAccountId: accountId, prefillSymbol: symbol)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([repo, settings, prices]),
          builder: (context, _) {
            final base = settings.baseCurrency;
            final key = HoldingRecord.keyOf(accountId, symbol);

            Position? p;
            for (final x in PortfolioService(fx: fx, baseCurrency: base)
                .positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings)) {
              if (HoldingRecord.keyOf(x.accountId, x.symbol) == key) {
                p = x;
                break;
              }
            }
            if (p == null) {
              return Center(child: Text(t.detailEmpty, style: TextStyle(color: c.textSecondary)));
            }

            final trades = [for (final x in repo.trades) if (HoldingRecord.keyOf(x.accountId, x.symbol) == key) x];
            final divs = [for (final d in repo.dividends) if (HoldingRecord.keyOf(d.accountId, d.symbol) == key) d];
            final activities = buildActivity(trades, divs);
            final record = repo.holdingFor(accountId, symbol);
            String accountName = '';
            for (final a in repo.accounts) {
              if (a.id == accountId) accountName = a.name;
            }
            final accountNames = {for (final a in repo.accounts) a.id: a.name};

            final feesLocal = trades.fold<double>(0, (s, x) => s + x.fees);
            final dividendsLocal = divs.fold<double>(0, (s, d) => s + d.netAmount);
            final ccy = p.currency;

            final updated = record?.priceUpdatedAt;
            final String priceNote;
            final bool priceWarn;
            if (p.assetClass == AssetClass.cash) {
              priceNote = '';
              priceWarn = false;
            } else if (updated == null) {
              priceNote = t.priceNotUpdated;
              priceWarn = true;
            } else {
              priceNote = t.pricesUpdated(DateFormat('yyyy-MM-dd HH:mm').format(updated));
              priceWarn = DateTime.now().difference(updated).inDays >= 7;
            }

            final isOpen = p.isOpen;
            final heroValue = isOpen ? p.marketValueLocal : p.realizedLocal;
            final heroColor = isOpen ? c.textPrimary : signColor(context, p.realizedLocal);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
              children: [
                Text(p.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: c.textPrimary)),
                const SizedBox(height: 4),
                Text('${assetClassLabel(t, p.assetClass)} · $accountName · $ccy', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                const SizedBox(height: 24),

                // Hero: what it is worth now (or what it made, if it is closed).
                Text(isOpen ? t.detailMarketValue : t.realisedGain, style: TextStyle(fontSize: 12, color: c.textTertiary)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isOpen ? CurrencyText.formatAmount(heroValue, ccy) : CurrencyText.formatSigned(heroValue, ccy),
                    style: AppTheme.numeral(context, size: 34, weight: FontWeight.w600, color: heroColor).copyWith(letterSpacing: -0.8),
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(CurrencyText.formatSigned(p.unrealizedLocal, ccy), style: AppTheme.numeral(context, size: 14, color: signColor(context, p.unrealizedLocal))),
                      Text('${p.unrealizedPct > 0 ? '+' : ''}${p.unrealizedPct.toStringAsFixed(2)}%',
                          style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500, color: signColor(context, p.unrealizedLocal))),
                      Text(t.unrealisedGain, style: TextStyle(fontSize: 12, color: c.textTertiary)),
                    ],
                  ),
                  if (ccy != base) ...[
                    const SizedBox(height: 4),
                    Text('≈ ${CurrencyText.formatAmount(p.marketValueBase, base)}', style: TextStyle(fontSize: 12, color: c.textTertiary)),
                  ],
                ],

                if (isOpen) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(Localizations.localeOf(context).languageCode == 'zh'
                        ? '模拟加仓' : 'What-if buy'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WhatIfBuyScreen(
                          accountId: accountId,
                          symbol: symbol,
                        ),
                      ),
                    ),
                  ),
                ],

                SectionLabel(t.holdingDetails),
                const HairlineDivider(),
                _Row(label: t.detailUnits, value: fmtQty(p.quantity)),
                if (isOpen) _Row(label: t.detailAvgPrice, value: CurrencyText.formatPrice(p.avgCostLocal, ccy)),
                if (p.assetClass != AssetClass.cash)
                  _Row(
                    label: t.detailLatestPrice,
                    value: p.currentPrice > 0 ? CurrencyText.formatPrice(p.currentPrice, ccy) : '–',
                    note: priceNote,
                    noteWarn: priceWarn,
                  ),
                if (isOpen) _Row(label: t.detailCost, value: CurrencyText.formatAmount(p.costLocal, ccy)),
                _Row(label: t.realisedGain, value: CurrencyText.formatSigned(p.realizedLocal, ccy), color: signColor(context, p.realizedLocal)),
                _Row(label: t.detailDividends, value: CurrencyText.formatSigned(dividendsLocal, ccy), color: signColor(context, dividendsLocal)),
                _Row(label: t.feesPaid, value: CurrencyText.formatAmount(feesLocal, ccy)),
                _Row(label: t.detailBroker, value: accountName),
                _Row(
                  label: t.detailTarget,
                  value: p.targetPct == null ? t.detailNotSet : '${p.targetPct!.toStringAsFixed(p.targetPct! % 1 == 0 ? 0 : 1)}%',
                  onTap: () => _editTarget(context, record, p!),
                ),

                if (record != null) ...[
                  SectionLabel(Localizations.localeOf(context).languageCode == 'zh' ? '投资复核' : 'Investment review'),
                  const HairlineDivider(),
                  _Row(
                    label: Localizations.localeOf(context).languageCode == 'zh' ? '状态' : 'Status',
                    value: reviewStatusLabel(record.reviewStatus, Localizations.localeOf(context).languageCode == 'zh'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvestmentReviewEditor(holding: record))),
                  ),
                  if (record.nextReviewDate != null)
                    _Row(
                      label: Localizations.localeOf(context).languageCode == 'zh' ? '下次复核' : 'Next review',
                      value: DateFormat('yyyy-MM-dd').format(record.nextReviewDate!),
                      note: reviewDue(record, DateTime.now()) ? (Localizations.localeOf(context).languageCode == 'zh' ? '待复核' : 'Review due') : null,
                      noteWarn: reviewDue(record, DateTime.now()),
                    ),
                  if ((record.investmentThesis ?? '').isNotEmpty)
                    Text(record.investmentThesis!, style: TextStyle(color: c.textSecondary)),
                  if ((record.reviewNotes ?? '').isNotEmpty)
                    Text(record.reviewNotes!, style: TextStyle(color: c.textTertiary)),
                ],
                SectionLabel('${t.detailTransactions} · ${activities.length}'),
                if (activities.isEmpty) Text(t.detailEmpty, style: TextStyle(color: c.textSecondary)),
                for (var i = 0; i < activities.length; i++) ...[
                  if (i > 0) const HairlineDivider(),
                  ActivityTile(
                    activity: activities[i],
                    accountName: accountNames[activities[i].accountId] ?? '',
                    onTap: () => editActivity(context, activities[i]),
                    onLongPress: () => deleteActivity(context, activities[i]),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// label on the left, value on the right, optional small note under the
/// value, hairline underneath. Tappable rows get a chevron.
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? note;
  final bool noteWarn;
  final VoidCallback? onTap;
  const _Row({required this.label, required this.value, this.color, this.note, this.noteWarn = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.textSecondary))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500, color: color)),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(note!, style: TextStyle(fontSize: 11, color: noteWarn ? c.warning : c.textTertiary)),
                    ],
                  ],
                ),
                if (onTap != null) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.chevron_right, size: 18, color: c.textTertiary)),
              ],
            ),
          ),
        ),
        const HairlineDivider(),
      ],
    );
  }
}
