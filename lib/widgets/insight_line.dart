import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/insights_service.dart';
import '../theme/app_colors.dart';
import 'currency_display.dart';

/// One plain sentence with a thin accent rule on the left. No icons.
class InsightLine extends StatelessWidget {
  final Insight insight;
  final String base;
  const InsightLine({super.key, required this.insight, required this.base});

  String _text(AppLocalizations t) {
    final i = insight;
    switch (i.kind) {
      case InsightKind.topContributor:
        return t.insightTopContributor(i.label, CurrencyText.formatSigned(i.amount, base), i.pct.toStringAsFixed(0));
      case InsightKind.biggestDrag:
        return t.insightBiggestDrag(i.label, CurrencyText.formatSigned(i.amount, base));
      case InsightKind.concentration:
        return t.insightConcentration(i.count.toString(), i.pct.toStringAsFixed(0));
      case InsightKind.dividends:
        return t.insightDividends(CurrencyText.formatAmount(i.amount, base), i.pct.toStringAsFixed(1));
      case InsightKind.currency:
        return t.insightCurrency(i.pct.toStringAsFixed(0), i.label);
      case InsightKind.fees:
        return t.insightFees(CurrencyText.formatAmount(i.amount, base), i.pct.toStringAsFixed(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 2, color: c.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(_text(t), style: TextStyle(fontSize: 14, height: 1.45, color: c.textPrimary))),
          ],
        ),
      ),
    );
  }
}
