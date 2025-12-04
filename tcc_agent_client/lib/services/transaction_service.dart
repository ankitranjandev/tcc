import 'api_service.dart';

class TransactionService {
  final ApiService _apiService = ApiService();

  // Get Transaction History
  Future<Map<String, dynamic>> getTransactionHistory({
    int? page,
    int? limit,
    String? type,
    String? status,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (search != null) 'search': search,
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

  // Get Transaction Statistics
  Future<Map<String, dynamic>> getTransactionStats({
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
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Transaction Details
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

  // Download Transaction Receipt
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
