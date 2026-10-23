import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../services/lock_service.dart';
import 'launch_screen.dart';

/// Sits above the whole Navigator (via MaterialApp.builder) so that it covers
/// every screen, including ones pushed on top, such as the entry form.
///
/// - Cold start with the lock on: shows the icon and asks right away.
/// - Back from the background after [relockAfter] or more: locks again.
/// - If the phone no longer has any screen lock, it lets you in (there is
///   nothing to check against) rather than locking you out.
class AppLock extends StatefulWidget {
  final Widget child;
  const AppLock({super.key, required this.child});

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  static const relockAfter = Duration(seconds: 30);

  late bool _locked = settings.lockEnabled;
  bool _authenticating = false;
  bool _failed = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!settings.lockEnabled || _authenticating) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _pausedAt;
      _pausedAt = null;
      if (!_locked && since != null && DateTime.now().difference(since) >= relockAfter) {
        setState(() {
          _locked = true;
          _failed = false;
        });
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    final reason = AppLocalizations.of(context)?.unlockReason ?? 'Unlock HuatLui';
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final supported = await LockService.isSupported();
    final ok = supported ? await LockService.authenticate(reason) : true;
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _locked = !ok;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked && settings.lockEnabled;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !locked,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: locked
                  ? LaunchScreen(key: const ValueKey('locked'), showUnlock: _failed, busy: _authenticating, onUnlock: _unlock)
                  : const SizedBox.shrink(key: ValueKey('open')),
            ),
          ),
        ),
      ],
    );
  }
}
