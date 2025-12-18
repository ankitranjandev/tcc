import '../models/admin_model.dart';
import '../models/api_response_model.dart';
import '../config/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'mock_data_service.dart';

/// Authentication Service
/// Handles all authentication-related API calls
class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final MockDataService _mockDataService = MockDataService();

  /// Login admin
  Future<ApiResponse<AdminModel>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Use mock data if enabled
    if (AppConstants.useMockData) {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get mock admin data
      final admin = _mockDataService.currentAdmin;

      // Generate mock tokens
      final mockTokens = {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      };

      // Save tokens
      await _storageService.saveAccessToken(mockTokens['access_token']!);
      await _storageService.saveRefreshToken(mockTokens['refresh_token']!);

      // Save user data
      await _storageService.saveUserData(admin.toJson());

      // Save remember me preference
      await _storageService.saveRememberMe(rememberMe);

      // Return success response
      return ApiResponse.success(
        data: admin,
        message: 'Login successful',
      );
    }

    // Real API call
    final response = await _apiService.post(
      '/admin/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      // Extract admin data and tokens from response.data
      final responseData = response.data as Map<String, dynamic>;

      // Save tokens
      if (responseData['access_token'] != null) {
        await _storageService.saveAccessToken(responseData['access_token']);
      }
      if (responseData['refresh_token'] != null) {
        await _storageService.saveRefreshToken(responseData['refresh_token']);
      }

      // Save admin user data
      if (responseData['admin'] != null) {
        final admin = AdminModel.fromJson(responseData['admin'] as Map<String, dynamic>);
        await _storageService.saveUserData(admin.toJson());

        // Save remember me preference
        await _storageService.saveRememberMe(rememberMe);

        // Return response with admin data
        return ApiResponse.success(
          data: admin,
          message: response.message ?? 'Login successful',
        );
      }
    }

    // Return the actual error message from the response
    return ApiResponse.error(
      message: response.error?.message ?? response.message ?? 'Login failed',
      code: response.error?.code,
    );
  }

  // Note: 2FA is included in login response, no separate verify endpoint needed

  /// Verify 2FA code
  Future<ApiResponse<AdminModel>> verify2FA({required String code}) async {
    // Use mock data if enabled
    if (AppConstants.useMockData) {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get mock admin data
      final admin = _mockDataService.currentAdmin;

      // Save tokens and admin data
      await _storageService.saveAccessToken('mock_access_token');
      await _storageService.saveRefreshToken('mock_refresh_token');
      await _storageService.saveUserData(admin.toJson());

      // Return mock success response with admin data
      return ApiResponse.success(
        data: admin,
        message: '2FA verification successful',
      );
    }

    // For now, return a simple success with mock data since backend endpoint may not be ready
    final admin = _mockDataService.currentAdmin;
    return ApiResponse.success(
      data: admin,
      message: '2FA verification successful',
    );
  }

  /// Logout admin
  Future<ApiResponse<void>> logout() async {
    // Use mock data if enabled
    if (AppConstants.useMockData) {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Clear local storage
      await _storageService.clearAll();

      // Return success response
      return ApiResponse.success(
        message: 'Logout successful',
      );
    }

    final response = await _apiService.post('/auth/logout');

    // Clear local storage regardless of API response
    await _storageService.clearAll();

    return response;
  }

  /// Forgot password
  Future<ApiResponse<void>> forgotPassword({
    required String email,
  }) async {
    return await _apiService.post(
      '/admin/forgot-password',
      data: {
        'email': email,
      },
    );
  }

  /// Reset password
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _apiService.post(
      '/admin/reset-password',
      data: {
        'token': token,
        'new_password': newPassword,
      },
    );
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _apiService.put(
      '/admin/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Get current admin profile
  Future<ApiResponse<AdminModel>> getProfile() async {
    // Use mock data if enabled
    if (AppConstants.useMockData) {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Get mock admin data
      final admin = _mockDataService.currentAdmin;

      // Return success response
      return ApiResponse.success(
        data: admin,
        message: 'Profile fetched successfully',
      );
    }

    return await _apiService.get(
      '/admin/profile',
      fromJson: (data) => AdminModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Refresh tokens
  Future<ApiResponse<void>> refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken == null) {
      return ApiResponse.error(message: 'No refresh token found');
    }

    final response = await _apiService.post(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
    );

    if (response.success && response.data != null) {
      // Handle different response structures
      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null) {
        // Try to get tokens from different possible locations
        final accessToken = responseData['access_token'] ?? responseData['accessToken'];
        final newRefreshToken = responseData['refresh_token'] ?? responseData['refreshToken'];

        if (accessToken != null) {
          await _storageService.saveAccessToken(accessToken);
        }
        if (newRefreshToken != null) {
          await _storageService.saveRefreshToken(newRefreshToken);
        }
      }
    }

    return response;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storageService.isLoggedIn();
  }

  /// Get stored admin data
  Future<AdminModel?> getStoredAdmin() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      return AdminModel.fromJson(userData);
    }
    return null;
  }
}
