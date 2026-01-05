import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = AppConstants.baseUrl;
  String? _token;
  String? _refreshToken;

  // Getters for token access
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  // Initialize with stored tokens
  Future<void> initialize() async {
    developer.log(
      '🌐 [API_SERVICE] Initializing API Service:\n'
      '  Base URL: $baseUrl',
      name: 'TCC.ApiService',
    );
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.cacheKeyToken);
    _refreshToken = prefs.getString(AppConstants.cacheKeyRefreshToken);
    developer.log(
      '✅ [API_SERVICE] Initialized - Token exists: ${_token != null}',
      name: 'TCC.ApiService',
    );
  }

  // Store tokens
  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyToken, token);
    await prefs.setString(AppConstants.cacheKeyRefreshToken, refreshToken);
  }

  // Clear tokens
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.cacheKeyToken);
    await prefs.remove(AppConstants.cacheKeyRefreshToken);
  }

  // Get headers
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      developer.log(
        '📡 [API_SERVICE] GET Request:\n'
        '  URL: $uri\n'
        '  Auth: $requiresAuth',
        name: 'TCC.ApiService',
      );

      final response = await http
          .get(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw TimeoutException(
                AppConstants.errorTimeout,
                Duration(seconds: AppConstants.apiTimeout),
              );
            },
          );

      developer.log(
        '✅ [API_SERVICE] Response received: ${response.statusCode}',
        name: 'TCC.ApiService',
      );
      return _handleResponse(response);
    } on TimeoutException {
      developer.log('❌ [API_SERVICE] Request timeout', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorTimeout);
    } on SocketException catch (e) {
      developer.log('❌ [API_SERVICE] Network error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException catch (e) {
      developer.log('❌ [API_SERVICE] HTTP error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException catch (e) {
      developer.log('❌ [API_SERVICE] Format error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException('Invalid response format. Please try again.');
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      developer.log('❌ [API_SERVICE] Unknown error: ${e.toString()}', name: 'TCC.ApiService');
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log(
        '📡 [API_SERVICE] POST Request:\n'
        '  URL: $uri\n'
        '  Auth: $requiresAuth\n'
        '  Body keys: ${body?.keys.join(", ") ?? "none"}',
        name: 'TCC.ApiService',
      );

      final response = await http
          .post(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw TimeoutException(
                AppConstants.errorTimeout,
                Duration(seconds: AppConstants.apiTimeout),
              );
            },
          );

      developer.log(
        '✅ [API_SERVICE] Response received: ${response.statusCode}',
        name: 'TCC.ApiService',
      );
      return _handleResponse(response);
    } on TimeoutException {
      developer.log('❌ [API_SERVICE] Request timeout', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorTimeout);
    } on SocketException catch (e) {
      developer.log('❌ [API_SERVICE] Network error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException catch (e) {
      developer.log('❌ [API_SERVICE] HTTP error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException catch (e) {
      developer.log('❌ [API_SERVICE] Format error: ${e.message}', name: 'TCC.ApiService');
      throw ApiException('Invalid response format. Please try again.');
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      developer.log('❌ [API_SERVICE] Unknown error: ${e.toString()}', name: 'TCC.ApiService');
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .put(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw TimeoutException(
                AppConstants.errorTimeout,
                Duration(seconds: AppConstants.apiTimeout),
              );
            },
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(AppConstants.errorTimeout);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format. Please try again.');
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw TimeoutException(
                AppConstants.errorTimeout,
                Duration(seconds: AppConstants.apiTimeout),
              );
            },
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(AppConstants.errorTimeout);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format. Please try again.');
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .delete(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw TimeoutException(
                AppConstants.errorTimeout,
                Duration(seconds: AppConstants.apiTimeout),
              );
            },
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(AppConstants.errorTimeout);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format. Please try again.');
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Upload file with multipart
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
            Duration(seconds: AppConstants.imageUploadTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Upload timeout. Please try again.',
                Duration(seconds: AppConstants.imageUploadTimeout),
              );
            },
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Upload timeout. Please check your connection and try again.');
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on ApiException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload failed: ${e.toString()}');
    }
  }

  // Build URI
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final url = '$baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }
    return Uri.parse(url);
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {'success': true};
        }

        // Decode the response
        final decoded = jsonDecode(response.body);
        developer.log(
          '📦 [API_SERVICE] Response body type: ${decoded.runtimeType}',
          name: 'TCC.ApiService',
        );

        // If it's already a Map, return it
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        // If it's a List, wrap it in a Map
        if (decoded is List) {
          developer.log(
            '⚠️ [API_SERVICE] Response is a List, wrapping in Map',
            name: 'TCC.ApiService',
          );
          return {
            'success': true,
            'data': decoded,
          };
        }

        // For other types, try to wrap in a Map
        return {
          'success': true,
          'data': decoded,
        };
      } else if (response.statusCode == 400) {
        // Bad Request
        final body = _parseResponseBody(response.body);
        throw ApiException(_extractErrorMessage(body) ?? 'Invalid request. Please check your input.');
      } else if (response.statusCode == 401) {
        // Unauthorized - token expired or invalid credentials
        clearTokens();
        final body = _parseResponseBody(response.body);
        throw UnauthorizedException(
          _extractErrorMessage(body) ?? AppConstants.errorUnauthorized,
        );
      } else if (response.statusCode == 403) {
        // Forbidden
        final body = _parseResponseBody(response.body);
        throw ApiException(
          _extractErrorMessage(body) ?? 'Access forbidden. You do not have permission to perform this action.',
        );
      } else if (response.statusCode == 404) {
        // Not Found
        final body = _parseResponseBody(response.body);
        throw ApiException(
          _extractErrorMessage(body) ?? 'Resource not found. Please try again.',
        );
      } else if (response.statusCode == 409) {
        // Conflict - duplicate entry
        final body = _parseResponseBody(response.body);
        throw ApiException(
          _extractErrorMessage(body) ?? 'This record already exists.',
        );
      } else if (response.statusCode == 422) {
        // Validation error
        final body = _parseResponseBody(response.body);
        throw ValidationException(
          _extractErrorMessage(body) ?? 'Validation failed',
          body['errors'] ?? (body['error'] != null ? body['error']['details'] : null),
        );
      } else if (response.statusCode == 429) {
        // Too Many Requests
        final body = _parseResponseBody(response.body);
        throw ApiException(
          _extractErrorMessage(body) ?? 'Too many requests. Please try again later.',
        );
      } else if (response.statusCode >= 500) {
        // Server Error
        final body = _parseResponseBody(response.body);
        throw ApiException(
          _extractErrorMessage(body) ?? 'Server error. Please try again later.',
        );
      } else {
        // Other errors
        final body = _parseResponseBody(response.body);
        throw ApiException(_extractErrorMessage(body) ?? AppConstants.errorGeneric);
      }
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException || e is ValidationException) {
        rethrow;
      }
      throw ApiException('Error processing response: ${e.toString()}');
    }
  }

  // Extract error message from response body
  // Handles both formats: {message: "..."} and {error: {message: "..."}}
  String? _extractErrorMessage(Map<String, dynamic> body) {
    // First, check if there's a nested error object with a message
    if (body['error'] != null && body['error'] is Map) {
      final errorObj = body['error'] as Map<String, dynamic>;
      if (errorObj['message'] != null && errorObj['message'] is String) {
        return errorObj['message'] as String;
      }
    }

    // Otherwise, check for direct message field
    if (body['message'] != null && body['message'] is String) {
      return body['message'] as String;
    }

    return null;
  }

  // Parse response body safely
  Map<String, dynamic> _parseResponseBody(String body) {
    try {
      if (body.isEmpty) {
        return {'message': 'Unknown error'};
      }

      final decoded = jsonDecode(body);

      // If it's already a Map, return it
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      // If it's a List, wrap it in a Map
      if (decoded is List) {
        return {
          'message': 'Validation errors',
          'errors': decoded,
        };
      }

      // For other types
      return {'message': decoded.toString()};
    } catch (e) {
      return {'message': body.isNotEmpty ? body : 'Unknown error'};
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException(this.message, [this.errors]);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return '$message: ${errors.toString()}';
    }
    return message;
  }
}
