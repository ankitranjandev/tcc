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
      final formatString = _getFormatString(format);
      final queryParameters = {
        'format': formatString,
        ...?filters,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );

      if (response.success && response.data != null) {
        final downloadUrl = response.data!['url'] as String?;
        final fileName = response.data!['filename'] as String? ?? 
            'export_${DateTime.now().millisecondsSinceEpoch}.$formatString';

        if (downloadUrl != null) {
          _downloadFile(downloadUrl, fileName);
          return ApiResponse.success(
            message: 'Export started successfully',
          );
        } else {
          // Handle direct file download response
          final fileData = response.data!['data'];
          if (fileData != null) {
            _downloadFileFromData(fileData as String, fileName, format);
            return ApiResponse.success(
              message: 'Export completed successfully',
            );
          }
        }
      }

      return ApiResponse.error(
        message: response.message ?? 'Export failed',
      );
    } catch (e) {
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
      final anchor = html.AnchorElement()
        ..href = url
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