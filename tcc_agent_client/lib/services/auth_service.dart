import '../models/agent_model.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Login (supports both agent and admin login)
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
    bool isAdminLogin = false,
  }) async {
    // Demo Mode - bypass API call
    if (AppConstants.isDemoMode && !isAdminLogin) {
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
        walletBalance: 5000000.0, // 5 million SLL
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

      // Admin login uses 'access_token', regular login uses 'token'
      final token = (response['access_token'] ?? response['token']) as String?;
      final refreshToken = response['refresh_token'] as String?;

      if (token == null || refreshToken == null) {
        throw Exception('Invalid response: missing authentication tokens');
      }

      // Admin login returns 'admin' field, regular login returns 'agent' field
      final userData = response['admin'] ?? response['agent'];
      if (userData == null) {
        throw Exception('Invalid response: missing user data');
      }

      final agent = AgentModel.fromJson(userData);

      await _apiService.setTokens(token, refreshToken);

      return AuthResult(
        success: true,
        agent: agent,
        token: token,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
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

      return AuthResult(
        success: true,
        message: response['message'] ?? AppConstants.successRegistration,
        otpRequired: true,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Verify OTP
  Future<AuthResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.verifyOtpEndpoint,
        body: {
          'mobile_number': mobileNumber,
          'otp': otp,
        },
        requiresAuth: false,
      );

      final token = response['token'] as String?;
      final refreshToken = response['refresh_token'] as String?;

      if (token != null && refreshToken != null) {
        final agent = AgentModel.fromJson(response['agent']);
        await _apiService.setTokens(token, refreshToken);

        return AuthResult(
          success: true,
          agent: agent,
          token: token,
        );
      }

      return AuthResult(
        success: true,
        message: response['message'] ?? 'OTP verified successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Resend OTP
  Future<AuthResult> resendOtp({
    required String mobileNumber,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.resendOtpEndpoint,
        body: {
          'mobile_number': mobileNumber,
        },
        requiresAuth: false,
      );

      return AuthResult(
        success: true,
        message: response['message'] ?? AppConstants.successOtpSent,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
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

      final agent = AgentModel.fromJson(response['agent']);

      return AuthResult(
        success: true,
        agent: agent,
        message: response['message'] ?? 'KYC submitted successfully. Awaiting admin verification.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
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

      return AuthResult(
        success: true,
        message: response['message'] ?? AppConstants.successOtpSent,
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

      return AuthResult(
        success: true,
        message: response['message'] ?? AppConstants.successPasswordReset,
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

      return AgentModel.fromJson(response['agent']);
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
