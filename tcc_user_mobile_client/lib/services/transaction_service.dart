import 'dart:developer' as developer;
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

      // Log to detect null dates from API
      _validateTransactionDates(response);

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Validate transaction dates and log issues
  void _validateTransactionDates(Map<String, dynamic> response) {
    try {
      if (response['data'] != null && response['data']['transactions'] is List) {
        final transactions = response['data']['transactions'] as List;
        int nullDateCount = 0;

        for (var tx in transactions) {
          if (tx is Map<String, dynamic>) {
            final hasDate = tx['date'] != null;
            final hasCreatedAt = tx['created_at'] != null;
            final hasCreatedAtCamel = tx['createdAt'] != null;
            final hasTimestamp = tx['timestamp'] != null;

            if (!hasDate && !hasCreatedAt && !hasCreatedAtCamel && !hasTimestamp) {
              nullDateCount++;
              developer.log(
                '⚠️ Transaction ${tx['id'] ?? 'unknown'} has no date field!',
                name: 'TransactionService',
              );
            }
          }
        }

        if (nullDateCount > 0) {
          developer.log(
            '⚠️ Found $nullDateCount transactions with null dates out of ${transactions.length} total',
            name: 'TransactionService',
          );
        } else {
          developer.log(
            '✅ All ${transactions.length} transactions have date fields',
            name: 'TransactionService',
          );
        }
      }
    } catch (e) {
      developer.log(
        '❌ Error validating transaction dates: $e',
        name: 'TransactionService',
      );
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

  // Download transaction receipt as PDF bytes
  Future<Map<String, dynamic>> downloadReceiptPdf({
    required String transactionId,
  }) async {
    try {
      final bytes = await _apiService.downloadFile(
        '/transactions/$transactionId/receipt',
        requiresAuth: true,
      );
      return {'success': true, 'data': bytes};
    } catch (e) {
      developer.log(
        '❌ Error downloading receipt PDF: $e',
        name: 'TransactionService',
      );
      return {'success': false, 'error': e.toString()};
    }
  }
}
