import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'biometric_saved_email';
  static const String _savedPasswordKey = 'biometric_saved_password';

  // ── Check if device supports biometrics ──────────────────────────────────
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // ── Check if biometrics are available/enrolled ────────────────────────────
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  // ── Get available biometric types ─────────────────────────────────────────
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Check if Face ID is available ─────────────────────────────────────────
  Future<bool> isFaceIdAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  // ── Check if Fingerprint is available ────────────────────────────────────
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  // ── Authenticate with biometrics ─────────────────────────────────────────
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to access Lumasdang',
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return BiometricResult.notSupported;

      final canCheck = await canCheckBiometrics();
      if (!canCheck) return BiometricResult.notEnrolled;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate
          ? BiometricResult.success
          : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) return BiometricResult.notSupported;
      if (e.code == auth_error.notEnrolled) return BiometricResult.notEnrolled;
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.error;
    } catch (_) {
      return BiometricResult.error;
    }
  }

  // ── SharedPreferences helpers (for biometric enabled flag) ────────────────
  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (!enabled) {
      await clearSavedCredentials();
    }
  }

  // ── Secure storage helpers using Flutter Secure Storage ──────────────────
  Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _savedEmailKey, value: email);
      await _secureStorage.write(key: _savedPasswordKey, value: password);
    } catch (e) {
      throw Exception('Failed to save credentials securely: $e');
    }
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: _savedEmailKey);
      final password = await _secureStorage.read(key: _savedPasswordKey);
      if (email == null || password == null) return null;
      return {'email': email, 'password': password};
    } catch (e) {
      throw Exception('Failed to retrieve saved credentials: $e');
    }
  }

  Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
    } catch (e) {
      throw Exception('Failed to clear saved credentials: $e');
    }
  }
}

enum BiometricResult {
  success,
  failed,
  notSupported,
  notEnrolled,
  lockedOut,
  error,
}