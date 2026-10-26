import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../services/activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_actions.dart';
import '../widgets/activity_tile.dart';
import '../widgets/currency_display.dart';
import '../widgets/ui_helpers.dart';

enum _DatePreset { all, thisMonth, last30, thisYear, lastYear, custom }

/// The full transaction feed with filters on top: date range, type, broker
/// and asset class. An empty selection means "don't filter on this".
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _DatePreset _date = _DatePreset.all;
  DateTimeRange? _custom;
  final Set<ActivityKind> _kinds = {};
  final Set<String> _accounts = {}; // account ids
  final Set<AssetClass> _classes = {};

  bool get _anyActive =>
      _date != _DatePreset.all || _kinds.isNotEmpty || _accounts.isNotEmpty || _classes.isNotEmpty;

  void _clearAll() => setState(() {
        _date = _DatePreset.all;
        _custom = null;
        _kinds.clear();
        _accounts.clear();
        _classes.clear();
      });

  DateTimeRange? _dateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_date) {
      case _DatePreset.all:
        return null;
      case _DatePreset.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case _DatePreset.last30:
        return DateTimeRange(start: DateTime(now.year, now.month, now.day - 29), end: today);
      case _DatePreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case _DatePreset.lastYear:
        return DateTimeRange(start: DateTime(now.year - 1, 1, 1), end: DateTime(now.year - 1, 12, 31));
      case _DatePreset.custom:
        return _custom;
    }
  }

  List<Activity> _apply(List<Activity> items) {
    final range = _dateRange();
    return items.where((a) {
      if (_kinds.isNotEmpty && !_kinds.contains(a.kind)) return false;
      if (_accounts.isNotEmpty && !_accounts.contains(a.accountId)) return false;
      if (_classes.isNotEmpty) {
        final cls = repo.holdingFor(a.accountId, a.symbol)?.assetClass ?? AssetClass.other;
        if (!_classes.contains(cls)) return false;
      }
      if (range != null) {
        final day = DateTime(a.date.year, a.date.month, a.date.day);
        if (day.isBefore(range.start) || day.isAfter(range.end)) return false;
      }
      return true;
    }).toList();
  }

  // ---- labels ---------------------------------------------------------

  String _kindLabel(AppLocalizations t, ActivityKind k) {
    switch (k) {
      case ActivityKind.buy:
        return t.buy;
      case ActivityKind.sell:
        return t.sell;
      case ActivityKind.dividend:
        return t.dividend;
    }
  }

  String _dateLabel(AppLocalizations t) {
    switch (_date) {
      case _DatePreset.all:
        return t.filterDate;
      case _DatePreset.thisMonth:
        return t.rangeThisMonth;
      case _DatePreset.last30:
        return t.rangeLast30;
      case _DatePreset.thisYear:
        return t.rangeThisYear;
      case _DatePreset.lastYear:
        return t.rangeLastYear;
      case _DatePreset.custom:
        final r = _custom;
        return r == null ? t.filterDate : '${fmtDate(r.start)} – ${fmtDate(r.end)}';
    }
  }

  String _kindsLabel(AppLocalizations t) {
    if (_kinds.isEmpty) return t.filterType;
    final ordered = ActivityKind.values.where(_kinds.contains);
    return ordered.map((k) => _kindLabel(t, k)).join(', ');
  }

  String _accountsLabel(AppLocalizations t) {
    if (_accounts.isEmpty) return t.filterBroker;
    if (_accounts.length == 1) {
      for (final a in repo.accounts) {
        if (a.id == _accounts.first) return a.name;
      }
    }
    return t.filterBrokersCount(_accounts.length.toString());
  }

  String _classesLabel(AppLocalizations t) {
    if (_classes.isEmpty) return t.filterClass;
    if (_classes.length == 1) return assetClassLabel(t, _classes.first);
    return t.filterClassesCount(_classes.length.toString());
  }

  // ---- pickers --------------------------------------------------------

  Future<void> _pickDate() async {
    final t = AppLocalizations.of(context)!;
    const values = _DatePreset.values;
    final labels = [t.rangeAllTime, t.rangeThisMonth, t.rangeLast30, t.rangeThisYear, t.rangeLastYear, t.rangeCustom];
    final choice = await showModalBottomSheet<_DatePreset>(
      context: context,
      builder: (ctx) => _SheetShell(
        title: t.filterDate,
        child: Column(
          children: [
            for (var i = 0; i < values.length; i++)
              _SheetRow(label: labels[i], selected: _date == values[i], onTap: () => Navigator.pop(ctx, values[i])),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == _DatePreset.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: _custom,
      );
      if (picked == null) return;
      setState(() {
        _date = _DatePreset.custom;
        _custom = picked;
      });
    } else {
      setState(() => _date = choice);
    }
  }

  Future<void> _pickMulti<T>({
    required String title,
    required List<T> values,
    required List<String> labels,
    required Set<T> selected,
  }) async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _SheetShell(
          title: title,
          trailing: TextButton(
            onPressed: () {
              setState(selected.clear);
              setSheet(() {});
            },
            child: Text(t.filterClear),
          ),
          child: Column(
            children: [
              for (var i = 0; i < values.length; i++)
                _SheetRow(
                  label: labels[i],
                  selected: selected.contains(values[i]),
                  onTap: () {
                    setState(() {
                      if (!selected.remove(values[i])) selected.add(values[i]);
                    });
                    setSheet(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickKinds() {
    final t = AppLocalizations.of(context)!;
    return _pickMulti<ActivityKind>(
      title: t.filterType,
      values: ActivityKind.values,
      labels: [for (final k in ActivityKind.values) _kindLabel(t, k)],
      selected: _kinds,
    );
  }

  Future<void> _pickAccounts() {
    final t = AppLocalizations.of(context)!;
    final accounts = [...repo.accounts]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _pickMulti<String>(
      title: t.filterBroker,
      values: [for (final a in accounts) a.id],
      labels: [for (final a in accounts) a.name],
      selected: _accounts,
    );
  }

  Future<void> _pickClasses() {
    final t = AppLocalizations.of(context)!;
    // Only offer classes you actually hold, so the list stays short.
    final present = {for (final h in repo.holdings) h.assetClass};
    final classes = [for (final c in AssetClass.values) if (present.contains(c)) c];
    return _pickMulti<AssetClass>(
      title: t.filterClass,
      values: classes,
      labels: [for (final c in classes) assetClassLabel(t, c)],
      selected: _classes,
    );
  }

  // ---- build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([repo, settings]),
        builder: (context, _) {
          final base = settings.baseCurrency;
          final everything = buildActivity(repo.trades, repo.dividends);
          final items = _apply(everything);
          final accountNames = {for (final a in repo.accounts) a.id: a.name};

          var bought = 0.0, sold = 0.0, dividends = 0.0;
          for (final a in items) {
            final v = fx.toBaseHistorical(amount: a.amount, fxRate: a.fxRate, fxBase: a.fxBase, targetBase: base);
            switch (a.kind) {
              case ActivityKind.buy:
                bought += v;
                break;
              case ActivityKind.sell:
                sold += v;
                break;
              case ActivityKind.dividend:
                dividends += v;
                break;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: ScreenTitle(t.navTransactions),
              ),
              // Filters stay put while the list scrolls underneath.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _FilterChip(label: _dateLabel(t), active: _date != _DatePreset.all, onTap: _pickDate),
                    _FilterChip(label: _kindsLabel(t), active: _kinds.isNotEmpty, onTap: _pickKinds),
                    _FilterChip(label: _accountsLabel(t), active: _accounts.isNotEmpty, onTap: _pickAccounts),
                    _FilterChip(label: _classesLabel(t), active: _classes.isNotEmpty, onTap: _pickClasses),
                    if (_anyActive)
                      TextButton(
                        onPressed: _clearAll,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36)),
                        child: Text(t.filterClear),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                  children: [
                    if (items.isNotEmpty) ...[
                      Text(t.filterTransactions(items.length.toString()), style: TextStyle(fontSize: 12, color: c.textTertiary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _MiniStat(label: t.summaryBought, text: CurrencyText.formatAmount(bought, base))),
                          Expanded(child: _MiniStat(label: t.summarySold, text: CurrencyText.formatAmount(sold, base))),
                          Expanded(
                            child: _MiniStat(label: t.dividendIncome, text: CurrencyText.formatAmount(dividends, base), color: dividends > 0 ? c.gain : null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const HairlineDivider(),
                    ],
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            everything.isEmpty ? t.transactionsEmpty : t.filterNoMatch,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ),
                      ),
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const HairlineDivider(),
                      ActivityTile(
                        activity: items[i],
                        accountName: accountNames[items[i].accountId] ?? '',
                        onTap: () => editActivity(context, items[i]),
                        onLongPress: () => deleteActivity(context, items[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.accentText : c.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: active ? c.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? c.accent.withOpacity(0.5) : c.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 16, color: fg),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String text;
  final Color? color;
  const _MiniStat({required this.label, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500, color: color)),
        ),
      ],
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _SheetShell({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary))),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c.textPrimary))),
            if (selected) Icon(Icons.check, size: 18, color: c.accentText),
          ],
        ),
      ),
    );
  }
}
