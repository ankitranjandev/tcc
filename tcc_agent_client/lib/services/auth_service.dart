import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/agent_model.dart';
import '../config/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login (supports both agent and admin login)
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
    bool isAdminLogin = false,
  }) async {
    developer.log(
      '🔐 [AUTH_SERVICE] Login attempt:\n'
      '  Email/Phone: $emailOrPhone\n'
      '  isAdminLogin: $isAdminLogin\n'
      '  isDemoMode: ${AppConstants.isDemoMode}',
      name: 'TCC.AuthService',
    );

    // Demo Mode - bypass API call
    if (AppConstants.isDemoMode && !isAdminLogin) {
      developer.log('🎭 [AUTH_SERVICE] Using demo mode', name: 'TCC.AuthService');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      // Create mock agent with verified status
      final mockAgent = AgentModel(
        id: 'demo-agent-001',
        firstName: 'Demo',
        lastName: 'Agent',
        email: 'demo@tccagent.com',
        mobileNumber: '+23276123456',
        profilePictureUrl: null,
        status: 'active', // Set to 'active' so user can access dashboard
        walletBalance: 5000000.0, // 5 million TCC
        commissionRate: 2.5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        verifiedAt: DateTime.now().subtract(const Duration(days: 29)),
        lastActiveAt: DateTime.now(),
        bankDetails: AgentBankDetails(
          bankName: 'Sierra Leone Commercial Bank',
          branchAddress: 'Freetown Main Branch',
          ifscCode: 'SLCB0001234',
          accountHolderName: 'Demo Agent',
          accountNumber: '****1234',
        ),
      );

      const mockToken = 'demo_token_12345';
      const mockRefreshToken = 'demo_refresh_token_12345';

      await _apiService.setTokens(mockToken, mockRefreshToken);

      return AuthResult(
        success: true,
        agent: mockAgent,
        token: mockToken,
      );
    }

    // Real API Mode
    try {
      // Validate inputs
      if (emailOrPhone.isEmpty) {
        return AuthResult(
          success: false,
          error: isAdminLogin ? 'Email is required' : 'Email or phone number is required',
        );
      }

      if (password.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Password is required',
        );
      }

      // Determine endpoint based on login type
      final endpoint = isAdminLogin
          ? AppConstants.adminLoginEndpoint
          : AppConstants.loginEndpoint;

      // Prepare request body based on login type
      final body = isAdminLogin
          ? {
              'email': emailOrPhone,
              'password': password,
            }
          : {
              'email_or_phone': emailOrPhone,
              'password': password,
            };

      final response = await _apiService.post(
        endpoint,
        body: body,
        requiresAuth: false,
      );

      // Extract data from response (server sends {success: true, data: {...}})
      final responseData = response['data'] as Map<String, dynamic>?;

      if (responseData == null) {
        return AuthResult(
          success: false,
          error: 'Invalid response from server. Please try again.',
        );
      }

      // Admin login uses 'access_token', regular login uses 'token'
      final token = (responseData['access_token'] ?? responseData['token']) as String?;
      final refreshToken = responseData['refresh_token'] as String?;

      if (token == null || refreshToken == null) {
        return AuthResult(
          success: false,
          error: 'Invalid response from server. Please try again.',
        );
      }

      // Admin login returns 'admin' field, regular login returns 'agent' field
      final userData = responseData['admin'] ?? responseData['user'] ?? responseData['agent'];
      if (userData == null) {
        return AuthResult(
          success: false,
          error: 'Invalid response from server. Please try again.',
        );
      }

      final agent = AgentModel.fromJson(userData);

      await _apiService.setTokens(token, refreshToken);

      developer.log(
        '✅ [AUTH_SERVICE] Login successful:\n'
        '  Agent: ${agent.fullName}\n'
        '  Status: ${agent.status}\n'
        '  ID: ${agent.id}',
        name: 'TCC.AuthService',
      );

      return AuthResult(
        success: true,
        agent: agent,
        token: token,
      );
    } on UnauthorizedException {
      developer.log('❌ [AUTH_SERVICE] Login failed: Unauthorized', name: 'TCC.AuthService');
      return AuthResult(
        success: false,
        error: 'Invalid credentials. Please check your email/phone and password.',
      );
    } on ApiException catch (e) {
      developer.log('❌ [AUTH_SERVICE] Login failed: ApiException - ${e.toString()}', name: 'TCC.AuthService');
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } on ValidationException catch (e) {
      developer.log('❌ [AUTH_SERVICE] Login failed: ValidationException - ${e.toString()}', name: 'TCC.AuthService');
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      developer.log('❌ [AUTH_SERVICE] Login failed: Unknown error - ${e.toString()}', name: 'TCC.AuthService');
      return AuthResult(
        success: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Register
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    String? profilePictureUrl,
  }) async {
    try {
      // Validate inputs
      if (firstName.isEmpty || firstName.length < 2) {
        return AuthResult(
          success: false,
          error: 'First name must be at least 2 characters',
        );
      }

      if (lastName.isEmpty || lastName.length < 2) {
        return AuthResult(
          success: false,
          error: 'Last name must be at least 2 characters',
        );
      }

      if (email.isEmpty || !RegExp(AppConstants.emailPattern).hasMatch(email)) {
        return AuthResult(
          success: false,
          error: 'Please enter a valid email address',
        );
      }

      if (mobileNumber.isEmpty || mobileNumber.length < 8) {
        return AuthResult(
          success: false,
          error: 'Please enter a valid mobile number',
        );
      }

      if (password.isEmpty || password.length < AppConstants.minPasswordLength) {
        return AuthResult(
          success: false,
          error: 'Password must be at least ${AppConstants.minPasswordLength} characters',
        );
      }

      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'mobile_number': mobileNumber,
          'password': password,
          if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
        },
        requiresAuth: false,
      );

      // Extract message from response
      final message = response['message'] as String?;

      return AuthResult(
        success: true,
        message: message ?? AppConstants.successRegistration,
        otpRequired: true,
      );
    } on ApiException catch (e) {
      // Check for specific error messages
      final errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('email') && errorMsg.toLowerCase().contains('exist')) {
        return AuthResult(
          success: false,
          error: 'This email is already registered. Please use a different email or login.',
        );
      } else if (errorMsg.toLowerCase().contains('mobile') && errorMsg.toLowerCase().contains('exist')) {
        return AuthResult(
          success: false,
          error: 'This mobile number is already registered. Please use a different number or login.',
        );
      }
      return AuthResult(
        success: false,
        error: errorMsg,
      );
    } on ValidationException catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Verify OTP
  Future<AuthResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      // Validate inputs
      if (mobileNumber.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Mobile number is required',
        );
      }

      if (otp.isEmpty || otp.length != AppConstants.otpLength) {
        return AuthResult(
          success: false,
          error: 'Please enter a valid ${AppConstants.otpLength}-digit OTP',
        );
      }

      final response = await _apiService.post(
        AppConstants.verifyOtpEndpoint,
        body: {
          'mobile_number': mobileNumber,
          'otp': otp,
        },
        requiresAuth: false,
      );

      // Extract data from response
      final responseData = response['data'] as Map<String, dynamic>?;

      if (responseData != null) {
        final token = (responseData['access_token'] ?? responseData['token']) as String?;
        final refreshToken = responseData['refresh_token'] as String?;

        if (token != null && refreshToken != null) {
          final userData = responseData['user'] ?? responseData['agent'];
          if (userData != null) {
            final agent = AgentModel.fromJson(userData);
            await _apiService.setTokens(token, refreshToken);

            return AuthResult(
              success: true,
              agent: agent,
              token: token,
            );
          }
        }
      }

      final message = response['message'] as String?;
      return AuthResult(
        success: true,
        message: message ?? 'OTP verified successfully',
      );
    } on ApiException catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('invalid') || errorMsg.toLowerCase().contains('incorrect')) {
        return AuthResult(
          success: false,
          error: 'Invalid OTP. Please check and try again.',
        );
      } else if (errorMsg.toLowerCase().contains('expired')) {
        return AuthResult(
          success: false,
          error: 'OTP has expired. Please request a new one.',
        );
      }
      return AuthResult(
        success: false,
        error: errorMsg,
      );
    } on ValidationException catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'OTP verification failed: ${e.toString()}',
      );
    }
  }

  // Resend OTP
  Future<AuthResult> resendOtp({
    required String mobileNumber,
  }) async {
    try {
      if (mobileNumber.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Mobile number is required',
        );
      }

      final response = await _apiService.post(
        AppConstants.resendOtpEndpoint,
        body: {
          'mobile_number': mobileNumber,
        },
        requiresAuth: false,
      );

      final message = response['message'] as String?;
      return AuthResult(
        success: true,
        message: message ?? AppConstants.successOtpSent,
      );
    } on ApiException catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('too many')) {
        return AuthResult(
          success: false,
          error: 'Too many OTP requests. Please wait before trying again.',
        );
      }
      return AuthResult(
        success: false,
        error: errorMsg,
      );
    } on ValidationException catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to resend OTP: ${e.toString()}',
      );
    }
  }

  // Upload KYC document
  Future<String?> uploadKycDocument(File imageFile) async {
    try {
      // Create multipart request
      final uri = Uri.parse('${_apiService.baseUrl}/uploads');
      final request = http.MultipartRequest('POST', uri);

      // Add auth headers
      final token = await _storageService.getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      final file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      // Add file type
      request.fields['file_type'] = 'KYC_DOCUMENT';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        developer.log('Upload failed: ${response.body}', name: 'AuthService');
        return null;
      }
    } catch (e) {
      developer.log('Error uploading KYC document: $e', name: 'AuthService');
      return null;
    }
  }

  // Submit KYC
  Future<AuthResult> submitKyc({
    required String nationalIdUrl,
    required String bankName,
    required String branchAddress,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    try {
      // Validate inputs
      if (nationalIdUrl.isEmpty) {
        return AuthResult(
          success: false,
          error: 'National ID document is required',
        );
      }

      if (bankName.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Bank name is required',
        );
      }

      if (branchAddress.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Branch address is required',
        );
      }

      if (ifscCode.isEmpty) {
        return AuthResult(
          success: false,
          error: 'IFSC code is required',
        );
      }

      if (accountHolderName.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Account holder name is required',
        );
      }

      final response = await _apiService.post(
        '/kyc/submit',
        body: {
          'national_id_url': nationalIdUrl,
          'bank_details': {
            'bank_name': bankName,
            'branch_address': branchAddress,
            'ifsc_code': ifscCode,
            'account_holder_name': accountHolderName,
          },
        },
        requiresAuth: true,
      );

      // Extract data from response
      final responseData = response['data'] as Map<String, dynamic>?;
      final message = response['message'] as String?;

      AgentModel? agent;
      if (responseData != null && responseData['agent'] != null) {
        agent = AgentModel.fromJson(responseData['agent']);
      }

      return AuthResult(
        success: true,
        agent: agent,
        message: message ?? 'KYC submitted successfully. Awaiting admin verification.',
      );
    } on UnauthorizedException {
      return AuthResult(
        success: false,
        error: 'Session expired. Please login again.',
      );
    } on ApiException catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } on ValidationException catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'KYC submission failed: ${e.toString()}',
      );
    }
  }

  // Forgot Password
  Future<AuthResult> forgotPassword({
    required String emailOrPhone,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.forgotPasswordEndpoint,
        body: {
          'email_or_phone': emailOrPhone,
        },
        requiresAuth: false,
      );

      final message = response['message'] as String?;
      return AuthResult(
        success: true,
        message: message ?? AppConstants.successOtpSent,
        otpRequired: true,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Reset Password
  Future<AuthResult> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.resetPasswordEndpoint,
        body: {
          'email_or_phone': emailOrPhone,
          'otp': otp,
          'new_password': newPassword,
        },
        requiresAuth: false,
      );

      final message = response['message'] as String?;
      return AuthResult(
        success: true,
        message: message ?? AppConstants.successPasswordReset,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearTokens();
  }

  // Get current agent profile
  Future<AgentModel?> getCurrentAgent() async {
    // Demo Mode - return mock agent
    if (AppConstants.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));

      return AgentModel(
        id: 'demo-agent-001',
        firstName: 'Demo',
        lastName: 'Agent',
        email: 'demo@tccagent.com',
        mobileNumber: '+23276123456',
        profilePictureUrl: null,
        status: 'active',
        walletBalance: 5000000.0,
        commissionRate: 2.5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        verifiedAt: DateTime.now().subtract(const Duration(days: 29)),
        lastActiveAt: DateTime.now(),
        bankDetails: AgentBankDetails(
          bankName: 'Sierra Leone Commercial Bank',
          branchAddress: 'Freetown Main Branch',
          ifscCode: 'SLCB0001234',
          accountHolderName: 'Demo Agent',
          accountNumber: '****1234',
        ),
      );
    }

    // Real API Mode
    try {
      final response = await _apiService.get(
        AppConstants.agentProfileEndpoint,
        requiresAuth: true,
      );

      // Extract data from response
      final responseData = response['data'] as Map<String, dynamic>?;

      if (responseData != null && responseData['agent'] != null) {
        return AgentModel.fromJson(responseData['agent']);
      } else if (response['agent'] != null) {
        // Fallback to direct agent field
        return AgentModel.fromJson(response['agent']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    await _apiService.initialize();
    return _apiService.token != null;
  }
}

// Auth result model
class AuthResult {
  final bool success;
  final AgentModel? agent;
  final String? token;
  final String? message;
  final String? error;
  final bool otpRequired;

  AuthResult({
    required this.success,
    this.agent,
    this.token,
    this.message,
    this.error,
    this.otpRequired = false,
  });
}
