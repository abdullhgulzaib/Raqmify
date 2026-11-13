import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool success;
  final String? message;
  final bool fallbackToPin;

  const BiometricAuthResult({
    required this.success,
    this.message,
    this.fallbackToPin = false,
  });
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticates using biometrics with device credential (PIN/Pattern/Password) fallback (U4).
  /// Gracefully handles 'not enrolled', 'not available', and falls back to app PIN.
  Future<BiometricAuthResult> authenticateDetailed({
    String reason = 'Please authenticate to unlock Raqmify',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) {
        return const BiometricAuthResult(
          success: false,
          message: 'Biometric hardware is not available on this device.',
          fallbackToPin: true,
        );
      }

      final available = await getAvailableBiometrics();
      if (available.isEmpty) {
        return const BiometricAuthResult(
          success: false,
          message: 'No biometrics enrolled. Using app PIN instead.',
          fallbackToPin: true,
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // Allow device credential fallback (U4)
        persistAcrossBackgrounding: true,
      );

      return BiometricAuthResult(
        success: authenticated,
        message: authenticated ? null : 'Authentication was cancelled.',
        fallbackToPin: !authenticated,
      );
    } on PlatformException catch (e) {
      String message = 'Authentication failed';
      final code = e.code.toLowerCase();
      if (code.contains('notenrolled')) {
        message = 'No biometrics enrolled on device. Please use your PIN.';
      } else if (code.contains('lockedout')) {
        message = 'Biometrics locked out due to attempts. Please use your PIN.';
      } else if (code.contains('notavailable')) {
        message = 'Biometrics currently unavailable. Please use your PIN.';
      }

      return BiometricAuthResult(
        success: false,
        message: message,
        fallbackToPin: true,
      );
    } catch (e) {
      return const BiometricAuthResult(
        success: false,
        message: 'Authentication error occurred.',
        fallbackToPin: true,
      );
    }
  }

  Future<bool> authenticate({
    String reason = 'Please scan your fingerprint to unlock Raqmify',
  }) async {
    final res = await authenticateDetailed(reason: reason);
    return res.success;
  }
}
