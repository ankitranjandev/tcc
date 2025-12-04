import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

/// Storage Service
/// Handles secure and non-secure local storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  // Secure storage for sensitive data (tokens)
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Shared preferences for non-sensitive data
  SharedPreferences? _prefs;

  /// Initialize storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== Secure Storage (Tokens) ====================

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAccessToken, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.keyAccessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.keyRefreshToken);
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }

  // ==================== Shared Preferences (User Data) ====================

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await _preferences;
    await prefs.setString(
      AppConstants.keyUserData,
      jsonEncode(userData),
    );
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _preferences;
    final userData = prefs.getString(AppConstants.keyUserData);
    if (userData != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.keyUserData);
  }

  /// Save remember me
  Future<void> saveRememberMe(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.keyRememberMe, value);
  }

  /// Get remember me
  Future<bool> getRememberMe() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.keyRememberMe) ?? false;
  }

  // ==================== Generic Methods ====================

  /// Save string
  Future<void> saveString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }

  /// Get string
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Save int
  Future<void> saveInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }

  /// Get int
  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  /// Save bool
  Future<void> saveBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }

  /// Get bool
  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  /// Save double
  Future<void> saveDouble(String key, double value) async {
    final prefs = await _preferences;
    await prefs.setDouble(key, value);
  }

  /// Get double
  Future<double?> getDouble(String key) async {
    final prefs = await _preferences;
    return prefs.getDouble(key);
  }

  /// Save list of strings
  Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await _preferences;
    await prefs.setStringList(key, value);
  }

  /// Get list of strings
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _preferences;
    return prefs.getStringList(key);
  }

  /// Remove key
  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _preferences;
    return prefs.containsKey(key);
  }

  /// Clear all data (logout)
  Future<void> clearAll() async {
    // Clear secure storage
    await _secureStorage.deleteAll();

    // Clear shared preferences
    final prefs = await _preferences;
    await prefs.clear();
  }

  // ==================== Helper Methods ====================

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    final prefs = await _preferences;
    return prefs.getKeys();
  }
}
