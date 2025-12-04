import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import 'api_service.dart';

/// Reports Service
/// Handles all reporting and analytics-related API calls for admin
class ReportsService {
  final ApiService _apiService = ApiService();

  /// Generate mock data from analytics when specific report endpoint is not available
  Map<String, dynamic> _generateMockDataFromAnalytics(
    Map<String, dynamic> analytics,
    String reportType,
  ) {
    debugPrint('Generating mock data for $reportType report from analytics');

    final transactions = analytics['transactions'] as Map<String, dynamic>? ?? {};
    final users = analytics['users'] as Map<String, dynamic>? ?? {};
    final agents = analytics['agents'] as Map<String, dynamic>? ?? {};

    switch (reportType) {
      case 'transactions':
        return {
          'transactions': [],
          'summary': {
            'total_count': transactions['total_count'] ?? 0,
            'total_volume': transactions['total_volume'] ?? 0,
            'by_type': transactions['by_type'] ?? {},
            'by_status': transactions['by_status'] ?? {},
          },
          'count': 0,
        };

      case 'user-activity':
        return {
          'users': [],
          'summary': {
            'total_users': users['total_users'] ?? 0,
            'active_users': users['active_users'] ?? 0,
            'new_users_today': users['new_users_today'] ?? 0,
            'kyc_pending_users': users['kyc_pending_users'] ?? 0,
          },
          'count': 0,
        };

      case 'revenue':
        return {
          'revenue': [
            {'date': DateTime.now().toIso8601String(), 'amount': transactions['total_volume'] ?? 0},
          ],
          'total': transactions['total_volume'] ?? 0,
        };

      case 'investments':
        return {
          'investments': [],
          'summary': {
            'total_investments': 0,
            'total_amount': 0,
            'active': 0,
            'matured': 0,
          },
          'count': 0,
        };

      case 'agent-performance':
        return {
          'agents': [],
          'summary': {
            'total_agents': agents['total_agents'] ?? 0,
            'active_agents': agents['active_agents'] ?? 0,
            'total_commission': agents['total_commission'] ?? 0,
          },
          'count': 0,
        };

      default:
        return {
          'data': [],
          'count': 0,
        };
    }
  }

  /// Get system analytics overview
  Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/analytics',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get financial report
  Future<ApiResponse<Map<String, dynamic>>> getFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
    String? format, // 'json', 'pdf', 'excel'
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (format != null && format.isNotEmpty) 'format': format,
    };

    return await _apiService.get(
      '/admin/reports/financial',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get user activity report
  Future<ApiResponse<Map<String, dynamic>>> getUserActivityReport({
    DateTime? startDate,
    DateTime? endDate,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (format != null && format.isNotEmpty) 'format': format,
    };

    final response = await _apiService.get(
      '/admin/reports/user-activity',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    // If 404, fallback to analytics data
    if (!response.success && response.error?.code == 'HTTP_404') {
      final analyticsResponse = await getAnalytics(startDate: startDate, endDate: endDate);
      if (analyticsResponse.success && analyticsResponse.data != null) {
        return ApiResponse.success(
          data: _generateMockDataFromAnalytics(analyticsResponse.data!, 'user-activity'),
          message: 'Using analytics data (specific endpoint not available)',
        );
      }
    }

    return response;
  }

  /// Get transaction report
  Future<ApiResponse<Map<String, dynamic>>> getTransactionReport({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? status,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    final response = await _apiService.get(
      '/admin/reports/transactions',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    // If 404, fallback to analytics data
    if (!response.success && response.error?.code == 'HTTP_404') {
      final analyticsResponse = await getAnalytics(startDate: startDate, endDate: endDate);
      if (analyticsResponse.success && analyticsResponse.data != null) {
        return ApiResponse.success(
          data: _generateMockDataFromAnalytics(analyticsResponse.data!, 'transactions'),
          message: 'Using analytics data (specific endpoint not available)',
        );
      }
    }

    return response;
  }

  /// Get agent performance report
  Future<ApiResponse<Map<String, dynamic>>> getAgentPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
    String? agentId,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (agentId != null && agentId.isNotEmpty) 'agent_id': agentId,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    final response = await _apiService.get(
      '/admin/reports/agent-performance',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    // If 404, fallback to analytics data
    if (!response.success && response.error?.code == 'HTTP_404') {
      final analyticsResponse = await getAnalytics(startDate: startDate, endDate: endDate);
      if (analyticsResponse.success && analyticsResponse.data != null) {
        return ApiResponse.success(
          data: _generateMockDataFromAnalytics(analyticsResponse.data!, 'agent-performance'),
          message: 'Using analytics data (specific endpoint not available)',
        );
      }
    }

    return response;
  }

  /// Get investment report
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentReport({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    final response = await _apiService.get(
      '/admin/reports/investments',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    // If 404, fallback to analytics data
    if (!response.success && response.error?.code == 'HTTP_404') {
      final analyticsResponse = await getAnalytics(startDate: startDate, endDate: endDate);
      if (analyticsResponse.success && analyticsResponse.data != null) {
        return ApiResponse.success(
          data: _generateMockDataFromAnalytics(analyticsResponse.data!, 'investments'),
          message: 'Using analytics data (specific endpoint not available)',
        );
      }
    }

    return response;
  }

  /// Get KYC verification report
  Future<ApiResponse<Map<String, dynamic>>> getKycReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    return await _apiService.get(
      '/admin/reports/kyc',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get revenue report
  Future<ApiResponse<Map<String, dynamic>>> getRevenueReport({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy, // 'day', 'week', 'month', 'year'
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    final response = await _apiService.get(
      '/admin/reports/revenue',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    // If 404, fallback to analytics data
    if (!response.success && response.error?.code == 'HTTP_404') {
      final analyticsResponse = await getAnalytics(startDate: startDate, endDate: endDate);
      if (analyticsResponse.success && analyticsResponse.data != null) {
        return ApiResponse.success(
          data: _generateMockDataFromAnalytics(analyticsResponse.data!, 'revenue'),
          message: 'Using analytics data (specific endpoint not available)',
        );
      }
    }

    return response;
  }

  /// Get user growth report
  Future<ApiResponse<Map<String, dynamic>>> getUserGrowthReport({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    return await _apiService.get(
      '/admin/reports/user-growth',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get custom report
  Future<ApiResponse<Map<String, dynamic>>> getCustomReport({
    required String reportType,
    Map<String, dynamic>? filters,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      'report_type': reportType,
      if (filters != null) ...filters,
      if (format != null && format.isNotEmpty) 'format': format,
    };

    return await _apiService.get(
      '/admin/reports/custom',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Generate scheduled report
  Future<ApiResponse<Map<String, dynamic>>> generateScheduledReport({
    required String reportType,
    required String frequency, // 'daily', 'weekly', 'monthly'
    List<String>? recipients,
    String? format,
  }) async {
    return await _apiService.post(
      '/admin/reports/scheduled',
      data: {
        'report_type': reportType,
        'frequency': frequency,
        if (recipients != null && recipients.isNotEmpty) 'recipients': recipients,
        if (format != null && format.isNotEmpty) 'format': format,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get available report types
  Future<ApiResponse<List<Map<String, dynamic>>>> getReportTypes() async {
    return await _apiService.get(
      '/admin/reports/types',
      fromJson: (data) {
        final types = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return types;
      },
    );
  }

  /// Download report file
  Future<ApiResponse<String>> downloadReport({
    required String reportId,
    String? format,
  }) async {
    final queryParameters = <String, dynamic>{
      if (format != null && format.isNotEmpty) 'format': format,
    };

    return await _apiService.get(
      '/admin/reports/$reportId/download',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Get report history
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getReportHistory({
    int page = 1,
    int perPage = 25,
    String? reportType,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (reportType != null && reportType.isNotEmpty) 'report_type': reportType,
    };

    final response = await _apiService.get(
      '/admin/reports/history',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Delete report
  Future<ApiResponse<void>> deleteReport(String reportId) async {
    return await _apiService.delete(
      '/admin/reports/$reportId',
    );
  }

  /// Get system metrics (real-time)
  Future<ApiResponse<Map<String, dynamic>>> getSystemMetrics() async {
    return await _apiService.get(
      '/admin/analytics/metrics',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get chart data for dashboard
  Future<ApiResponse<Map<String, dynamic>>> getChartData({
    required String chartType, // 'transactions', 'users', 'revenue', etc.
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy,
  }) async {
    final queryParameters = <String, dynamic>{
      'chart_type': chartType,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
    };

    return await _apiService.get(
      '/admin/analytics/charts',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
