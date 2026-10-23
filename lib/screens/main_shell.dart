import 'package:flutter/material.dart';
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
    return Scaffold(
      // IndexedStack keeps each tab's state alive while you switch tabs.
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(onOpenInsights: () => setState(() => _index = 2)),
          const HoldingsScreen(),
          const InsightsScreen(),
          const TransactionsScreen(),
          const SettingsScreen(),
        ],
      ),
      // Add button on Overview, Holdings and Activity.
      floatingActionButton: (_index == 0 || _index == 1 || _index == 3)
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
  }
}
