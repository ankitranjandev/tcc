import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/admin_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Admin Provider
/// Manages the admin user state and authentication
class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AdminModel? _admin;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Getters
  AdminModel? get admin => _admin;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get adminName => _admin?.name;
  String? get adminEmail => _admin?.email;
  String? get adminRole => _admin?.role.displayName;

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        await loadAdminProfile();
      }
    } catch (e) {
      developer.log('Error initializing admin provider: $e', name: 'AdminProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load admin profile
  Future<void> loadAdminProfile() async {
    try {
      final response = await _apiService.get(
        '/admin/profile',
        fromJson: (data) => AdminModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        _admin = response.data;
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error loading admin profile: $e', name: 'AdminProvider');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Login admin
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _admin = response.data;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error during login: $e', name: 'AdminProvider');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout admin
  Future<void> logout() async {
    await _storageService.clearAll();
    _admin = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Update admin profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final response = await _apiService.put(
        '/admin/profile',
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (phone != null) 'phone': phone,
        },
        fromJson: (data) => AdminModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        _admin = response.data;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error updating profile: $e', name: 'AdminProvider');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/admin/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response.success;
    } catch (e) {
      developer.log('Error changing password: $e', name: 'AdminProvider');
      return false;
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) async {
    try {
      final response = await _apiService.put(
        '/admin/notification-settings',
        data: {
          if (emailNotifications != null) 'email_notifications': emailNotifications,
          if (pushNotifications != null) 'push_notifications': pushNotifications,
          if (smsNotifications != null) 'sms_notifications': smsNotifications,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success) {
        // Update local admin model if needed
        await loadAdminProfile();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error updating notification settings: $e', name: 'AdminProvider');
      return false;
    }
  }

  /// Check if admin has specific permission
  bool hasPermission(String permission) {
    if (_admin == null) return false;
    return _admin!.permissions.contains(permission);
  }

  /// Clear provider data
  void clear() {
    _admin = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}