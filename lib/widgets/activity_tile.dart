import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'currency_display.dart';
import 'ui_helpers.dart';

/// One buy / sell / dividend line. Amounts are always in the entry's own
/// original currency; nothing is converted on a per-item row.
class ActivityTile extends StatelessWidget {
  final Activity activity;
  final String accountName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ActivityTile({super.key, required this.activity, required this.accountName, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    final a = activity;

    late final String kindLabel;
    late final Color kindColor;
    switch (a.kind) {
      case ActivityKind.buy:
        kindLabel = t.buy;
        kindColor = c.accentText;
        break;
      case ActivityKind.sell:
        kindLabel = t.sell;
        kindColor = c.textSecondary;
        break;
      case ActivityKind.dividend:
        kindLabel = t.dividend;
        kindColor = c.gain;
        break;
    }

    final isDividend = a.kind == ActivityKind.dividend;
    final amountText = isDividend ? CurrencyText.formatSigned(a.amount, a.currency) : CurrencyText.formatAmount(a.amount, a.currency);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              child: Text(kindLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kindColor)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.symbol, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${fmtDate(a.date)} · $accountName',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.textTertiary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText, style: AppTheme.numeral(context, size: 14, color: isDividend ? c.gain : c.textPrimary)),
                if (a.quantity != null && a.price != null) ...[
                  const SizedBox(height: 2),
                  Text('${fmtQty(a.quantity!)} @ ${CurrencyText.formatAmount(a.price!, a.currency)}',
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
