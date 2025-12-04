/// API Response Model
/// Standardizes all API responses from the backend
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.meta,
  });

  /// Create successful response
  factory ApiResponse.success({
    T? data,
    String? message,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      meta: meta,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) {
    return ApiResponse(
      success: false,
      error: ApiError(
        message: message,
        code: code,
        details: details,
      ),
    );
  }

  /// Create ApiResponse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    if (json['success'] == true) {
      return ApiResponse.success(
        data: fromJsonT != null && json['data'] != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
        message: json['message'] as String?,
        meta: json['meta'] as Map<String, dynamic>?,
      );
    } else {
      return ApiResponse.error(
        message: json['error']?['message'] as String? ?? 'An error occurred',
        code: json['error']?['code'] as String?,
        details: json['error']?['details'] as Map<String, dynamic>?,
      );
    }
  }

  /// Convert ApiResponse to JSON
  Map<String, dynamic> toJson() {
    if (success) {
      return {
        'success': success,
        'data': data,
        'message': message,
        'meta': meta,
      };
    } else {
      return {
        'success': success,
        'error': error?.toJson(),
      };
    }
  }
}

/// API Error Model
class ApiError {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  ApiError({
    required this.message,
    this.code,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'details': details,
    };
  }
}

/// Paginated Response Model
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      perPage: json['per_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
