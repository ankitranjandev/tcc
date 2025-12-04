import '../models/api_response_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// User Management Service
/// Handles all user management-related API calls for admin
class UserManagementService {
  final ApiService _apiService = ApiService();

  /// Get all users with pagination, search, and filters
  Future<ApiResponse<PaginatedResponse<UserModel>>> getUsers({
    int page = 1,
    int limit = 25,
    String? search,
    String? role,
    String? kycStatus,
    bool? isActive,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      if (kycStatus != null && kycStatus.isNotEmpty) 'kyc_status': kycStatus,
      if (isActive != null) 'is_active': isActive.toString(),
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: queryParameters,
    );

    // Transform the response to PaginatedResponse
    if (response.success && response.data != null && response.meta != null) {
      try {
        final responseData = response.data!;
        final users = (responseData['users'] as List<dynamic>)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<UserModel>(
            data: users,
            total: pagination['total'] as int,
            page: pagination['page'] as int,
            perPage: pagination['limit'] as int,
            totalPages: pagination['totalPages'] as int,
          );

          return ApiResponse.success(
            data: paginatedResponse,
            message: response.message,
          );
        }
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse users response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load users',
    );
  }

  /// Get user by ID
  Future<ApiResponse<UserModel>> getUserById(String userId) async {
    return await _apiService.get(
      '/admin/users/$userId',
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Search users by query
  Future<ApiResponse<List<UserModel>>> searchUsers({
    required String query,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/users',
      queryParameters: {
        'search': query,
        'per_page': limit,
      },
      fromJson: (data) {
        final paginatedData = data as Map<String, dynamic>;
        final users = (paginatedData['data'] as List<dynamic>)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return users;
      },
    );

    return response;
  }

  /// Update user status (activate, deactivate, suspend)
  Future<ApiResponse<UserModel>> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    return await _apiService.put(
      '/admin/users/$userId/status',
      data: {
        'status': status,
      },
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get user statistics
  Future<ApiResponse<Map<String, dynamic>>> getUserStats() async {
    return await _apiService.get(
      '/admin/users/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Export users data
  Future<ApiResponse<String>> exportUsers({
    String format = 'csv',
    String? status,
    String? kycStatus,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      if (status != null && status.isNotEmpty) 'status': status,
      if (kycStatus != null && kycStatus.isNotEmpty) 'kyc_status': kycStatus,
    };

    return await _apiService.get(
      '/admin/users/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Get user transaction history
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getUserTransactions({
    required String userId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/users/$userId/transactions',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Get user wallet details
  Future<ApiResponse<Map<String, dynamic>>> getUserWallet(String userId) async {
    return await _apiService.get(
      '/admin/users/$userId/wallet',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Adjust user wallet balance (admin credit/debit)
  Future<ApiResponse<Map<String, dynamic>>> adjustWalletBalance({
    required String userId,
    required double amount,
    required String type, // 'credit' or 'debit'
    required String reason,
  }) async {
    return await _apiService.post(
      '/admin/users/$userId/wallet/adjust',
      data: {
        'amount': amount,
        'type': type,
        'reason': reason,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get user activity log
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getUserActivityLog({
    required String userId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/users/$userId/activity',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Create new user (admin only)
  Future<ApiResponse<UserModel>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? countryCode,
    DateTime? dateOfBirth,
    String? address,
    String role = 'USER',
  }) async {
    return await _apiService.post(
      '/admin/users',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (countryCode != null && countryCode.isNotEmpty) 'country_code': countryCode,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (address != null && address.isNotEmpty) 'address': address,
        'role': role,
      },
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update user details
  Future<ApiResponse<UserModel>> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    return await _apiService.put(
      '/admin/users/$userId',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'country_code': countryCode,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (address != null) 'address': address,
      },
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete user
  Future<ApiResponse<void>> deleteUser(String userId) async {
    return await _apiService.delete(
      '/admin/users/$userId',
    );
  }
}
