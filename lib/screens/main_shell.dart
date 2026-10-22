import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'allocation_screen.dart';
import 'dashboard_screen.dart';
import 'entry_form_screen.dart';
import 'holdings_screen.dart';
import 'more_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // IndexedStack keeps each tab's state (e.g. the Allocation grouping) alive
  // while you switch between tabs.
  static const _screens = <Widget>[
    DashboardScreen(),
    HoldingsScreen(),
    AllocationScreen(),
    TransactionsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      // Add button on Dashboard, Holdings and Transactions.
      floatingActionButton: (_index == 0 || _index == 1 || _index == 3)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen())),
              icon: const Icon(Icons.add),
              label: Text(t.addEntry),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard), label: t.navDashboard),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: t.navHoldings),
          NavigationDestination(icon: const Icon(Icons.donut_large_outlined), selectedIcon: const Icon(Icons.donut_large), label: t.navAllocation),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: t.navTransactions),
          NavigationDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more_horiz), label: t.navMore),
        ],
      ),
    );
  }
}
