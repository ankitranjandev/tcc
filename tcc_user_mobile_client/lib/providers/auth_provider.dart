import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

// Helper function to convert backend error codes to user-friendly messages
String _getUserFriendlyErrorMessage(String? error) {
  if (error == null) return 'An error occurred. Please try again.';

  // Handle common backend error codes
  switch (error.toUpperCase()) {
    case 'PHONE_ALREADY_EXISTS':
      return 'This phone number is already registered. Please use a different number or try logging in.';
    case 'EMAIL_ALREADY_EXISTS':
      return 'This email address is already registered. Please use a different email or try logging in.';
    case 'USER_NOT_FOUND':
      return 'No account found with these credentials.';
    case 'INVALID_CREDENTIALS':
      return 'Invalid email or password. Please try again.';
    case 'INVALID_OTP':
      return 'Invalid verification code. Please check and try again.';
    case 'OTP_EXPIRED':
      return 'Verification code has expired. Please request a new one.';
    case 'ACCOUNT_LOCKED':
      return 'Your account has been locked. Please contact support.';
    case 'ACCOUNT_DISABLED':
      return 'Your account has been disabled. Please contact support.';
    case 'INVALID_PHONE':
      return 'Please enter a valid phone number.';
    case 'INVALID_EMAIL':
      return 'Please enter a valid email address.';
    case 'WEAK_PASSWORD':
      return 'Password is too weak. Please use a stronger password.';
    default:
      // If the error is already a readable message (contains spaces), return as-is
      if (error.contains(' ')) {
        return error;
      }
      // Otherwise, return the error with a generic prefix
      return error.replaceAll('_', ' ').toLowerCase();
  }
}

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

  // Handle unauthorized errors - clear state and force re-login
  Future<void> handleUnauthorized() async {
    developer.log('🔴 AuthProvider: Handling unauthorized - forcing logout', name: 'AuthProvider');
    await _apiService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = 'Session expired. Please log in again.';
    notifyListeners();
  }

  // Initialize - check for existing tokens
  Future<void> initialize() async {
    developer.log('🔵 AuthProvider: Starting initialization', name: 'AuthProvider');
    await _apiService.initialize();
    developer.log('🔵 AuthProvider: ApiService initialized', name: 'AuthProvider');

    // If we have a token, try to get user profile
    if (_apiService.token != null) {
      developer.log('🔵 AuthProvider: Token found, loading user profile', name: 'AuthProvider');
      final success = await loadUserProfile();
      if (!success) {
        developer.log('🔵 AuthProvider: Profile load failed, clearing tokens', name: 'AuthProvider');
        // Token is invalid, clear it
        await _apiService.clearTokens();
        _isAuthenticated = false;
      }
    } else {
      developer.log('🔵 AuthProvider: No token found', name: 'AuthProvider');
      _isAuthenticated = false;
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
        final profileLoaded = await loadUserProfile();
        if (profileLoaded) {
          _isAuthenticated = true;
          _isLoading = false;
          developer.log('🟢 AuthProvider: Login complete. isAuthenticated: $_isAuthenticated', name: 'AuthProvider');

          // Send FCM token to backend for push notifications
          await NotificationService().sendTokenToBackendIfNeeded();
          developer.log('🟢 AuthProvider: FCM token registration triggered', name: 'AuthProvider');

          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Failed to load user profile';
          developer.log('🔴 AuthProvider: Login succeeded but profile load failed', name: 'AuthProvider');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(result['error']);
        developer.log('🔴 AuthProvider: Login failed: $_errorMessage', name: 'AuthProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyErrorMessage(e.toString());
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
          final profileLoaded = await loadUserProfile();
          if (profileLoaded) {
            _isAuthenticated = true;
          } else {
            developer.log('🟢 AuthProvider: Registration succeeded but profile load failed', name: 'AuthProvider');
          }
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(result['error']);
        developer.log('🔴 AuthProvider: Registration failed: $_errorMessage', name: 'AuthProvider');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyErrorMessage(e.toString());
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
        final profileLoaded = await loadUserProfile();
        if (profileLoaded) {
          _isAuthenticated = true;
          _isLoading = false;
          developer.log('🟡 AuthProvider: OTP verification complete. isAuthenticated: $_isAuthenticated', name: 'AuthProvider');

          // Send FCM token to backend for push notifications
          await NotificationService().sendTokenToBackendIfNeeded();
          developer.log('🟡 AuthProvider: FCM token registration triggered', name: 'AuthProvider');

          notifyListeners();
          return true;
        } else {
          // Profile load failed but OTP was verified - still consider success
          // The user might need to complete registration
          _isLoading = false;
          developer.log('🟡 AuthProvider: OTP verified but profile load failed', name: 'AuthProvider');
          notifyListeners();
          return true;
        }
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(result['error']);
        developer.log('🔴 AuthProvider: OTP verification failed: $_errorMessage', name: 'AuthProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyErrorMessage(e.toString());
      developer.log('🔴 AuthProvider: OTP verification exception: $e', name: 'AuthProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load user profile
  Future<bool> loadUserProfile() async {
    developer.log('🟡 AuthProvider: Loading user profile', name: 'AuthProvider');
    try {
      final result = await _authService.getProfile();
      developer.log('🟡 AuthProvider: Profile result success: ${result['success']}', name: 'AuthProvider');
      developer.log('🟡 AuthProvider: Full profile result: $result', name: 'AuthProvider');

      if (result['success'] == true && result['data'] != null) {
        // The API response structure is: { success: true, data: { user: {...}, wallet: {...} } }
        // But auth_service wraps it again, so result['data'] contains the full API response
        final apiResponse = result['data'];
        developer.log('🟡 AuthProvider: API response: $apiResponse', name: 'AuthProvider');
        developer.log('🟡 AuthProvider: API response keys: ${apiResponse?.keys?.toList()}', name: 'AuthProvider');

        final userData = apiResponse['data']?['user'];
        final walletData = apiResponse['data']?['wallet'];
        developer.log('🟡 AuthProvider: User data extracted: $userData', name: 'AuthProvider');
        developer.log('🟡 AuthProvider: User data keys: ${userData?.keys?.toList()}', name: 'AuthProvider');
        developer.log('🟡 AuthProvider: Wallet data extracted: $walletData', name: 'AuthProvider');

        // Log specific profile picture fields
        if (userData != null) {
          developer.log('🟡 AuthProvider: profile_picture_url in response: ${userData['profile_picture_url']}', name: 'AuthProvider');
          developer.log('🟡 AuthProvider: profilePicture in response: ${userData['profilePicture']}', name: 'AuthProvider');
          developer.log('🟡 AuthProvider: profile_picture in response: ${userData['profile_picture']}', name: 'AuthProvider');
        }

        if (userData != null) {
          // Merge wallet balance from wallet object into user data for UserModel
          final mergedUserData = Map<String, dynamic>.from(userData);
          if (walletData != null && walletData['balance'] != null) {
            mergedUserData['walletBalance'] = walletData['balance'];
            developer.log('🟡 AuthProvider: Merged wallet balance: ${walletData['balance']}', name: 'AuthProvider');
          }
          _user = UserModel.fromJson(mergedUserData);
          _isAuthenticated = true;
          developer.log('🟡 AuthProvider: User profile loaded successfully. User: ${_user?.email}', name: 'AuthProvider');
          developer.log('🟡 AuthProvider: Parsed profilePicture: ${_user?.profilePicture}', name: 'AuthProvider');
          notifyListeners();
          return true;
        }
      } else {
        developer.log('🔴 AuthProvider: Failed to load profile: ${result['error']}', name: 'AuthProvider');
        // Check if error indicates unauthorized - force logout
        final error = result['error']?.toString().toLowerCase() ?? '';
        if (error.contains('unauthorized') || error.contains('no token') || error.contains('token')) {
          await handleUnauthorized();
        }
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 AuthProvider: Profile loading exception: $e', name: 'AuthProvider');
      // Check if this is an unauthorized exception
      if (e.toString().toLowerCase().contains('unauthorized') ||
          e.toString().toLowerCase().contains('no token')) {
        await handleUnauthorized();
      }
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Remove FCM token from backend before logout
      await NotificationService().removeTokenFromBackend();
      developer.log('🔴 AuthProvider: FCM token removed from backend', name: 'AuthProvider');
    } catch (e) {
      developer.log('🔴 AuthProvider: Error removing FCM token: $e', name: 'AuthProvider');
      // Continue with logout even if FCM token removal fails
    }

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

  // Resend OTP
  Future<bool> resendOTP({
    required String phone,
    required String countryCode,
  }) async {
    developer.log('🟡 AuthProvider: Resend OTP requested for phone: $phone', name: 'AuthProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.resendOTP(
        phone: phone,
        countryCode: countryCode,
      );

      developer.log('🟡 AuthProvider: Resend OTP result: ${result['success']}', name: 'AuthProvider');

      _isLoading = false;
      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(result['error']);
        developer.log('🔴 AuthProvider: Resend OTP failed: $_errorMessage', name: 'AuthProvider');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyErrorMessage(e.toString());
      developer.log('🔴 AuthProvider: Resend OTP exception: $e', name: 'AuthProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update profile picture
  Future<bool> updateProfilePicture(String filePath) async {
    developer.log('🟢 AuthProvider: Updating profile picture', name: 'AuthProvider');
    developer.log('🟢 AuthProvider: File path: $filePath', name: 'AuthProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.uploadProfilePicture(filePath: filePath);
      developer.log('🟢 AuthProvider: Upload result: $result', name: 'AuthProvider');

      if (result['success'] == true) {
        developer.log('🟢 AuthProvider: Profile picture uploaded successfully', name: 'AuthProvider');
        developer.log('🟢 AuthProvider: Upload response data: ${result['data']}', name: 'AuthProvider');

        // Reload user profile to get the updated picture URL
        developer.log('🟢 AuthProvider: Reloading user profile to get updated picture URL...', name: 'AuthProvider');
        final profileLoaded = await loadUserProfile();
        _isLoading = false;

        if (profileLoaded) {
          developer.log('🟢 AuthProvider: Profile reloaded successfully', name: 'AuthProvider');
          developer.log('🟢 AuthProvider: Updated user profilePicture: ${_user?.profilePicture}', name: 'AuthProvider');
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Profile picture uploaded but failed to reload profile';
          developer.log('🔴 AuthProvider: Profile picture uploaded but profile reload failed', name: 'AuthProvider');
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = result['error'] ?? 'Failed to update profile picture';
        developer.log('🔴 AuthProvider: Profile picture update failed: $_errorMessage', name: 'AuthProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      developer.log('🔴 AuthProvider: Profile picture update exception: $e', name: 'AuthProvider');
      developer.log('🔴 AuthProvider: Stack trace: $stackTrace', name: 'AuthProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
