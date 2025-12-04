import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize - check for existing tokens
  Future<void> initialize() async {
    await _apiService.initialize();

    // If we have a token, try to get user profile
    if (_apiService.token != null) {
      await loadUserProfile();
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        // Load user profile after successful login
        await loadUserProfile();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        countryCode: countryCode,
        password: password,
        referralCode: referralCode,
      );

      _isLoading = false;

      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String phone,
    required String countryCode,
    required String otp,
    required String purpose,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(
        phone: phone,
        countryCode: countryCode,
        otp: otp,
        purpose: purpose,
      );

      if (result['success'] == true) {
        // Load user profile after successful verification
        await loadUserProfile();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'OTP verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    try {
      final result = await _authService.getProfile();

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data']['user'];
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors, clear local state anyway
    }

    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
