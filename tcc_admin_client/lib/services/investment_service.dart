import '../models/api_response_model.dart';
import '../models/investment_model.dart';
import 'api_service.dart';

/// Investment Service
/// Handles all investment-related API calls for admin
class InvestmentService {
  final ApiService _apiService = ApiService();

  /// Get all investments with pagination and filters (Admin endpoint)
  Future<ApiResponse<PaginatedResponse<InvestmentModel>>> getInvestments({
    int page = 1,
    int limit = 25,
    String? search,
    String? category,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (status != null && status.isNotEmpty) 'status': status,
      if (fromDate != null) 'from_date': fromDate.toIso8601String(),
      if (toDate != null) 'to_date': toDate.toIso8601String(),
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/investments',
      queryParameters: queryParameters,
    );

    // Transform the response to PaginatedResponse
    if (response.success && response.data != null && response.meta != null) {
      try {
        final responseData = response.data!;
        final investments = (responseData['investments'] as List<dynamic>)
            .map((e) => InvestmentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<InvestmentModel>(
            data: investments,
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
          message: 'Failed to parse investments response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load investments',
    );
  }

  /// Get investment by ID
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentById(String investmentId) async {
    return await _apiService.get(
      '/investments/$investmentId',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get all investment categories
  Future<ApiResponse<List<Map<String, dynamic>>>> getInvestmentCategories() async {
    return await _apiService.get(
      '/investments/categories',
      fromJson: (data) {
        final categories = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return categories;
      },
    );
  }

  /// Create new investment category (admin only)
  Future<ApiResponse<Map<String, dynamic>>> createInvestmentCategory({
    required String name,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return await _apiService.post(
      '/investments/categories',
      data: {
        'name': name,
        'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (metadata != null) 'metadata': metadata,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update investment category (admin only)
  Future<ApiResponse<Map<String, dynamic>>> updateInvestmentCategory({
    required String categoryId,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    return await _apiService.put(
      '/investments/categories/$categoryId',
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (isActive != null) 'is_active': isActive,
        if (metadata != null) 'metadata': metadata,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Delete investment category (admin only)
  Future<ApiResponse<void>> deleteInvestmentCategory(String categoryId) async {
    return await _apiService.delete(
      '/investments/categories/$categoryId',
    );
  }

  /// Get all investment opportunities (products)
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getInvestmentOpportunities({
    int page = 1,
    int perPage = 25,
    String? category,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (category != null && category.isNotEmpty) 'category': category,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    final response = await _apiService.get(
      '/investments/opportunities',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Create new investment opportunity (admin only)
  Future<ApiResponse<Map<String, dynamic>>> createInvestmentOpportunity({
    required String categoryId,
    required String title,
    required String description,
    required double minInvestment,
    required double maxInvestment,
    required int tenureMonths,
    required double returnRate,
    required int totalUnits,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return await _apiService.post(
      '/investments/opportunities',
      data: {
        'category_id': categoryId,
        'title': title,
        'description': description,
        'min_investment': minInvestment,
        'max_investment': maxInvestment,
        'tenure_months': tenureMonths,
        'return_rate': returnRate,
        'total_units': totalUnits,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (metadata != null) 'metadata': metadata,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update investment opportunity (admin only)
  Future<ApiResponse<Map<String, dynamic>>> updateInvestmentOpportunity({
    required String opportunityId,
    String? title,
    String? description,
    double? minInvestment,
    double? maxInvestment,
    int? tenureMonths,
    double? returnRate,
    int? totalUnits,
    String? status,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return await _apiService.put(
      '/investments/opportunities/$opportunityId',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        if (minInvestment != null) 'min_investment': minInvestment,
        if (maxInvestment != null) 'max_investment': maxInvestment,
        if (tenureMonths != null) 'tenure_months': tenureMonths,
        if (returnRate != null) 'return_rate': returnRate,
        if (totalUnits != null) 'total_units': totalUnits,
        if (status != null && status.isNotEmpty) 'status': status,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (metadata != null) 'metadata': metadata,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Delete investment opportunity (admin only)
  Future<ApiResponse<void>> deleteInvestmentOpportunity(String opportunityId) async {
    return await _apiService.delete(
      '/investments/opportunities/$opportunityId',
    );
  }

  /// Get investment statistics
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentStats() async {
    return await _apiService.get(
      '/investments/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get investment performance metrics
  Future<ApiResponse<Map<String, dynamic>>> getInvestmentPerformance({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/investments/performance',
      queryParameters: queryParameters,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get user investments (all investments by a specific user)
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getUserInvestments({
    required String userId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/investments/users/$userId',
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

  /// Export investments data
  Future<ApiResponse<String>> exportInvestments({
    String format = 'csv',
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      if (category != null && category.isNotEmpty) 'category': category,
      if (status != null && status.isNotEmpty) 'status': status,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _apiService.get(
      '/investments/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Process investment maturity (admin only)
  Future<ApiResponse<Map<String, dynamic>>> processInvestmentMaturity({
    required String investmentId,
    required double returnAmount,
    String? remarks,
  }) async {
    return await _apiService.post(
      '/investments/$investmentId/mature',
      data: {
        'return_amount': returnAmount,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Cancel investment (admin only)
  Future<ApiResponse<Map<String, dynamic>>> cancelInvestment({
    required String investmentId,
    required String reason,
  }) async {
    return await _apiService.post(
      '/investments/$investmentId/cancel',
      data: {
        'reason': reason,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
