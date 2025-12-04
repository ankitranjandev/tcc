import '../models/api_response_model.dart';
import 'api_service.dart';

/// Admin API Service
/// Centralized service for all admin-specific backend API calls
class AdminApiService {
  final ApiService _apiService = ApiService();

  // ==================== Dashboard APIs ====================

  /// Get dashboard statistics
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    return await _apiService.get(
      '/admin/dashboard/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get analytics KPI
  Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParameters = <String, dynamic>{
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/analytics',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  // ==================== User Management APIs ====================

  /// Get users with filters and pagination
  Future<ApiResponse<Map<String, dynamic>>> getUsers({
    int page = 1,
    int limit = 20,
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

    return await _apiService.get(
      '/admin/users',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  // ==================== Withdrawal Management APIs ====================

  /// Get withdrawals with filters and pagination
  Future<ApiResponse<Map<String, dynamic>>> getWithdrawals({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    return await _apiService.get(
      '/admin/withdrawals',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Review withdrawal request
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

  // ==================== Agent Credit Management APIs ====================

  /// Review agent credit request
  Future<ApiResponse<void>> reviewAgentCredit({
    required String requestId,
    required String status, // 'COMPLETED' or 'REJECTED'
    String? reason,
  }) async {
    return await _apiService.post(
      '/admin/agent-credits/review',
      data: {
        'request_id': requestId,
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ==================== System Configuration APIs ====================

  /// Get system configuration
  Future<ApiResponse<Map<String, dynamic>>> getSystemConfig() async {
    return await _apiService.get(
      '/admin/config',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update system configuration
  Future<ApiResponse<void>> updateSystemConfig({
    required Map<String, dynamic> config,
  }) async {
    return await _apiService.put(
      '/admin/config',
      data: {
        'config': config,
      },
    );
  }

  // ==================== Reports APIs ====================

  /// Generate report
  Future<ApiResponse<Map<String, dynamic>>> generateReport({
    required String type, // 'transactions', 'investments', 'users'
    String format = 'json', // 'json', 'csv', 'pdf'
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParameters = <String, dynamic>{
      'type': type,
      'format': format,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/reports',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
