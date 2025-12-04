import '../models/api_response_model.dart';
import 'api_service.dart';

/// Dashboard Service
/// Handles all dashboard-related API calls for admin
class DashboardService {
  final ApiService _apiService = ApiService();

  /// Get dashboard statistics
  /// Returns overview stats for admin dashboard
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    return await _apiService.get(
      '/admin/dashboard/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get analytics KPI
  Future<ApiResponse<Map<String, dynamic>>> getAnalyticsKPI({
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

  /// Get real-time statistics
  Future<ApiResponse<Map<String, dynamic>>> getRealtimeStats() async {
    return await _apiService.get(
      '/admin/dashboard/realtime',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get recent activities
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentActivities({
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/dashboard/activities',
      queryParameters: {
        'limit': limit,
      },
      fromJson: (data) {
        final activities = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return activities;
      },
    );

    return response;
  }

  /// Get pending approvals count
  Future<ApiResponse<Map<String, dynamic>>> getPendingApprovalsCount() async {
    return await _apiService.get(
      '/admin/dashboard/pending-approvals',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get pending items for admin action
  Future<ApiResponse<Map<String, dynamic>>> getPendingItems() async {
    return await _apiService.get(
      '/admin/dashboard/pending-items',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get system alerts and notifications
  Future<ApiResponse<List<Map<String, dynamic>>>> getSystemAlerts({
    int limit = 5,
    String? severity, // 'low', 'medium', 'high', 'critical'
  }) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
    };

    final response = await _apiService.get(
      '/admin/dashboard/alerts',
      queryParameters: queryParameters,
      fromJson: (data) {
        final alerts = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return alerts;
      },
    );

    return response;
  }

  /// Get user statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getUserStatsSummary() async {
    return await _apiService.get(
      '/admin/dashboard/user-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transaction statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getTransactionStatsSummary() async {
    return await _apiService.get(
      '/admin/dashboard/transaction-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get agent statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getAgentStatsSummary() async {
    return await _apiService.get(
      '/admin/dashboard/agent-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get investment statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentStatsSummary() async {
    return await _apiService.get(
      '/admin/dashboard/investment-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get KYC statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getKycStatsSummary() async {
    return await _apiService.get(
      '/admin/dashboard/kyc-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get revenue statistics summary
  Future<ApiResponse<Map<String, dynamic>>> getRevenueStatsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/dashboard/revenue-stats',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get top users (by transaction volume, wallet balance, etc.)
  Future<ApiResponse<List<Map<String, dynamic>>>> getTopUsers({
    String sortBy = 'transaction_volume', // 'transaction_volume', 'wallet_balance', 'investments'
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/dashboard/top-users',
      queryParameters: {
        'sort_by': sortBy,
        'limit': limit,
      },
      fromJson: (data) {
        final users = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return users;
      },
    );

    return response;
  }

  /// Get top agents (by performance)
  Future<ApiResponse<List<Map<String, dynamic>>>> getTopAgents({
    String sortBy = 'transactions', // 'transactions', 'commission', 'rating'
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/dashboard/top-agents',
      queryParameters: {
        'sort_by': sortBy,
        'limit': limit,
      },
      fromJson: (data) {
        final agents = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return agents;
      },
    );

    return response;
  }

  /// Get recent transactions
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentTransactions({
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/dashboard/recent-transactions',
      queryParameters: {
        'limit': limit,
      },
      fromJson: (data) {
        final transactions = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return transactions;
      },
    );

    return response;
  }

  /// Get growth metrics (users, transactions, revenue over time)
  Future<ApiResponse<Map<String, dynamic>>> getGrowthMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'day', // 'day', 'week', 'month'
  }) async {
    final queryParameters = <String, dynamic>{
      'group_by': groupBy,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/admin/dashboard/growth',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get system health status
  Future<ApiResponse<Map<String, dynamic>>> getSystemHealth() async {
    return await _apiService.get(
      '/admin/dashboard/system-health',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get platform performance metrics
  Future<ApiResponse<Map<String, dynamic>>> getPlatformMetrics() async {
    return await _apiService.get(
      '/admin/dashboard/platform-metrics',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Mark notification as read
  Future<ApiResponse<void>> markNotificationRead(String notificationId) async {
    return await _apiService.put(
      '/admin/notifications/$notificationId/read',
    );
  }

  /// Get unread notification count
  Future<ApiResponse<int>> getUnreadNotificationCount() async {
    return await _apiService.get(
      '/admin/notifications/unread-count',
      fromJson: (data) => data['count'] as int,
    );
  }

  /// Get admin notifications
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getNotifications({
    int page = 1,
    int perPage = 25,
    bool? unreadOnly,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (unreadOnly != null) 'unread_only': unreadOnly,
    };

    final response = await _apiService.get(
      '/admin/notifications',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Dismiss alert
  Future<ApiResponse<void>> dismissAlert(String alertId) async {
    return await _apiService.put(
      '/admin/alerts/$alertId/dismiss',
    );
  }
}
