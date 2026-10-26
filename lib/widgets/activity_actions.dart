import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/trade.dart';
import '../screens/entry_form_screen.dart';
import '../services/activity.dart';

/// Opens the entry form on an existing buy / sell / dividend.
Future<void> editActivity(BuildContext context, Activity a) async {
  if (a.kind == ActivityKind.dividend) {
    for (final d in repo.dividends) {
      if (d.id == a.id) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => EntryFormScreen(editDividend: d)));
        return;
      }
    }
  } else {
    for (final x in repo.trades) {
      if (x.id == a.id) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => EntryFormScreen(editTrade: x)));
        return;
      }
    }
  }
}

Future<bool> _confirm(BuildContext context) async {
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
  return ok == true;
}

/// Asks first. Refuses to delete a purchase that later sales depend on.
/// Returns true if it was deleted.
Future<bool> deleteTradeChecked(BuildContext context, Trade trade) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!await _confirm(context)) return false;
  final after = [for (final x in repo.trades) if (x.id != trade.id) x];
  if (changeBreaksHoldings(repo.trades, after)) {
    messenger.showSnackBar(SnackBar(content: Text(t.errBreaksHoldings)));
    return false;
  }
  await repo.deleteTrade(trade.id);
  return true;
}

Future<bool> deleteDividendChecked(BuildContext context, Dividend dividend) async {
  if (!await _confirm(context)) return false;
  await repo.deleteDividend(dividend.id);
  return true;
}

Future<bool> deleteActivity(BuildContext context, Activity a) async {
  if (a.kind == ActivityKind.dividend) {
    for (final d in repo.dividends) {
      if (d.id == a.id) return deleteDividendChecked(context, d);
    }
  } else {
    for (final x in repo.trades) {
      if (x.id == a.id) return deleteTradeChecked(context, x);
    }
  }
  return false;
}
