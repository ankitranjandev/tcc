import 'package:flutter/material.dart';
import 'dart:developer' as developer;
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
    developer.log('🔵 AuthProvider: Starting initialization', name: 'AuthProvider');
    await _apiService.initialize();
    developer.log('🔵 AuthProvider: ApiService initialized', name: 'AuthProvider');

    // If we have a token, try to get user profile
    if (_apiService.token != null) {
      developer.log('🔵 AuthProvider: Token found, loading user profile', name: 'AuthProvider');
      await loadUserProfile();
    } else {
      developer.log('🔵 AuthProvider: No token found', name: 'AuthProvider');
    }
    developer.log('🔵 AuthProvider: Initialization complete. isAuthenticated: $_isAuthenticated', name: 'AuthProvider');
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    developer.log('🟢 AuthProvider: Login started for email: $email', name: 'AuthProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      developer.log('🟢 AuthProvider: Calling authService.login()', name: 'AuthProvider');
      final result = await _authService.login(
        email: email,
        password: password,
      );

      developer.log('🟢 AuthProvider: Login result received: ${result['success']}', name: 'AuthProvider');

      if (result['success'] == true) {
        developer.log('🟢 AuthProvider: Login successful, loading user profile', name: 'AuthProvider');
        // Load user profile after successful login
        await loadUserProfile();
        _isAuthenticated = true;
        _isLoading = false;
        developer.log('🟢 AuthProvider: Login complete. isAuthenticated: $_isAuthenticated', name: 'AuthProvider');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Login failed';
        developer.log('🔴 AuthProvider: Login failed: $_errorMessage', name: 'AuthProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 AuthProvider: Login exception: $e', name: 'AuthProvider');
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
    String? otp,
  }) async {
    developer.log('🟢 AuthProvider: Register started for email: $email', name: 'AuthProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      developer.log('🟢 AuthProvider: Calling authService.register() with OTP: ${otp != null}', name: 'AuthProvider');
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        countryCode: countryCode,
        password: password,
        referralCode: referralCode,
        otp: otp,
      );

      _isLoading = false;

      developer.log('🟢 AuthProvider: Register result received: ${result['success']}', name: 'AuthProvider');

      if (result['success'] == true) {
        developer.log('🟢 AuthProvider: Registration successful', name: 'AuthProvider');

        // If OTP was provided and registration was successful, load user profile
        if (otp != null) {
          developer.log('🟢 AuthProvider: Registration with OTP successful, loading user profile', name: 'AuthProvider');
          await loadUserProfile();
          _isAuthenticated = true;
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Registration failed';
        developer.log('🔴 AuthProvider: Registration failed: $_errorMessage', name: 'AuthProvider');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      developer.log('🔴 AuthProvider: Registration exception: $e', name: 'AuthProvider');
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
    developer.log('🟡 AuthProvider: OTP verification started for phone: $phone, purpose: $purpose', name: 'AuthProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      developer.log('🟡 AuthProvider: Calling authService.verifyOTP()', name: 'AuthProvider');
      final result = await _authService.verifyOTP(
        phone: phone,
        countryCode: countryCode,
        otp: otp,
        purpose: purpose,
      );

      developer.log('🟡 AuthProvider: OTP verification result: ${result['success']}', name: 'AuthProvider');

      if (result['success'] == true) {
        developer.log('🟡 AuthProvider: OTP verified successfully, loading user profile', name: 'AuthProvider');
        // Load user profile after successful verification
        await loadUserProfile();
        _isAuthenticated = true;
        _isLoading = false;
        developer.log('🟡 AuthProvider: OTP verification complete. isAuthenticated: $_isAuthenticated', name: 'AuthProvider');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'OTP verification failed';
        developer.log('🔴 AuthProvider: OTP verification failed: $_errorMessage', name: 'AuthProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 AuthProvider: OTP verification exception: $e', name: 'AuthProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    developer.log('🟡 AuthProvider: Loading user profile', name: 'AuthProvider');
    try {
      final result = await _authService.getProfile();
      developer.log('🟡 AuthProvider: Profile result: ${result['success']}', name: 'AuthProvider');

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data']['user'];
        developer.log('🟡 AuthProvider: User data received: ${userData != null}', name: 'AuthProvider');
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
          developer.log('🟡 AuthProvider: User profile loaded successfully. User: ${_user?.email}', name: 'AuthProvider');
        }
      } else {
        developer.log('🔴 AuthProvider: Failed to load profile: ${result['error']}', name: 'AuthProvider');
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 AuthProvider: Profile loading exception: $e', name: 'AuthProvider');
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
