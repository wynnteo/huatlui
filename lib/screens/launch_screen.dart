import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// The app icon on a plain background. It matches the native splash screen
/// (same colour, same centred icon), so starting the app looks like one
/// continuous screen, and doubles as the lock screen.
class LaunchScreen extends StatelessWidget {
  final bool showUnlock; // true after a failed or cancelled attempt
  final bool busy;
  final VoidCallback onUnlock;
  const LaunchScreen({super.key, required this.showUnlock, required this.busy, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    return Material(
      color: c.surface,
      child: Stack(
        children: [
          Center(child: Image.asset('assets/icons/app_icon_tran.png', width: 120, height: 120)),
          if (showUnlock && !busy)
            Positioned(
              left: 32,
              right: 32,
              bottom: 56,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.lockedTitle, style: TextStyle(fontSize: 15, color: c.textSecondary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: onUnlock, child: Text(t.unlockButton)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
