import '../models/api_response_model.dart';
import '../models/consumer_model.dart';
import 'api_service.dart';

/// Consumer Management Service
/// Handles all consumer management-related API calls for admin
/// Consumers are users from the TCC user mobile app
class ConsumerService {
  final ApiService _apiService = ApiService();

  /// Get all consumers with pagination, search, and filters
  Future<ApiResponse<PaginatedResponse<ConsumerModel>>> getConsumers({
    int page = 1,
    int limit = 25,
    String? search,
    String? kycStatus,
    bool? isActive,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'role': 'USER', // Filter to get only consumers (not agents or admins)
      if (search != null && search.isNotEmpty) 'search': search,
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
        final consumers = (responseData['users'] as List<dynamic>)
            .map((e) => ConsumerModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination =
            response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<ConsumerModel>(
            data: consumers,
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
          message: 'Failed to parse consumers response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load consumers',
    );
  }

  /// Get consumer by ID
  Future<ApiResponse<ConsumerModel>> getConsumerById(String consumerId) async {
    return await _apiService.get(
      '/admin/users/$consumerId',
      fromJson: (data) => ConsumerModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Search consumers by query
  Future<ApiResponse<List<ConsumerModel>>> searchConsumers({
    required String query,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/users',
      queryParameters: {'search': query, 'limit': limit, 'role': 'USER'},
      fromJson: (data) {
        final paginatedData = data as Map<String, dynamic>;
        final consumers = (paginatedData['users'] as List<dynamic>)
            .map((e) => ConsumerModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return consumers;
      },
    );

    return response;
  }

  /// Update consumer status (activate, deactivate, suspend)
  Future<ApiResponse<ConsumerModel>> updateConsumerStatus({
    required String consumerId,
    required String status,
  }) async {
    return await _apiService.put(
      '/admin/users/$consumerId/status',
      data: {'status': status},
      fromJson: (data) => ConsumerModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get consumer statistics
  Future<ApiResponse<Map<String, dynamic>>> getConsumerStats() async {
    return await _apiService.get(
      '/admin/users/stats',
      queryParameters: {'role': 'USER'},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get consumer transaction history
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>>
  getConsumerTransactions({
    required String consumerId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/users/$consumerId/transactions',
      queryParameters: {'page': page, 'per_page': perPage},
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Get consumer wallet details
  Future<ApiResponse<Map<String, dynamic>>> getConsumerWallet(
    String consumerId,
  ) async {
    return await _apiService.get(
      '/admin/users/$consumerId/wallet',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Adjust consumer wallet balance (admin credit/debit)
  Future<ApiResponse<Map<String, dynamic>>> adjustWalletBalance({
    required String consumerId,
    required double amount,
    required String type, // 'credit' or 'debit'
    required String reason,
  }) async {
    return await _apiService.post(
      '/admin/users/$consumerId/wallet/adjust',
      data: {'amount': amount, 'type': type, 'reason': reason},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get consumer activity log
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>>
  getConsumerActivityLog({
    required String consumerId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/users/$consumerId/activity',
      queryParameters: {'page': page, 'per_page': perPage},
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Get consumer investments
  Future<ApiResponse<List<Map<String, dynamic>>>> getConsumerInvestments(
    String consumerId,
  ) async {
    return await _apiService.get(
      '/admin/users/$consumerId/investments',
      fromJson: (data) {
        final investments = data as List<dynamic>;
        return investments.map((e) => e as Map<String, dynamic>).toList();
      },
    );
  }

  /// Get consumer KYC documents
  Future<ApiResponse<Map<String, dynamic>>> getConsumerKyc(
    String consumerId,
  ) async {
    return await _apiService.get(
      '/admin/users/$consumerId/kyc',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update consumer KYC status
  Future<ApiResponse<ConsumerModel>> updateConsumerKycStatus({
    required String consumerId,
    required String status,
    String? remarks,
  }) async {
    return await _apiService.put(
      '/admin/users/$consumerId/kyc/status',
      data: {
        'status': status,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => ConsumerModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Export consumers data
  Future<ApiResponse<String>> exportConsumers({
    String format = 'csv',
    String? status,
    String? kycStatus,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      'role': 'USER',
      if (status != null && status.isNotEmpty) 'status': status,
      if (kycStatus != null && kycStatus.isNotEmpty) 'kyc_status': kycStatus,
    };

    return await _apiService.get(
      '/admin/users/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Update consumer details
  Future<ApiResponse<ConsumerModel>> updateConsumer({
    required String consumerId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    return await _apiService.put(
      '/admin/users/$consumerId',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'country_code': countryCode,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (address != null) 'address': address,
      },
      fromJson: (data) => ConsumerModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete consumer
  Future<ApiResponse<void>> deleteConsumer(String consumerId) async {
    return await _apiService.delete('/admin/users/$consumerId');
  }
}
