import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../services/activity.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_tile.dart';
import '../widgets/ui_helpers.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Activity a) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteEntryTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    if (a.kind == ActivityKind.dividend) {
      await repo.deleteDividend(a.id);
    } else {
      await repo.deleteTrade(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final items = buildActivity(repo.trades, repo.dividends);
          final accountNames = {for (final a in repo.accounts) a.id: a.name};

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ScreenTitle(t.navTransactions),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text(t.transactionsEmpty, style: TextStyle(color: c.textSecondary))),
                ),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const HairlineDivider(),
                ActivityTile(
                  activity: items[i],
                  accountName: accountNames[items[i].accountId] ?? '',
                  onLongPress: () => _confirmDelete(context, items[i]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
