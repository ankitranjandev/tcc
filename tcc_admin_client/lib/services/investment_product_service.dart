import '../models/api_response_model.dart';
import '../models/investment_category_model.dart';
import '../models/product_version_model.dart';
import '../models/rate_change_model.dart';
import '../models/version_report_model.dart';
import 'api_service.dart';

/// Investment Product Service
/// Handles all investment product management API calls (versioning, categories, tenures, units)
class InvestmentProductService {
  final ApiService _apiService = ApiService();

  // =====================================================
  // CATEGORY MANAGEMENT
  // =====================================================

  /// Get all investment categories with version information
  Future<ApiResponse<List<InvestmentCategoryWithVersionsModel>>>
      getCategories() async {
    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/categories',
    );

    if (response.success && response.data != null) {
      try {
        final categories = (response.data as List<dynamic>)
            .map((e) => InvestmentCategoryWithVersionsModel.fromJson(
                e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: categories,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse categories response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load categories',
    );
  }

  /// Create a new investment category
  Future<ApiResponse<InvestmentCategoryModel>> createCategory({
    required String name,
    required String displayName,
    String? description,
    List<String>? subCategories,
    String? iconUrl,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/admin/investment-products/categories',
      data: {
        'name': name,
        'display_name': displayName,
        if (description != null) 'description': description,
        if (subCategories != null) 'sub_categories': subCategories,
        if (iconUrl != null) 'icon_url': iconUrl,
      },
    );

    if (response.success && response.data != null) {
      try {
        final category =
            InvestmentCategoryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: category,
          message: response.message ?? 'Category created successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse category response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to create category',
    );
  }

  /// Update an investment category
  Future<ApiResponse<InvestmentCategoryModel>> updateCategory({
    required String categoryId,
    String? displayName,
    String? description,
    List<String>? subCategories,
    String? iconUrl,
    bool? isActive,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/admin/investment-products/categories/$categoryId',
      data: {
        if (displayName != null) 'display_name': displayName,
        if (description != null) 'description': description,
        if (subCategories != null) 'sub_categories': subCategories,
        if (iconUrl != null) 'icon_url': iconUrl,
        if (isActive != null) 'is_active': isActive,
      },
    );

    if (response.success && response.data != null) {
      try {
        final category =
            InvestmentCategoryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: category,
          message: response.message ?? 'Category updated successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse category response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to update category',
    );
  }

  /// Deactivate an investment category
  Future<ApiResponse<void>> deactivateCategory(String categoryId) async {
    final response = await _apiService.delete<void>(
      '/admin/investment-products/categories/$categoryId',
    );

    if (response.success) {
      return ApiResponse.success(
        message: response.message ?? 'Category deactivated successfully',
      );
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to deactivate category',
    );
  }

  // =====================================================
  // TENURE MANAGEMENT WITH VERSIONING
  // =====================================================

  /// Get all tenures for a category
  Future<ApiResponse<List<TenureWithVersionHistoryModel>>> getTenures(
      String categoryId) async {
    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/categories/$categoryId/tenures',
    );

    if (response.success && response.data != null) {
      try {
        final tenures = (response.data as List<dynamic>)
            .map((e) => TenureWithVersionHistoryModel.fromJson(
                e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: tenures,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse tenures response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load tenures',
    );
  }

  /// Create a new investment tenure
  Future<ApiResponse<InvestmentTenureModel>> createTenure({
    required String categoryId,
    required int durationMonths,
    required double returnPercentage,
    String? agreementTemplateUrl,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/admin/investment-products/categories/$categoryId/tenures',
      data: {
        'duration_months': durationMonths,
        'return_percentage': returnPercentage,
        if (agreementTemplateUrl != null)
          'agreement_template_url': agreementTemplateUrl,
      },
    );

    if (response.success && response.data != null) {
      try {
        final tenure =
            InvestmentTenureModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: tenure,
          message: response.message ?? 'Tenure created successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse tenure response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to create tenure',
    );
  }

  /// Update tenure rate - creates a new version
  Future<ApiResponse<ProductVersionModel>> updateTenureRate({
    required String tenureId,
    required double newRate,
    required String changeReason,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/admin/investment-products/tenures/$tenureId/rate',
      data: {
        'new_rate': newRate,
        'change_reason': changeReason,
      },
    );

    if (response.success && response.data != null) {
      try {
        final version =
            ProductVersionModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: version,
          message: response.message ??
              'Rate updated successfully. Users have been notified.',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse version response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to update rate',
    );
  }

  /// Get version history for a tenure
  Future<ApiResponse<List<ProductVersionModel>>> getTenureVersionHistory(
      String tenureId) async {
    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/tenures/$tenureId/versions',
    );

    if (response.success && response.data != null) {
      try {
        final versions = (response.data as List<dynamic>)
            .map((e) => ProductVersionModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: versions,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse versions response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load version history',
    );
  }

  // =====================================================
  // UNIT MANAGEMENT
  // =====================================================

  /// Get investment units for a category
  Future<ApiResponse<List<InvestmentUnitModel>>> getUnits(
      String categoryId) async {
    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/categories/$categoryId/units',
    );

    if (response.success && response.data != null) {
      try {
        final units = (response.data as List<dynamic>)
            .map(
                (e) => InvestmentUnitModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: units,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse units response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load units',
    );
  }

  /// Create a new investment unit
  Future<ApiResponse<InvestmentUnitModel>> createUnit({
    required String category,
    required String unitName,
    required double unitPrice,
    String? description,
    String? iconUrl,
    int? displayOrder,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/admin/investment-products/units',
      data: {
        'category': category,
        'unit_name': unitName,
        'unit_price': unitPrice,
        if (description != null) 'description': description,
        if (iconUrl != null) 'icon_url': iconUrl,
        if (displayOrder != null) 'display_order': displayOrder,
      },
    );

    if (response.success && response.data != null) {
      try {
        final unit =
            InvestmentUnitModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: unit,
          message: response.message ?? 'Unit created successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse unit response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to create unit',
    );
  }

  /// Update an investment unit
  Future<ApiResponse<InvestmentUnitModel>> updateUnit({
    required String unitId,
    String? unitName,
    double? unitPrice,
    String? description,
    String? iconUrl,
    int? displayOrder,
    bool? isActive,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/admin/investment-products/units/$unitId',
      data: {
        if (unitName != null) 'unit_name': unitName,
        if (unitPrice != null) 'unit_price': unitPrice,
        if (description != null) 'description': description,
        if (iconUrl != null) 'icon_url': iconUrl,
        if (displayOrder != null) 'display_order': displayOrder,
        if (isActive != null) 'is_active': isActive,
      },
    );

    if (response.success && response.data != null) {
      try {
        final unit =
            InvestmentUnitModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: unit,
          message: response.message ?? 'Unit updated successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse unit response: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to update unit',
    );
  }

  /// Delete an investment unit
  Future<ApiResponse<void>> deleteUnit(String unitId) async {
    final response = await _apiService.delete<void>(
      '/admin/investment-products/units/$unitId',
    );

    if (response.success) {
      return ApiResponse.success(
        message: response.message ?? 'Unit deleted successfully',
      );
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to delete unit',
    );
  }

  // =====================================================
  // REPORTS AND HISTORY
  // =====================================================

  /// Get rate change history
  Future<ApiResponse<List<RateChangeHistoryModel>>> getRateChangeHistory({
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? adminId,
  }) async {
    final queryParameters = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (fromDate != null) 'from_date': fromDate.toIso8601String(),
      if (toDate != null) 'to_date': toDate.toIso8601String(),
      if (adminId != null && adminId.isNotEmpty) 'admin_id': adminId,
    };

    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/rate-changes/history',
      queryParameters: queryParameters,
    );

    if (response.success && response.data != null) {
      try {
        final history = (response.data as List<dynamic>)
            .map((e) =>
                RateChangeHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: history,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse rate change history: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message:
          response.error?.message ?? 'Failed to load rate change history',
    );
  }

  /// Get version-based report
  Future<ApiResponse<List<VersionReportModel>>> getVersionReport({
    String? category,
    String? tenureId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (tenureId != null && tenureId.isNotEmpty) 'tenure_id': tenureId,
      if (fromDate != null) 'from_date': fromDate.toIso8601String(),
      if (toDate != null) 'to_date': toDate.toIso8601String(),
    };

    final response = await _apiService.get<List<dynamic>>(
      '/admin/investment-products/versions/report',
      queryParameters: queryParameters,
    );

    if (response.success && response.data != null) {
      try {
        final reports = (response.data as List<dynamic>)
            .map((e) => VersionReportModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: reports,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse version report: ${e.toString()}',
        );
      }
    }

    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load version report',
    );
  }
}
