import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// "Prices updated 2026-10-22 10:41", or a small spinner while refreshing.
class PriceStatus extends StatelessWidget {
  const PriceStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([prices, repo]),
      builder: (context, _) {
        final last = prices.lastUpdated;
        final String text;
        if (prices.refreshing) {
          text = t.pricesUpdating;
        } else if (last == null) {
          text = t.pricesNever;
        } else {
          text = t.pricesUpdated(DateFormat('yyyy-MM-dd HH:mm').format(last));
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prices.refreshing) ...[
              SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.textTertiary)),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(text, style: TextStyle(fontSize: 11, color: c.textTertiary))),
          ],
        );
      },
    );
  }
}
