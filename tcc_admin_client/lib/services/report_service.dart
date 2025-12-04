import '../models/api_response_model.dart';
import 'api_service.dart';

/// Report Service
/// Handles all report generation and analytics API calls for admin
class ReportService {
  final ApiService _apiService = ApiService();

  /// Generate report
  /// Creates a report based on type, format, and date range
  Future<ApiResponse<Map<String, dynamic>>> generateReport({
    required String type, // 'transactions', 'investments', 'users'
    String format = 'json', // 'json', 'csv', 'pdf'
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'type': type,
        'format': format,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '/admin/reports',
        queryParameters: queryParameters,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          data: response.data!,
          message: response.message,
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to generate report',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to generate report: ${e.toString()}',
      );
    }
  }

  /// Get transaction report
  /// Convenience method for transaction reports
  Future<ApiResponse<Map<String, dynamic>>> getTransactionReport({
    String format = 'json',
    DateTime? from,
    DateTime? to,
  }) async {
    return await generateReport(
      type: 'transactions',
      format: format,
      from: from,
      to: to,
    );
  }

  /// Get investment report
  /// Convenience method for investment reports
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentReport({
    String format = 'json',
    DateTime? from,
    DateTime? to,
  }) async {
    return await generateReport(
      type: 'investments',
      format: format,
      from: from,
      to: to,
    );
  }

  /// Get user report
  /// Convenience method for user reports
  Future<ApiResponse<Map<String, dynamic>>> getUserReport({
    String format = 'json',
    DateTime? from,
    DateTime? to,
  }) async {
    return await generateReport(
      type: 'users',
      format: format,
      from: from,
      to: to,
    );
  }

  /// Export report as CSV
  /// Generates and downloads CSV report
  Future<ApiResponse<String>> exportReportAsCSV({
    required String type,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await generateReport(
        type: type,
        format: 'csv',
        from: from,
        to: to,
      );

      if (response.success && response.data != null) {
        // Extract download URL or CSV content
        final url = response.data!['url'] as String? ??
                    response.data!['download_url'] as String? ??
                    '';

        return ApiResponse.success(
          data: url,
          message: 'Report exported successfully',
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to export report',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to export report: ${e.toString()}',
      );
    }
  }

  /// Export report as PDF
  /// Generates and downloads PDF report
  Future<ApiResponse<String>> exportReportAsPDF({
    required String type,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await generateReport(
        type: type,
        format: 'pdf',
        from: from,
        to: to,
      );

      if (response.success && response.data != null) {
        // Extract download URL
        final url = response.data!['url'] as String? ??
                    response.data!['download_url'] as String? ??
                    '';

        return ApiResponse.success(
          data: url,
          message: 'Report exported successfully',
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to export report',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to export report: ${e.toString()}',
      );
    }
  }

  /// Get report summary statistics
  /// Helper to extract summary data from report
  Map<String, dynamic> getReportSummary(Map<String, dynamic> reportData) {
    if (reportData.containsKey('summary')) {
      return reportData['summary'] as Map<String, dynamic>;
    }
    return {};
  }

  /// Get report data
  /// Helper to extract main data from report
  List<dynamic> getReportData(Map<String, dynamic> reportData) {
    if (reportData.containsKey('data')) {
      return reportData['data'] as List<dynamic>;
    }
    return [];
  }
}
