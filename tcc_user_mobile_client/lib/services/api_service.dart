import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
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
    developer.log('🔧 ApiService: Initializing...', name: 'ApiService');
    developer.log('🔧 ApiService: Base URL: $baseUrl', name: 'ApiService');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.cacheKeyToken);
    _refreshToken = prefs.getString(AppConstants.cacheKeyRefreshToken);
    developer.log('🔧 ApiService: Token exists: ${_token != null}, RefreshToken exists: ${_refreshToken != null}', name: 'ApiService');
    if (_token != null) {
      developer.log('🔧 ApiService: Token preview: ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...', name: 'ApiService');
    }
  }

  // Store tokens
  Future<void> setTokens(String token, String refreshToken) async {
    developer.log('💾 ApiService: Storing tokens', name: 'ApiService');
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyToken, token);
    await prefs.setString(AppConstants.cacheKeyRefreshToken, refreshToken);
    developer.log('💾 ApiService: Tokens stored successfully', name: 'ApiService');
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
      developer.log('📡 ApiService: GET $uri', name: 'ApiService');
      developer.log('📡 ApiService: RequiresAuth: $requiresAuth, HasToken: ${_token != null}', name: 'ApiService');

      final response = await http
          .get(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      developer.log('📡 ApiService: Response status: ${response.statusCode}', name: 'ApiService');
      return _handleResponse(response);
    } on SocketException catch (e) {
      developer.log('❌ ApiService: SocketException: $e', name: 'ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException catch (e) {
      developer.log('❌ ApiService: HttpException: $e', name: 'ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException catch (e) {
      developer.log('❌ ApiService: FormatException: $e', name: 'ApiService');
      throw ApiException('Invalid response format');
    } catch (e) {
      developer.log('❌ ApiService: Exception: $e', name: 'ApiService');
      throw ApiException(e.toString());
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
      developer.log('📡 ApiService: POST $uri', name: 'ApiService');
      developer.log('📡 ApiService: RequiresAuth: $requiresAuth, HasToken: ${_token != null}', name: 'ApiService');
      if (body != null) {
        developer.log('📡 ApiService: Request body: ${body.keys.toList()}', name: 'ApiService');
      }

      final response = await http
          .post(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      developer.log('📡 ApiService: Response status: ${response.statusCode}', name: 'ApiService');
      return _handleResponse(response);
    } on SocketException catch (e) {
      developer.log('❌ ApiService: SocketException: $e', name: 'ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException catch (e) {
      developer.log('❌ ApiService: HttpException: $e', name: 'ApiService');
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException catch (e) {
      developer.log('❌ ApiService: FormatException: $e', name: 'ApiService');
      throw ApiException('Invalid response format');
    } catch (e) {
      developer.log('❌ ApiService: Exception: $e', name: 'ApiService');
      throw ApiException(e.toString());
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
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException(e.toString());
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
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException(e.toString());
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
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException(e.toString());
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
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(AppConstants.errorNetwork);
    } on HttpException {
      throw ApiException(AppConstants.errorNetwork);
    } catch (e) {
      throw ApiException(e.toString());
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
    developer.log('🔍 ApiService: Handling response with status ${response.statusCode}', name: 'ApiService');
    developer.log('🔍 ApiService: Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}', name: 'ApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      developer.log('✅ ApiService: Success response', name: 'ApiService');
      if (response.body.isEmpty) {
        return {'success': true};
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      developer.log('✅ ApiService: Response keys: ${decoded.keys.toList()}', name: 'ApiService');
      return decoded;
    } else if (response.statusCode == 401) {
      developer.log('⚠️ ApiService: 401 Unauthorized', name: 'ApiService');

      // Try to get the error message from response body
      String errorMessage = AppConstants.errorUnauthorized;
      try {
        if (response.body.isNotEmpty) {
          final body = jsonDecode(response.body);

          // Try different error formats
          if (body['error'] != null && body['error'] is Map) {
            // Format: { error: { message: "..." } }
            final errorObj = body['error'] as Map<String, dynamic>;
            errorMessage = errorObj['message'] ?? errorMessage;
          } else if (body['error'] != null && body['error'] is String) {
            // Format: { error: "..." }
            errorMessage = body['error'];
          } else if (body['message'] != null) {
            // Format: { message: "..." }
            errorMessage = body['message'];
          }

          developer.log('⚠️ ApiService: 401 Error message: $errorMessage', name: 'ApiService');
        }
      } catch (e) {
        developer.log('⚠️ ApiService: Could not parse 401 error body: $e', name: 'ApiService');
      }

      // Only clear tokens if this is for an authenticated request
      // Don't clear tokens on login failure
      if (_token != null) {
        developer.log('⚠️ ApiService: Clearing tokens due to 401', name: 'ApiService');
        clearTokens();
      }

      throw UnauthorizedException(errorMessage);
    } else if (response.statusCode == 403) {
      developer.log('⚠️ ApiService: 403 Forbidden', name: 'ApiService');
      throw ApiException('Access forbidden');
    } else if (response.statusCode == 404) {
      developer.log('⚠️ ApiService: 404 Not Found', name: 'ApiService');
      throw ApiException('Resource not found');
    } else if (response.statusCode == 422) {
      developer.log('⚠️ ApiService: 422 Validation Error', name: 'ApiService');
      developer.log('⚠️ ApiService: Response body: ${response.body}', name: 'ApiService');
      // Validation error
      try {
        final body = jsonDecode(response.body);

        // Try different error response formats
        String errorMessage = 'Validation failed';
        Map<String, dynamic>? errors;

        // Format 1: Standard { message, errors }
        if (body['message'] != null) {
          errorMessage = body['message'];
        }

        // Format 2: Nested error object { error: { message, details } }
        if (body['error'] != null && body['error'] is Map) {
          final errorObj = body['error'] as Map<String, dynamic>;
          if (errorObj['message'] != null) {
            errorMessage = errorObj['message'];
          }

          // Check for details array
          if (errorObj['details'] != null && errorObj['details'] is List) {
            final details = errorObj['details'] as List;
            if (details.isNotEmpty) {
              // Extract first error message
              final firstDetail = details.first;
              if (firstDetail is Map && firstDetail['message'] != null) {
                errorMessage = firstDetail['message'].toString();
              }

              // Build error map for display
              errors = {};
              for (var detail in details) {
                if (detail is Map && detail['path'] != null && detail['message'] != null) {
                  final path = detail['path'].toString().split('.').last;
                  errors[path] = detail['message'];
                }
              }
            }
          }
        }

        // Format 3: Direct errors object
        if (body['errors'] != null && body['errors'] is Map) {
          errors = body['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            } else if (firstError is String) {
              errorMessage = firstError;
            }
          }
        }

        developer.log('⚠️ ApiService: Parsed validation message: $errorMessage', name: 'ApiService');
        developer.log('⚠️ ApiService: Parsed validation errors: $errors', name: 'ApiService');

        throw ValidationException(errorMessage, errors);
      } catch (e) {
        if (e is ValidationException) rethrow;
        developer.log('⚠️ ApiService: Failed to parse validation error: $e', name: 'ApiService');
        throw ValidationException('Invalid input. Please check your information.');
      }
    } else if (response.statusCode >= 500) {
      developer.log('❌ ApiService: ${response.statusCode} Server Error', name: 'ApiService');
      throw ApiException('Server error. Please try again later.');
    } else {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'message': 'Unknown error'};
      developer.log('❌ ApiService: ${response.statusCode} Error: ${body['message']}', name: 'ApiService');
      throw ApiException(body['message'] ?? AppConstants.errorGeneric);
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
