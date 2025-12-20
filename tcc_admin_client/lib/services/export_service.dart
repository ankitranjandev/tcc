import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../models/api_response_model.dart';
import '../widgets/dialogs/export_dialog.dart';
import 'api_service.dart';

/// Export Service
/// Handles all data export functionality across the admin app
class ExportService {
  final ApiService _apiService = ApiService();

  /// Export users data
  Future<ApiResponse<void>> exportUsers({
    required ExportFormat format,
    String? search,
    String? role,
    String? status,
    String? kycStatus,
  }) async {
    return _exportData(
      endpoint: '/admin/users/export',
      format: format,
      filters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
        if (kycStatus != null && kycStatus.isNotEmpty) 'kycStatus': kycStatus,
      },
    );
  }

  /// Export transactions data
  Future<ApiResponse<void>> exportTransactions({
    required ExportFormat format,
    String? search,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _exportData(
      endpoint: '/admin/transactions/export',
      format: format,
      filters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
  }

  /// Export investments data
  Future<ApiResponse<void>> exportInvestments({
    required ExportFormat format,
    String? search,
    String? status,
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _exportData(
      endpoint: '/admin/investments/export',
      format: format,
      filters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
  }

  /// Export bill payments data
  Future<ApiResponse<void>> exportBillPayments({
    required ExportFormat format,
    String? search,
    String? status,
    String? billerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _exportData(
      endpoint: '/admin/bill-payments/export',
      format: format,
      filters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (billerId != null && billerId.isNotEmpty) 'billerId': billerId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
  }

  /// Export e-voting data
  Future<ApiResponse<void>> exportEVoting({
    required ExportFormat format,
    String? electionId,
    String? status,
  }) async {
    return _exportData(
      endpoint: '/admin/e-voting/export',
      format: format,
      filters: {
        if (electionId != null && electionId.isNotEmpty) 'electionId': electionId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
  }

  /// Export reports data
  Future<ApiResponse<void>> exportReports({
    required ExportFormat format,
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? additionalFilters,
  }) async {
    return _exportData(
      endpoint: '/admin/reports/export',
      format: format,
      filters: {
        'reportType': reportType,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        ...?additionalFilters,
      },
    );
  }

  /// Generic export method
  Future<ApiResponse<void>> _exportData({
    required String endpoint,
    required ExportFormat format,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('=== EXPORT DEBUG START ===');
      debugPrint('Export endpoint: $endpoint');
      debugPrint('Export format: $format');

      final formatString = _getFormatString(format);
      debugPrint('Format string: $formatString');

      final queryParameters = {
        'format': formatString,
        ...?filters,
      };
      debugPrint('Query parameters: $queryParameters');

      debugPrint('Making API request...');
      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );

      debugPrint('API Response received');
      debugPrint('Response success: ${response.success}');
      debugPrint('Response data: ${response.data}');
      debugPrint('Response message: ${response.message}');
      debugPrint('Response error: ${response.error}');

      if (response.success && response.data != null) {
        debugPrint('Response data type: ${response.data.runtimeType}');
        debugPrint('Response data keys: ${response.data!.keys}');

        final downloadUrl = response.data!['url'] as String?;
        debugPrint('Download URL: $downloadUrl');

        final fileName = response.data!['filename'] as String? ??
            'export_${DateTime.now().millisecondsSinceEpoch}.$formatString';
        debugPrint('File name: $fileName');

        if (downloadUrl != null) {
          debugPrint('Starting file download from URL...');
          _downloadFile(downloadUrl, fileName);
          debugPrint('=== EXPORT DEBUG END (SUCCESS) ===');
          return ApiResponse.success(
            message: 'Export started successfully',
          );
        } else {
          debugPrint('No download URL, checking for direct data...');
          // Handle direct file download response
          final fileData = response.data!['data'];
          debugPrint('File data: ${fileData != null ? "present" : "null"}');

          if (fileData != null) {
            debugPrint('Starting file download from data...');
            _downloadFileFromData(fileData as String, fileName, format);
            debugPrint('=== EXPORT DEBUG END (SUCCESS) ===');
            return ApiResponse.success(
              message: 'Export completed successfully',
            );
          } else {
            debugPrint('ERROR: No download URL or data in response');
          }
        }
      } else {
        debugPrint('ERROR: Response not successful or data is null');
        debugPrint('Response success: ${response.success}');
        debugPrint('Response data is null: ${response.data == null}');
      }

      debugPrint('=== EXPORT DEBUG END (FAILED) ===');
      return ApiResponse.error(
        message: response.message ?? 'Export failed. The server encountered an error while processing your request.',
      );
    } catch (e, stackTrace) {
      debugPrint('=== EXPORT DEBUG EXCEPTION ===');
      debugPrint('Exception type: ${e.runtimeType}');
      debugPrint('Exception message: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== EXPORT DEBUG END (EXCEPTION) ===');

      return ApiResponse.error(
        message: 'Export failed: ${e.toString()}',
      );
    }
  }

  /// Convert ExportFormat enum to string
  String _getFormatString(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'pdf';
      case ExportFormat.excel:
        return 'xlsx';
      case ExportFormat.csv:
        return 'csv';
    }
  }

  /// Download file from URL
  void _downloadFile(String url, String filename) {
    if (kIsWeb) {
      // Construct full URL if it's a relative path
      String fullUrl = url;
      if (url.startsWith('/')) {
        // Remove /v1 from the base URL since static files are served at root
        final baseUrl = ApiService.baseUrl.replaceAll('/v1', '');
        fullUrl = '$baseUrl$url';
      }

      debugPrint('Downloading file from: $fullUrl');

      final anchor = html.AnchorElement()
        ..href = fullUrl
        ..target = 'blank'
        ..download = filename;

      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
    } else {
      // For mobile/desktop platforms, you would implement platform-specific download
      // For now, this is a no-op as export is primarily used on web
      debugPrint('Download URL: $url');
    }
  }

  /// Download file from base64 data
  void _downloadFileFromData(String data, String filename, ExportFormat format) {
    if (kIsWeb) {
      String mimeType;
      switch (format) {
        case ExportFormat.pdf:
          mimeType = 'application/pdf';
          break;
        case ExportFormat.excel:
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case ExportFormat.csv:
          mimeType = 'text/csv';
          break;
      }

      final blob = html.Blob([data], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement()
        ..href = url
        ..target = 'blank'
        ..download = filename;
      
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop platforms, you would implement platform-specific download
      // For now, this is a no-op as export is primarily used on web
      debugPrint('Download data: $filename');
    }
  }
}