import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../services/activity.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ui_helpers.dart';
import 'dashboard_screen.dart';
import 'entry_form_screen.dart';
import 'holdings_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final issue = firstOversellIssue(repo.trades);
        final needsRepair = issue != null;
        return Scaffold(
      // IndexedStack keeps each tab's state alive while you switch tabs.
      body: IndexedStack(
        index: _index,
        children: [
          if (needsRepair)
            _PortfolioRepairNotice(issue: issue, onOpenActivity: () => setState(() => _index = 3))
          else
            DashboardScreen(onOpenInsights: () => setState(() => _index = 2)),
          if (needsRepair)
            _PortfolioRepairNotice(issue: issue, onOpenActivity: () => setState(() => _index = 3))
          else
            const HoldingsScreen(),
          if (needsRepair)
            _PortfolioRepairNotice(issue: issue, onOpenActivity: () => setState(() => _index = 3))
          else
            const InsightsScreen(),
          const TransactionsScreen(),
          const SettingsScreen(),
        ],
      ),
      // Add button on Overview, Holdings and Activity.
      floatingActionButton: (_index == 3 || (!needsRepair && (_index == 0 || _index == 1)))
          ? FloatingActionButton(
              tooltip: t.addEntry,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen())),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HairlineDivider(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard), label: t.navDashboard),
              NavigationDestination(icon: const Icon(Icons.layers_outlined), selectedIcon: const Icon(Icons.layers), label: t.navHoldings),
              NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: t.navInsights),
              NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: t.navTransactions),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t.navSettings),
            ],
          ),
        ],
      ),
        );
      },
    );
  }
}

class _PortfolioRepairNotice extends StatelessWidget {
  final OversellIssue? issue;
  final VoidCallback onOpenActivity;

  const _PortfolioRepairNotice({required this.issue, required this.onOpenActivity});

  @override
  Widget build(BuildContext context) {
    final problem = issue!;
    final trade = problem.trade;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final date = '${trade.tradeDate.year}-${trade.tradeDate.month.toString().padLeft(2, '0')}-${trade.tradeDate.day.toString().padLeft(2, '0')}';
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 42),
              const SizedBox(height: 16),
              Text(
                zh ? '交易记录需要检查' : 'Transaction needs review',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(zh
                  ? '系统发现一笔卖出数量超过当时可用持仓。为避免显示错误的投资回报，相关计算暂时停用。你的记录没有被更改。'
                  : 'A sell transaction exceeds the shares available at that date. Portfolio calculations are temporarily paused to prevent misleading values. Your saved records have not been changed.'),
              const SizedBox(height: 16),
              Text('${trade.symbol} · $date'),
              const SizedBox(height: 6),
              Text(zh
                  ? '卖出：${trade.quantity}，当时可用：${problem.available}'
                  : 'Sold: ${trade.quantity} · Available then: ${problem.available}'),
              const SizedBox(height: 6),
              SelectableText(zh
                  ? '交易 ID：${trade.id}'
                  : 'Transaction ID: ${trade.id}'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onOpenActivity,
                icon: const Icon(Icons.receipt_long),
                label: Text(zh ? '前往交易记录修正' : 'Review transactions'),
              ),
              const SizedBox(height: 8),
              Text(zh
                  ? '你也可以前往设置导出备份，修正之前请先保存。'
                  : 'You can also export a backup in Settings before making changes.'),
            ],
          ),
        ),
      ),
    );
  }
}
