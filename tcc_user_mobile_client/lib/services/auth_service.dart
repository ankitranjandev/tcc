import 'dart:developer' as developer;
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register new user
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
    String? referralCode,
  }) async {
    try {
      developer.log('📤 AuthService: Registration request for email: $email', name: 'AuthService');

      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'country_code': countryCode,
        'password': password,
      };

      if (referralCode != null && referralCode.isNotEmpty) {
        body['referral_code'] = referralCode;
      }

      developer.log('📤 AuthService: Sending registration data', name: 'AuthService');

      final response = await _apiService.post(
        '/auth/register',
        body: body,
        requiresAuth: false,
      );

      developer.log('✅ AuthService: Registration successful', name: 'AuthService');
      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: Registration error: $e', name: 'AuthService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify OTP after registration
  Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String countryCode,
    required String otp,
    required String purpose, // REGISTRATION, LOGIN, PHONE_CHANGE, PASSWORD_RESET
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/verify-otp',
        body: {
          'phone': phone,
          'country_code': countryCode,
          'otp': otp,
          'purpose': purpose,
        },
        requiresAuth: false,
      );

      // Store tokens if verification successful
      if (response['token'] != null && response['refreshToken'] != null) {
        await _apiService.setTokens(
          response['token'],
          response['refreshToken'],
        );
      }

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Login user with email
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    developer.log('📤 AuthService: Login request for email: $email', name: 'AuthService');
    try {
      developer.log('📤 AuthService: Sending POST request to /auth/login', name: 'AuthService');
      final response = await _apiService.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      developer.log('📥 AuthService: Login response received: $response', name: 'AuthService');

      // Store tokens if login successful
      if (response['token'] != null && response['refreshToken'] != null) {
        developer.log('📥 AuthService: Tokens found in response, storing them', name: 'AuthService');
        await _apiService.setTokens(
          response['token'],
          response['refreshToken'],
        );
        developer.log('✅ AuthService: Tokens stored successfully', name: 'AuthService');
      } else {
        developer.log('⚠️ AuthService: No tokens in response', name: 'AuthService');
      }

      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: Login error: $e', name: 'AuthService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP({
    required String phone,
    required String countryCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/resend-otp',
        body: {
          'phone': phone,
          'country_code': countryCode,
        },
        requiresAuth: false,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Forgot password - request OTP via email
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/forgot-password',
        body: {
          'email': email,
        },
        requiresAuth: false,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String countryCode,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/reset-password',
        body: {
          'phone': phone,
          'country_code': countryCode,
          'otp': otp,
          'new_password': newPassword,
        },
        requiresAuth: false,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = _apiService.refreshToken;
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiService.post(
        '/auth/refresh',
        body: {
          'refreshToken': refreshToken,
        },
        requiresAuth: false,
      );

      // Store new tokens
      if (response['token'] != null && response['refreshToken'] != null) {
        await _apiService.setTokens(
          response['token'],
          response['refreshToken'],
        );
      }

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _apiService.post(
        '/auth/logout',
        requiresAuth: true,
      );

      // Clear tokens
      await _apiService.clearTokens();

      return {'success': true, 'data': response};
    } catch (e) {
      // Even if API call fails, clear local tokens
      await _apiService.clearTokens();
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    developer.log('📤 AuthService: Fetching user profile', name: 'AuthService');
    try {
      final response = await _apiService.get(
        '/users/profile',
        requiresAuth: true,
      );
      developer.log('📥 AuthService: Profile response: $response', name: 'AuthService');
      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: Get profile error: $e', name: 'AuthService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? address,
    String? dateOfBirth,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (address != null) body['address'] = address;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;

      final response = await _apiService.patch(
        '/users/profile',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/users/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
