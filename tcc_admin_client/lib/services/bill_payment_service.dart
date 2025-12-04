import '../models/api_response_model.dart';
import '../models/bill_payment_model.dart';
import 'api_service.dart';

/// Bill Payment Service
/// Handles all bill payment-related API calls for admin
class BillPaymentService {
  final ApiService _apiService = ApiService();

  /// Get all bill payments with pagination, search, and filters
  Future<ApiResponse<PaginatedResponse<BillPaymentModel>>> getBillPayments({
    int page = 1,
    int limit = 25,
    String? search,
    String? billType,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (billType != null && billType.isNotEmpty) 'bill_type': billType,
      if (status != null && status.isNotEmpty) 'status': status,
      if (fromDate != null) 'from_date': fromDate.toIso8601String(),
      if (toDate != null) 'to_date': toDate.toIso8601String(),
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/bill-payments',
      queryParameters: queryParameters,
    );

    // Transform the response to PaginatedResponse
    if (response.success && response.data != null && response.meta != null) {
      try {
        final responseData = response.data!;
        final billPayments = (responseData['billPayments'] as List<dynamic>)
            .map((e) => BillPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<BillPaymentModel>(
            data: billPayments,
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
          message: 'Failed to parse bill payments response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load bill payments',
    );
  }

  /// Get bill payment statistics
  Future<ApiResponse<Map<String, dynamic>>> getBillPaymentStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Get all bill payments to calculate stats
      final response = await getBillPayments(
        page: 1,
        limit: 1000, // Get a large number to calculate stats
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!response.success || response.data == null) {
        return ApiResponse.error(
          message: 'Failed to calculate bill payment statistics',
        );
      }

      final payments = response.data!.data;
      final totalPayments = payments.length;
      final completedPayments = payments.where((p) => p.status == 'COMPLETED').length;
      final pendingPayments = payments.where((p) => p.status == 'PENDING').length;
      final failedPayments = payments.where((p) => p.status == 'FAILED').length;
      final totalAmount = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final totalFees = payments.fold<double>(0.0, (sum, payment) => sum + payment.fee);

      // Group by bill type
      final byType = <String, int>{};
      for (final payment in payments) {
        byType[payment.billType] = (byType[payment.billType] ?? 0) + 1;
      }

      final stats = {
        'total_payments': totalPayments,
        'completed_payments': completedPayments,
        'pending_payments': pendingPayments,
        'failed_payments': failedPayments,
        'total_amount': totalAmount,
        'total_fees': totalFees,
        'total_revenue': totalAmount + totalFees,
        'by_type': byType,
        'average_amount': totalPayments > 0 ? totalAmount / totalPayments : 0.0,
      };

      return ApiResponse.success(data: stats);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to calculate bill payment statistics: ${e.toString()}',
      );
    }
  }

  /// Search bill payments by query
  Future<ApiResponse<List<BillPaymentModel>>> searchBillPayments({
    required String query,
    String? billType,
    String? status,
  }) async {
    try {
      final response = await getBillPayments(
        search: query,
        billType: billType,
        status: status,
        limit: 100,
      );

      if (!response.success || response.data == null) {
        return ApiResponse.error(
          message: response.error?.message ?? 'Failed to search bill payments',
        );
      }

      return ApiResponse.success(data: response.data!.data);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to search bill payments: ${e.toString()}',
      );
    }
  }

  /// Export bill payments data
  Future<ApiResponse<List<BillPaymentModel>>> exportBillPayments({
    String? billType,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await getBillPayments(
        billType: billType,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        limit: 10000, // Get all payments for export
      );

      if (!response.success || response.data == null) {
        return ApiResponse.error(
          message: response.error?.message ?? 'Failed to export bill payments',
        );
      }

      return ApiResponse.success(data: response.data!.data);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to export bill payments: ${e.toString()}',
      );
    }
  }
}
