import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/agent_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AgentModel? _agent;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  AgentModel? get agent => _agent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _agent?.isVerified ?? false;
  bool get isPendingVerification => _agent?.isPendingVerification ?? false;
  bool get isKycApproved => _agent?.kycStatus == 'APPROVED';
  AuthService get authService => _authService;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    developer.log('🔄 [AUTH_PROVIDER] Initializing...', name: 'TCC.AuthProvider');
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.initialize();
      developer.log('✅ [AUTH_PROVIDER] API service initialized', name: 'TCC.AuthProvider');

      final isAuth = await _authService.isAuthenticated();
      developer.log('🔍 [AUTH_PROVIDER] isAuthenticated check: $isAuth', name: 'TCC.AuthProvider');

      if (isAuth) {
        final agent = await _authService.getCurrentAgent();
        if (agent != null) {
          _agent = agent;
          _isAuthenticated = true;
          developer.log(
            '✅ [AUTH_PROVIDER] Agent loaded:\n'
            '  Name: ${agent.fullName}\n'
            '  Status: ${agent.status}\n'
            '  isPendingVerification: $isPendingVerification',
            name: 'TCC.AuthProvider',
          );
        } else {
          developer.log('⚠️ [AUTH_PROVIDER] isAuth=true but agent is null', name: 'TCC.AuthProvider');
        }
      } else {
        developer.log('ℹ️ [AUTH_PROVIDER] No existing session found', name: 'TCC.AuthProvider');
      }
    } catch (e) {
      developer.log('❌ [AUTH_PROVIDER] Initialize error: ${e.toString()}', name: 'TCC.AuthProvider');
      _error = e.toString();
    } finally {
      _isLoading = false;
      developer.log('✅ [AUTH_PROVIDER] Initialize complete', name: 'TCC.AuthProvider');
      notifyListeners();
    }
  }

  // Login (supports both agent and admin login)
  Future<bool> login({
    required String emailOrPhone,
    required String password,
    bool isAdminLogin = false,
  }) async {
    developer.log(
      '🔐 [AUTH_PROVIDER] Login starting:\n'
      '  Email/Phone: $emailOrPhone\n'
      '  isAdminLogin: $isAdminLogin',
      name: 'TCC.AuthProvider',
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        emailOrPhone: emailOrPhone,
        password: password,
        isAdminLogin: isAdminLogin,
      );

      developer.log(
        '📦 [AUTH_PROVIDER] Login result received:\n'
        '  Success: ${result.success}\n'
        '  Has Agent: ${result.agent != null}\n'
        '  Error: ${result.error ?? 'none'}',
        name: 'TCC.AuthProvider',
      );

      if (result.success && result.agent != null) {
        _agent = result.agent;
        _isAuthenticated = true;
        _error = null;

        developer.log(
          '✅ [AUTH_PROVIDER] Login successful, setting state:\n'
          '  Agent: ${_agent?.fullName}\n'
          '  Status: ${_agent?.status}\n'
          '  isAuthenticated: $_isAuthenticated\n'
          '  isPendingVerification: $isPendingVerification',
          name: 'TCC.AuthProvider',
        );

        developer.log('🔔 [AUTH_PROVIDER] Calling notifyListeners()', name: 'TCC.AuthProvider');
        notifyListeners();
        developer.log('✅ [AUTH_PROVIDER] notifyListeners() completed', name: 'TCC.AuthProvider');
        return true;
      } else {
        _error = result.error ?? 'Login failed';
        _isAuthenticated = false;
        developer.log('❌ [AUTH_PROVIDER] Login failed: $_error', name: 'TCC.AuthProvider');
        notifyListeners();
        return false;
      }
    } catch (e) {
      developer.log('❌ [AUTH_PROVIDER] Login exception: ${e.toString()}', name: 'TCC.AuthProvider');
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      developer.log('✅ [AUTH_PROVIDER] Login process complete', name: 'TCC.AuthProvider');
      notifyListeners();
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobileNumber: mobileNumber,
        password: password,
        profilePictureUrl: profilePictureUrl,
      );

      if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify OTP
  Future<AuthResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(
        mobileNumber: mobileNumber,
        otp: otp,
      );

      if (result.success && result.agent != null) {
        _agent = result.agent;
        _isAuthenticated = true;
      } else if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend OTP
  Future<AuthResult> resendOtp({
    required String mobileNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resendOtp(
        mobileNumber: mobileNumber,
      );

      if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.submitKyc(
        nationalIdUrl: nationalIdUrl,
        bankName: bankName,
        branchAddress: branchAddress,
        ifscCode: ifscCode,
        accountHolderName: accountHolderName,
      );

      if (result.success && result.agent != null) {
        _agent = result.agent;
      } else if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot Password
  Future<AuthResult> forgotPassword({
    required String emailOrPhone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.forgotPassword(
        emailOrPhone: emailOrPhone,
      );

      if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset Password
  Future<AuthResult> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(
        emailOrPhone: emailOrPhone,
        otp: otp,
        newPassword: newPassword,
      );

      if (!result.success) {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return AuthResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _agent = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh agent profile
  Future<void> refreshProfile() async {
    try {
      final agent = await _authService.getCurrentAgent();
      if (agent != null) {
        _agent = agent;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
