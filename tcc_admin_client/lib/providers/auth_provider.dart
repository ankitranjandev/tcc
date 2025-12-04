import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../services/auth_service.dart';

/// Authentication Provider
/// Manages authentication state and user session
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AdminModel? _admin;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  AdminModel? get admin => _admin;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  bool get isSuperAdmin => _admin?.role == AdminRole.superAdmin;

  /// Initialize auth state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _admin = await _authService.getStoredAdmin();
        _isAuthenticated = _admin != null;

        // Optionally refresh profile from server
        if (_isAuthenticated) {
          await refreshProfile();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (response.success && response.data != null) {
        _admin = response.data;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify 2FA
  Future<bool> verify2FA(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verify2FA(code: code);

      if (response.success && response.data != null) {
        _admin = response.data;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? '2FA verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('2FA verification error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _admin = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.forgotPassword(email: email);

      if (response.success) {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Failed to send reset email';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Forgot password error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      if (response.success) {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Failed to reset password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh profile from server
  Future<void> refreshProfile() async {
    try {
      final response = await _authService.getProfile();
      if (response.success && response.data != null) {
        _admin = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  /// Check if admin has permission
  bool hasPermission(String permission) {
    return _admin?.hasPermission(permission) ?? false;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
