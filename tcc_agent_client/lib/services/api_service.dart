import 'dart:convert';
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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.cacheKeyToken);
    _refreshToken = prefs.getString(AppConstants.cacheKeyRefreshToken);
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
      final response = await http
          .get(
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

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .post(
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
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // Unauthorized - token expired
      clearTokens();
      throw UnauthorizedException(AppConstants.errorUnauthorized);
    } else if (response.statusCode == 403) {
      throw ApiException('Access forbidden');
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found');
    } else if (response.statusCode == 422) {
      // Validation error
      final body = jsonDecode(response.body);
      throw ValidationException(
        body['message'] ?? 'Validation failed',
        body['errors'],
      );
    } else if (response.statusCode >= 500) {
      throw ApiException('Server error. Please try again later.');
    } else {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'message': 'Unknown error'};
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
