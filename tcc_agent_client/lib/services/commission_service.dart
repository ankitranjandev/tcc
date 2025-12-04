import 'api_service.dart';

class CommissionService {
  final ApiService _apiService = ApiService();

  // Get Commission History
  // Uses the transaction history endpoint filtered by COMMISSION type
  Future<Map<String, dynamic>> getCommissionHistory({
    int? page,
    int? limit,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'COMMISSION', // Filter for commission transactions
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (status != null) 'status': status,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };

      final response = await _apiService.get(
        '/transactions/history',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Commission Statistics
  // Uses the transaction stats endpoint to get commission-specific stats
  Future<Map<String, dynamic>> getCommissionStats({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };

      final response = await _apiService.get(
        '/transactions/stats',
        queryParams: queryParams,
        requiresAuth: true,
      );

      // The stats will include commission information
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Total Commissions Earned
  // Uses the agent dashboard endpoint which includes commission data
  Future<Map<String, dynamic>> getTotalCommissionsEarned({
    required String agentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'agent_id': agentId,
      };

      final response = await _apiService.get(
        '/agent/dashboard',
        queryParams: queryParams,
        requiresAuth: true,
      );

      // Extract commission data from dashboard stats
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Commission Rate
  // Uses the agent profile endpoint to get the commission rate
  Future<Map<String, dynamic>> getCommissionRate() async {
    try {
      final response = await _apiService.get(
        '/agent/profile',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
