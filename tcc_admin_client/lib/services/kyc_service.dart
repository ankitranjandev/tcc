import '../models/api_response_model.dart';
import 'api_service.dart';

/// KYC Service
/// Handles all KYC verification-related API calls for admin
class KycService {
  final ApiService _apiService = ApiService();

  /// Get all KYC submissions with pagination and filters
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getKycSubmissions({
    int page = 1,
    int perPage = 25,
    String? status,
    String? userType, // 'user' or 'agent'
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (userType != null && userType.isNotEmpty) 'user_type': userType,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    final response = await _apiService.get(
      '/kyc/admin/submissions',
      queryParameters: queryParameters,
      fromJson: (data) {
        final responseData = data as Map<String, dynamic>;
        final submissions = responseData['submissions'] as List<dynamic>;
        final pagination = responseData['meta']?['pagination'] as Map<String, dynamic>?;
        
        return PaginatedResponse<Map<String, dynamic>>(
          data: submissions.map((e) => e as Map<String, dynamic>).toList(),
          total: pagination?['total'] ?? 0,
          page: pagination?['page'] ?? 1,
          perPage: pagination?['limit'] ?? perPage,
          totalPages: pagination?['totalPages'] ?? 1,
        );
      },
    );

    return response;
  }

  /// Get KYC submission by ID
  Future<ApiResponse<Map<String, dynamic>>> getKycSubmissionById(String submissionId) async {
    return await _apiService.get(
      '/kyc/admin/submissions/$submissionId',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get KYC submissions for a specific user
  Future<ApiResponse<List<Map<String, dynamic>>>> getUserKycSubmissions(String userId) async {
    return await _apiService.get(
      '/kyc/admin/users/$userId/submissions',
      fromJson: (data) {
        final submissions = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return submissions;
      },
    );
  }

  /// Review KYC submission (approve/reject)
  Future<ApiResponse<Map<String, dynamic>>> reviewKycSubmission({
    required String submissionId,
    required String action, // 'approve' or 'reject'
    String? remarks,
  }) async {
    return await _apiService.post(
      '/kyc/admin/review/$submissionId',
      data: {
        'action': action,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Request additional documents from user
  Future<ApiResponse<Map<String, dynamic>>> requestAdditionalDocuments({
    required String submissionId,
    required List<String> requiredDocuments,
    String? message,
  }) async {
    return await _apiService.post(
      '/kyc/admin/submissions/$submissionId/request-documents',
      data: {
        'required_documents': requiredDocuments,
        if (message != null && message.isNotEmpty) 'message': message,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get KYC statistics
  Future<ApiResponse<Map<String, dynamic>>> getKycStats() async {
    return await _apiService.get(
      '/kyc/admin/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get pending KYC count
  Future<ApiResponse<int>> getPendingKycCount() async {
    return await _apiService.get(
      '/kyc/admin/pending-count',
      fromJson: (data) => data['count'] as int,
    );
  }

  /// Bulk approve KYC submissions
  Future<ApiResponse<Map<String, dynamic>>> bulkApproveKyc({
    required List<String> submissionIds,
    String? remarks,
  }) async {
    return await _apiService.post(
      '/kyc/admin/bulk-approve',
      data: {
        'submission_ids': submissionIds,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Bulk reject KYC submissions
  Future<ApiResponse<Map<String, dynamic>>> bulkRejectKyc({
    required List<String> submissionIds,
    required String reason,
  }) async {
    return await _apiService.post(
      '/kyc/admin/bulk-reject',
      data: {
        'submission_ids': submissionIds,
        'reason': reason,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get KYC verification history for a user
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getKycHistory({
    required String userId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/kyc/admin/users/$userId/history',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Export KYC submissions data
  Future<ApiResponse<String>> exportKycSubmissions({
    String format = 'csv',
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      if (status != null && status.isNotEmpty) 'status': status,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/kyc/admin/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Get document by ID (for viewing/downloading)
  Future<ApiResponse<Map<String, dynamic>>> getKycDocument(String documentId) async {
    return await _apiService.get(
      '/kyc/admin/documents/$documentId',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update KYC submission status (for manual status changes)
  Future<ApiResponse<Map<String, dynamic>>> updateKycStatus({
    required String submissionId,
    required String status,
    String? remarks,
  }) async {
    return await _apiService.put(
      '/kyc/admin/submissions/$submissionId/status',
      data: {
        'status': status,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
