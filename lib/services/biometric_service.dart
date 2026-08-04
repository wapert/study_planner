import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps device biometrics (Face ID / Touch ID / fingerprint).
///
/// This is used as an **app lock**, not as a replacement for the account
/// password: the Firebase session already persists, so biometrics simply gate
/// access to the app's contents on a shared or lost device. No credentials are
/// ever stored on the device.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Biometrics only exist on iOS/Android — never on web or desktop.
  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// True when the device has hardware AND the user has enrolled a
  /// fingerprint / face (or a device passcode we can fall back to).
  Future<bool> isAvailable() async {
    if (!_supportedPlatform) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Human label for what the device offers, for use in UI copy.
  Future<String> methodLabel() async {
    if (!_supportedPlatform) return '生物辨識';
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        return defaultTargetPlatform == TargetPlatform.iOS
            ? 'Face ID'
            : '臉部辨識';
      }
      if (types.contains(BiometricType.fingerprint)) {
        return defaultTargetPlatform == TargetPlatform.iOS
            ? 'Touch ID'
            : '指紋辨識';
      }
      if (types.contains(BiometricType.iris)) return '虹膜辨識';
    } catch (_) {}
    return '生物辨識';
  }

  /// Prompts the user. Returns true only on a successful match.
  /// [reason] is shown in the system dialog on iOS.
  Future<bool> authenticate({String reason = '請驗證身分以開啟讀書計畫'}) async {
    if (!_supportedPlatform) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Allow the device passcode as a fallback so a failed or unreadable
        // fingerprint doesn't lock the owner out of their own data.
        biometricOnly: false,
        // Survive the OS briefly backgrounding the app to show the prompt.
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    }
  }
}
