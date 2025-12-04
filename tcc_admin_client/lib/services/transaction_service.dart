import '../models/api_response_model.dart';
import '../models/transaction_model.dart';
import 'api_service.dart';

/// Transaction Service
/// Handles all transaction-related API calls for admin
class TransactionService {
  final ApiService _apiService = ApiService();

  /// Get all transactions with pagination, search, and filters
  Future<ApiResponse<PaginatedResponse<TransactionModel>>> getTransactions({
    int page = 1,
    int perPage = 25,
    String? search,
    String? type,
    String? status,
    String? userId,
    String? agentId,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': perPage,  // Backend uses 'limit' not 'per_page'
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (agentId != null && agentId.isNotEmpty) 'agent_id': agentId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/transactions',
      queryParameters: queryParameters,
    );

    // Transform the response to PaginatedResponse
    if (response.success && response.data != null && response.meta != null) {
      try {
        final responseData = response.data!;
        final transactions = (responseData['transactions'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<TransactionModel>(
            data: transactions,
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
          message: 'Failed to parse transactions response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load transactions',
    );
  }

  /// Get transaction by ID
  Future<ApiResponse<TransactionModel>> getTransactionById(String transactionId) async {
    return await _apiService.get(
      '/admin/transactions/$transactionId',
      fromJson: (data) => TransactionModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get pending withdrawals
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getWithdrawals({
    int page = 1,
    int limit = 25,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _apiService.get(
      '/admin/withdrawals',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Review withdrawal request (approve/reject)
  Future<ApiResponse<void>> reviewWithdrawal({
    required String withdrawalId,
    required String status, // 'COMPLETED' or 'REJECTED'
    String? reason,
  }) async {
    return await _apiService.post(
      '/admin/withdrawals/review',
      data: {
        'withdrawal_id': withdrawalId,
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  /// Get pending deposits
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getDeposits({
    int page = 1,
    int perPage = 25,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _apiService.get(
      '/admin/deposits',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Review deposit request (approve/reject)
  Future<ApiResponse<Map<String, dynamic>>> reviewDeposit({
    required String depositId,
    required String action, // 'approve' or 'reject'
    String? remarks,
  }) async {
    return await _apiService.post(
      '/admin/deposits/review',
      data: {
        'deposit_id': depositId,
        'action': action,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transaction statistics
  Future<ApiResponse<Map<String, dynamic>>> getTransactionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/transactions/stats',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transaction volume by type
  Future<ApiResponse<Map<String, dynamic>>> getTransactionVolume({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy, // 'day', 'week', 'month'
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
    };

    return await _apiService.get(
      '/admin/transactions/volume',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Export transactions data
  Future<ApiResponse<String>> exportTransactions({
    String format = 'csv',
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/transactions/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Reverse/cancel transaction (admin only)
  Future<ApiResponse<Map<String, dynamic>>> reverseTransaction({
    required String transactionId,
    required String reason,
  }) async {
    return await _apiService.post(
      '/admin/transactions/$transactionId/reverse',
      data: {
        'reason': reason,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transaction audit log
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getTransactionAuditLog({
    required String transactionId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/transactions/$transactionId/audit',
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
}
