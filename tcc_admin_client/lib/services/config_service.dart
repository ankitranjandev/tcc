import '../models/api_response_model.dart';
import 'api_service.dart';

/// Configuration Service
/// Handles all system configuration-related API calls for admin
class ConfigService {
  final ApiService _apiService = ApiService();

  /// Get all system configuration
  Future<ApiResponse<Map<String, dynamic>>> getSystemConfig() async {
    return await _apiService.get(
      '/admin/config',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update system configuration
  Future<ApiResponse<Map<String, dynamic>>> updateSystemConfig({
    required Map<String, dynamic> config,
  }) async {
    return await _apiService.put(
      '/admin/config',
      data: config,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get specific config value
  Future<ApiResponse<dynamic>> getConfigValue({
    required String key,
  }) async {
    return await _apiService.get(
      '/admin/config/$key',
      fromJson: (data) => data['value'],
    );
  }

  /// Update specific config value
  Future<ApiResponse<Map<String, dynamic>>> updateConfigValue({
    required String key,
    required dynamic value,
  }) async {
    return await _apiService.put(
      '/admin/config/$key',
      data: {
        'value': value,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transaction limits configuration
  Future<ApiResponse<Map<String, dynamic>>> getTransactionLimits() async {
    return await _apiService.get(
      '/admin/config/transaction-limits',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update transaction limits
  Future<ApiResponse<Map<String, dynamic>>> updateTransactionLimits({
    double? minDeposit,
    double? maxDeposit,
    double? minWithdrawal,
    double? maxWithdrawal,
    double? minTransfer,
    double? maxTransfer,
  }) async {
    return await _apiService.put(
      '/admin/config/transaction-limits',
      data: {
        if (minDeposit != null) 'min_deposit': minDeposit,
        if (maxDeposit != null) 'max_deposit': maxDeposit,
        if (minWithdrawal != null) 'min_withdrawal': minWithdrawal,
        if (maxWithdrawal != null) 'max_withdrawal': maxWithdrawal,
        if (minTransfer != null) 'min_transfer': minTransfer,
        if (maxTransfer != null) 'max_transfer': maxTransfer,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get fee configuration
  Future<ApiResponse<Map<String, dynamic>>> getFeeConfig() async {
    return await _apiService.get(
      '/admin/config/fees',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update fee configuration
  Future<ApiResponse<Map<String, dynamic>>> updateFeeConfig({
    double? depositFee,
    double? withdrawalFee,
    double? transferFee,
    double? billPaymentFee,
    double? agentCommissionRate,
  }) async {
    return await _apiService.put(
      '/admin/config/fees',
      data: {
        if (depositFee != null) 'deposit_fee': depositFee,
        if (withdrawalFee != null) 'withdrawal_fee': withdrawalFee,
        if (transferFee != null) 'transfer_fee': transferFee,
        if (billPaymentFee != null) 'bill_payment_fee': billPaymentFee,
        if (agentCommissionRate != null) 'agent_commission_rate': agentCommissionRate,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get KYC configuration
  Future<ApiResponse<Map<String, dynamic>>> getKycConfig() async {
    return await _apiService.get(
      '/admin/config/kyc',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update KYC configuration
  Future<ApiResponse<Map<String, dynamic>>> updateKycConfig({
    bool? autoApprovalEnabled,
    List<String>? requiredDocuments,
    int? expiryDays,
  }) async {
    return await _apiService.put(
      '/admin/config/kyc',
      data: {
        if (autoApprovalEnabled != null) 'auto_approval_enabled': autoApprovalEnabled,
        if (requiredDocuments != null) 'required_documents': requiredDocuments,
        if (expiryDays != null) 'expiry_days': expiryDays,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get security configuration
  Future<ApiResponse<Map<String, dynamic>>> getSecurityConfig() async {
    return await _apiService.get(
      '/admin/config/security',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update security configuration
  Future<ApiResponse<Map<String, dynamic>>> updateSecurityConfig({
    bool? twoFactorRequired,
    int? sessionTimeout,
    int? maxLoginAttempts,
    int? passwordExpiryDays,
  }) async {
    return await _apiService.put(
      '/admin/config/security',
      data: {
        if (twoFactorRequired != null) 'two_factor_required': twoFactorRequired,
        if (sessionTimeout != null) 'session_timeout': sessionTimeout,
        if (maxLoginAttempts != null) 'max_login_attempts': maxLoginAttempts,
        if (passwordExpiryDays != null) 'password_expiry_days': passwordExpiryDays,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get notification configuration
  Future<ApiResponse<Map<String, dynamic>>> getNotificationConfig() async {
    return await _apiService.get(
      '/admin/config/notifications',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update notification configuration
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationConfig({
    bool? emailEnabled,
    bool? smsEnabled,
    bool? pushEnabled,
    Map<String, dynamic>? templates,
  }) async {
    return await _apiService.put(
      '/admin/config/notifications',
      data: {
        if (emailEnabled != null) 'email_enabled': emailEnabled,
        if (smsEnabled != null) 'sms_enabled': smsEnabled,
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (templates != null) 'templates': templates,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get payment gateway configuration
  Future<ApiResponse<Map<String, dynamic>>> getPaymentGatewayConfig() async {
    return await _apiService.get(
      '/admin/config/payment-gateways',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update payment gateway configuration
  Future<ApiResponse<Map<String, dynamic>>> updatePaymentGatewayConfig({
    required String gateway,
    required Map<String, dynamic> config,
  }) async {
    return await _apiService.put(
      '/admin/config/payment-gateways/$gateway',
      data: config,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get SMS provider configuration
  Future<ApiResponse<Map<String, dynamic>>> getSmsProviderConfig() async {
    return await _apiService.get(
      '/admin/config/sms-provider',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update SMS provider configuration
  Future<ApiResponse<Map<String, dynamic>>> updateSmsProviderConfig({
    required String provider,
    required Map<String, dynamic> config,
  }) async {
    return await _apiService.put(
      '/admin/config/sms-provider',
      data: {
        'provider': provider,
        'config': config,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get email configuration
  Future<ApiResponse<Map<String, dynamic>>> getEmailConfig() async {
    return await _apiService.get(
      '/admin/config/email',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update email configuration
  Future<ApiResponse<Map<String, dynamic>>> updateEmailConfig({
    String? smtpHost,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? fromEmail,
    String? fromName,
  }) async {
    return await _apiService.put(
      '/admin/config/email',
      data: {
        if (smtpHost != null) 'smtp_host': smtpHost,
        if (smtpPort != null) 'smtp_port': smtpPort,
        if (smtpUser != null) 'smtp_user': smtpUser,
        if (smtpPassword != null) 'smtp_password': smtpPassword,
        if (fromEmail != null) 'from_email': fromEmail,
        if (fromName != null) 'from_name': fromName,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get app configuration (for mobile apps)
  Future<ApiResponse<Map<String, dynamic>>> getAppConfig() async {
    return await _apiService.get(
      '/admin/config/app',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update app configuration
  Future<ApiResponse<Map<String, dynamic>>> updateAppConfig({
    String? minAppVersion,
    String? latestAppVersion,
    bool? forceUpdate,
    String? maintenanceMode,
    Map<String, dynamic>? features,
  }) async {
    return await _apiService.put(
      '/admin/config/app',
      data: {
        if (minAppVersion != null) 'min_app_version': minAppVersion,
        if (latestAppVersion != null) 'latest_app_version': latestAppVersion,
        if (forceUpdate != null) 'force_update': forceUpdate,
        if (maintenanceMode != null) 'maintenance_mode': maintenanceMode,
        if (features != null) 'features': features,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get feature flags
  Future<ApiResponse<Map<String, dynamic>>> getFeatureFlags() async {
    return await _apiService.get(
      '/admin/config/feature-flags',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update feature flags
  Future<ApiResponse<Map<String, dynamic>>> updateFeatureFlags({
    required Map<String, bool> flags,
  }) async {
    return await _apiService.put(
      '/admin/config/feature-flags',
      data: flags,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Toggle specific feature flag
  Future<ApiResponse<Map<String, dynamic>>> toggleFeatureFlag({
    required String featureName,
    required bool enabled,
  }) async {
    return await _apiService.put(
      '/admin/config/feature-flags/$featureName',
      data: {
        'enabled': enabled,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get system maintenance mode status
  Future<ApiResponse<Map<String, dynamic>>> getMaintenanceMode() async {
    return await _apiService.get(
      '/admin/config/maintenance',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Toggle system maintenance mode
  Future<ApiResponse<Map<String, dynamic>>> toggleMaintenanceMode({
    required bool enabled,
    String? message,
    DateTime? scheduledEnd,
  }) async {
    return await _apiService.put(
      '/admin/config/maintenance',
      data: {
        'enabled': enabled,
        if (message != null) 'message': message,
        if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get audit log for configuration changes
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getConfigAuditLog({
    int page = 1,
    int perPage = 25,
    String? configKey,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (configKey != null && configKey.isNotEmpty) 'config_key': configKey,
    };

    final response = await _apiService.get(
      '/admin/config/audit',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Reset configuration to defaults
  Future<ApiResponse<Map<String, dynamic>>> resetConfigToDefaults({
    String? section, // optional, reset specific section only
  }) async {
    return await _apiService.post(
      '/admin/config/reset',
      data: {
        if (section != null && section.isNotEmpty) 'section': section,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Export configuration
  Future<ApiResponse<String>> exportConfig() async {
    return await _apiService.get(
      '/admin/config/export',
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Import configuration
  Future<ApiResponse<Map<String, dynamic>>> importConfig({
    required Map<String, dynamic> config,
  }) async {
    return await _apiService.post(
      '/admin/config/import',
      data: config,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
