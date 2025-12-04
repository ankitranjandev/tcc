import 'api_service.dart';

class TransactionService {
  final ApiService _apiService = ApiService();

  // Get transaction history with filters
  Future<Map<String, dynamic>> getTransactionHistory({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

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

  // Get transaction details by ID
  Future<Map<String, dynamic>> getTransactionDetails({
    required String transactionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/transactions/$transactionId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats({
    String? period, // 'today', 'week', 'month', 'year'
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.get(
        '/transactions/stats',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Download transaction receipt
  Future<Map<String, dynamic>> downloadReceipt({
    required String transactionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/transactions/$transactionId/receipt',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
