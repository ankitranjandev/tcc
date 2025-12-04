import '../models/api_response_model.dart';
import 'api_service.dart';

/// Settings Service
/// Handles all settings and configuration-related API calls for admin
class SettingsService {
  final ApiService _apiService = ApiService();

  /// Get system configuration
  /// Returns the current system configuration settings
  Future<ApiResponse<Map<String, dynamic>>> getSystemConfig() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/admin/config',
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          data: response.data!,
          message: response.message,
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to load system configuration',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load system configuration: ${e.toString()}',
      );
    }
  }

  /// Update system configuration
  /// Sends updated configuration settings to the backend
  Future<ApiResponse<Map<String, dynamic>>> updateSystemConfig({
    required Map<String, dynamic> config,
  }) async {
    try {
      final response = await _apiService.put(
        '/admin/config',
        data: {
          'config': config,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to update system configuration: ${e.toString()}',
      );
    }
  }

  /// Change admin password
  /// Uses the user change-password endpoint (works for admin users)
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    String? totpCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/users/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          if (totpCode != null && totpCode.isNotEmpty) 'totp_code': totpCode,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  /// Update notification settings
  /// Updates notification preferences in system config
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings({
    required bool emailNotifications,
    required bool smsNotifications,
    required bool pushNotifications,
  }) async {
    final config = {
      'notifications': {
        'email_enabled': emailNotifications,
        'sms_enabled': smsNotifications,
        'push_enabled': pushNotifications,
      },
    };

    return await updateSystemConfig(config: config);
  }

  /// Update security settings
  /// Updates security-related settings in system config
  Future<ApiResponse<Map<String, dynamic>>> updateSecuritySettings({
    bool? twoFactorAuth,
    bool? loginAlerts,
    int? sessionTimeout,
  }) async {
    final config = <String, dynamic>{
      'security': <String, dynamic>{
        if (twoFactorAuth != null) 'two_factor_auth_required': twoFactorAuth,
        if (loginAlerts != null) 'login_alerts_enabled': loginAlerts,
        if (sessionTimeout != null) 'session_timeout_minutes': sessionTimeout,
      },
    };

    return await updateSystemConfig(config: config);
  }

  /// Update transaction fee settings
  /// Updates fee percentages in system config
  Future<ApiResponse<Map<String, dynamic>>> updateFeeSettings({
    double? withdrawalFee,
    double? transferFee,
    double? billPaymentFee,
    double? investmentFee,
  }) async {
    final config = <String, dynamic>{
      'fees': <String, dynamic>{
        if (withdrawalFee != null) 'withdrawal_fee_percent': withdrawalFee,
        if (transferFee != null) 'transfer_fee_percent': transferFee,
        if (billPaymentFee != null) 'bill_payment_fee_percent': billPaymentFee,
        if (investmentFee != null) 'investment_fee_percent': investmentFee,
      },
    };

    return await updateSystemConfig(config: config);
  }

  /// Update admin controls
  /// Updates administrative control settings
  Future<ApiResponse<Map<String, dynamic>>> updateAdminControls({
    bool? autoApproveKYC,
    bool? autoProcessWithdrawals,
    bool? maintenanceMode,
  }) async {
    final config = <String, dynamic>{
      'admin_controls': <String, dynamic>{
        if (autoApproveKYC != null) 'auto_approve_kyc': autoApproveKYC,
        if (autoProcessWithdrawals != null) 'auto_process_withdrawals': autoProcessWithdrawals,
        if (maintenanceMode != null) 'maintenance_mode': maintenanceMode,
      },
    };

    return await updateSystemConfig(config: config);
  }

  /// Update general application settings
  /// Updates general app configuration
  Future<ApiResponse<Map<String, dynamic>>> updateGeneralSettings({
    String? appName,
    String? appVersion,
    String? environment,
    String? timezone,
  }) async {
    final config = <String, dynamic>{
      'general': <String, dynamic>{
        if (appName != null) 'app_name': appName,
        if (appVersion != null) 'app_version': appVersion,
        if (environment != null) 'environment': environment,
        if (timezone != null) 'timezone': timezone,
      },
    };

    return await updateSystemConfig(config: config);
  }

  /// Get specific config section
  /// Helper method to extract a section from config
  Map<String, dynamic>? getConfigSection(
    Map<String, dynamic> config,
    String section,
  ) {
    if (config.containsKey(section)) {
      return config[section] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Parse config value with default
  /// Helper method to safely get config values
  T getConfigValue<T>(
    Map<String, dynamic> config,
    String section,
    String key,
    T defaultValue,
  ) {
    try {
      final sectionData = getConfigSection(config, section);
      if (sectionData != null && sectionData.containsKey(key)) {
        return sectionData[key] as T;
      }
    } catch (e) {
      // Return default if parsing fails
    }
    return defaultValue;
  }
}
