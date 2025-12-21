import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  BiometricAuth._();

  static final LocalAuthentication _auth = LocalAuthentication();
  static String? _lastError;

  static String? get lastError => _lastError;

  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    _lastError = null;
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      _lastError = e.message ?? e.code;
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  static Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
