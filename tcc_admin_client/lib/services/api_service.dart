import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import 'storage_service.dart';
import 'navigation_service.dart';
import '../widgets/dialogs/session_expired_dialog.dart';

/// API Service
/// Handles all HTTP requests to the backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final StorageService _storage = StorageService();
  final NavigationService _navigation = NavigationService();

  // Track if session expired dialog is already showing
  bool _isSessionExpiredDialogShowing = false;

  // Track token refresh to prevent concurrent refresh attempts
  bool _isRefreshing = false;
  final List<void Function()> _refreshCallbacks = [];

  ApiService._internal() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  /// Base URL - For demo purposes
  static String get baseUrl {
    // For demo, using localhost. In production, this would be from environment config
    return 'http://localhost:3000/v1';
  }

  /// Base options for Dio
  BaseOptions get _baseOptions => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  /// Setup interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to all requests
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request in debug mode
          debugPrint('REQUEST[${options.method}] => ${options.uri}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response in debug mode
          debugPrint('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log error in debug mode
          debugPrint('ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');

          final statusCode = error.response?.statusCode;

          // Handle 401 Unauthorized or 403 Forbidden
          if (statusCode == 401 || statusCode == 403) {
            // Try to refresh token for 401 only
            if (statusCode == 401) {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the request
                return handler.resolve(await _retry(error.requestOptions));
              }
            }

            // Token refresh failed or it's a 403 error
            // Show session expired dialog and logout
            await _handleSessionExpired(statusCode == 401 ? 'unauthorized' : 'forbidden');
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    // If already refreshing, wait for the current refresh to complete
    if (_isRefreshing) {
      // Create a completer to wait for refresh completion
      final completer = Completer<bool>();
      _refreshCallbacks.add(() {
        completer.complete(true);
      });
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        _notifyRefreshCallbacks(false);
        return false;
      }

      debugPrint('Attempting to refresh token...');

      // Create a new Dio instance to avoid interceptor loops
      final refreshDio = Dio(_baseOptions);

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response structures
        String? accessToken;
        String? newRefreshToken;

        // Try to get tokens from data object
        if (data['data'] != null) {
          accessToken = data['data']['access_token'] ?? data['data']['accessToken'];
          newRefreshToken = data['data']['refresh_token'] ?? data['data']['refreshToken'];
        } else {
          // Tokens might be at root level
          accessToken = data['access_token'] ?? data['accessToken'];
          newRefreshToken = data['refresh_token'] ?? data['refreshToken'];
        }

        if (accessToken != null) {
          await _storage.saveAccessToken(accessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }

          debugPrint('Token refresh successful');
          _isRefreshing = false;
          _notifyRefreshCallbacks(true);
          return true;
        }
      }

      debugPrint('Token refresh failed: Invalid response format');
      _isRefreshing = false;
      _notifyRefreshCallbacks(false);
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      _isRefreshing = false;
      _notifyRefreshCallbacks(false);
      return false;
    }
  }

  /// Notify all waiting callbacks about refresh completion
  void _notifyRefreshCallbacks(bool success) {
    for (var callback in _refreshCallbacks) {
      callback();
    }
    _refreshCallbacks.clear();
  }

  /// Retry failed request
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    // Get the new access token
    final token = await _storage.getAccessToken();

    // Update the authorization header with the new token
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final options = Options(
      method: requestOptions.method,
      headers: headers,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Handle session expired
  Future<void> _handleSessionExpired(String reason) async {
    // Prevent multiple dialogs
    if (_isSessionExpiredDialogShowing) return;
    _isSessionExpiredDialogShowing = true;

    // Clear storage
    await _storage.clearAll();

    // Show session expired dialog
    final context = _navigation.context;
    if (context != null && context.mounted) {
      final message = reason == 'unauthorized'
          ? 'Your session has expired. Please login again to continue.'
          : 'Access denied. Your authentication token is invalid. Please login again.';

      await SessionExpiredDialog.show(context, message: message);
    }

    _isSessionExpiredDialogShowing = false;
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(message: 'An unexpected error occurred: $e');
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(message: 'An unexpected error occurred: $e');
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(message: 'An unexpected error occurred: $e');
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(message: 'An unexpected error occurred: $e');
    }
  }

  /// Handle Dio errors
  ApiResponse<T> _handleDioError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['error']?['message'] ??
            error.response?.data?['message'] ??
            'An error occurred';

        return ApiResponse.error(
          message: message,
          code: 'HTTP_$statusCode',
        );

      case DioExceptionType.cancel:
        return ApiResponse.error(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
      default:
        return ApiResponse.error(
          message: 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
        );
    }
  }

  /// Upload file (multipart)
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
      );

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(message: 'File upload failed: $e');
    }
  }

  /// Download file
  Future<bool> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );
      return true;
    } catch (e) {
      debugPrint('Download error: $e');
      return false;
    }
  }
}
