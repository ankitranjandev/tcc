import 'dart:developer' as developer;
import 'api_service.dart';

// Helper function to extract error message from exceptions
String _extractErrorMessage(dynamic error) {
  if (error is ApiException) {
    return error.message;
  } else if (error is ValidationException) {
    return error.message;
  } else if (error is UnauthorizedException) {
    return error.message;
  }
  return error.toString();
}

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
    String? otp,
  }) async {
    try {
      developer.log('📤 AuthService: Registration request for email: $email, with OTP: ${otp != null}', name: 'AuthService');

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

      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }

      developer.log('📤 AuthService: Sending registration data', name: 'AuthService');

      final response = await _apiService.post(
        '/auth/register',
        body: body,
        requiresAuth: false,
      );

      // Store tokens if registration with OTP is successful
      // Backend returns response wrapped in 'data' field
      if (otp != null && response['data'] != null) {
        final data = response['data'];
        if (data['access_token'] != null && data['refresh_token'] != null) {
          developer.log('✅ AuthService: Registration with OTP successful, storing tokens', name: 'AuthService');
          await _apiService.setTokens(
            data['access_token'],
            data['refresh_token'],
          );
        }
      }

      developer.log('✅ AuthService: Registration successful', name: 'AuthService');
      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: Registration error: $e', name: 'AuthService');
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      developer.log('📤 AuthService: OTP verification request for phone: $phone', name: 'AuthService');
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
      // Backend returns response wrapped in 'data' field
      if (response['data'] != null) {
        final data = response['data'];
        if (data['access_token'] != null && data['refresh_token'] != null) {
          developer.log('✅ AuthService: OTP verified, storing tokens', name: 'AuthService');
          await _apiService.setTokens(
            data['access_token'],
            data['refresh_token'],
          );
        } else {
          developer.log('⚠️ AuthService: No tokens in OTP verification response data', name: 'AuthService');
        }
      } else {
        developer.log('⚠️ AuthService: No data field in OTP verification response', name: 'AuthService');
      }

      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: OTP verification error: $e', name: 'AuthService');
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      // Backend returns response wrapped in 'data' field
      if (response['data'] != null) {
        final data = response['data'];
        if (data['access_token'] != null && data['refresh_token'] != null) {
          developer.log('📥 AuthService: Tokens found in response, storing them', name: 'AuthService');
          await _apiService.setTokens(
            data['access_token'],
            data['refresh_token'],
          );
          developer.log('✅ AuthService: Tokens stored successfully', name: 'AuthService');
        } else {
          developer.log('⚠️ AuthService: No tokens in login response data', name: 'AuthService');
        }
      } else {
        developer.log('⚠️ AuthService: No data field in login response', name: 'AuthService');
      }

      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('❌ AuthService: Login error: $e', name: 'AuthService');
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
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
      return {'success': false, 'error': _extractErrorMessage(e)};
    }
  }
}
