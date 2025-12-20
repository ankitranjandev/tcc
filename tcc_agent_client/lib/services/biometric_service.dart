import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isInitialized = false;

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const int _authValidityMinutes = 5;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint('Biometric service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing biometric service: $e');
    }
  }

  // Check if device supports biometrics

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking device support: $e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<String> getBiometricsDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric Authentication';
    } else {
      return 'Biometric Authentication';
    }
  }

  // Authentication

  Future<bool> authenticate({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        debugPrint('Device does not support biometrics');
        return false;
      }

      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        debugPrint('Biometrics not available on this device');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason ?? 'Authenticate to continue',
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      if (authenticated) {
        await _saveLastAuthTime();
        debugPrint('Biometric authentication successful');
      } else {
        debugPrint('Biometric authentication failed');
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  Future<bool> authenticateForTransaction({
    required double amount,
    String? transactionType,
  }) async {
    final type = transactionType ?? 'transaction';
    return await authenticate(
      localizedReason: 'Authenticate to confirm $type of TCC${amount.toStringAsFixed(2)}',
      biometricOnly: false,
    );
  }

  Future<bool> authenticateForLogin() async {
    return await authenticate(
      localizedReason: 'Authenticate to login to TCC Agent',
      biometricOnly: false,
    );
  }

  Future<bool> authenticateForSettings() async {
    return await authenticate(
      localizedReason: 'Authenticate to access sensitive settings',
      biometricOnly: false,
    );
  }

  // Settings management

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking biometric enabled status: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);

      debugPrint('Biometric authentication ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('Error setting biometric enabled status: $e');
    }
  }

  Future<void> enableBiometric() async {
    // First authenticate to enable
    final authenticated = await authenticate(
      localizedReason: 'Authenticate to enable biometric login',
    );

    if (authenticated) {
      await setBiometricEnabled(true);
    }
  }

  Future<void> disableBiometric() async {
    await setBiometricEnabled(false);
  }

  // Session management

  Future<void> _saveLastAuthTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastAuthTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving last auth time: $e');
    }
  }

  Future<bool> isAuthenticationRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuthTime = prefs.getInt(_lastAuthTimeKey);

      if (lastAuthTime == null) return false;

      final lastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
      final difference = DateTime.now().difference(lastAuth);

      return difference.inMinutes < _authValidityMinutes;
    } catch (e) {
      debugPrint('Error checking auth recency: $e');
      return false;
    }
  }

  Future<void> clearAuthenticationSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastAuthTimeKey);
      debugPrint('Authentication session cleared');
    } catch (e) {
      debugPrint('Error clearing authentication session: $e');
    }
  }

  // Quick authentication helper

  Future<bool> quickAuth({String? reason}) async {
    // Check if biometric is enabled
    final enabled = await isBiometricEnabled();
    if (!enabled) return true; // If not enabled, allow access

    // Check if recently authenticated
    final isRecent = await isAuthenticationRecent();
    if (isRecent) return true;

    // Authenticate
    return await authenticate(localizedReason: reason);
  }

  // Stop biometric authentication (useful for canceling ongoing auth)

  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
      debugPrint('Biometric authentication stopped');
    } catch (e) {
      debugPrint('Error stopping authentication: $e');
    }
  }
}

