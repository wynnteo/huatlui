import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over local_auth. It uses the phone's own lock (fingerprint,
/// face, or the screen PIN / pattern as a fallback), so there is no separate
/// HuatLui PIN to remember or store.
class LockService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True if this phone has any way to verify the owner.
  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
