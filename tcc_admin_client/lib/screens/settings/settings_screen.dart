import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/responsive.dart';

/// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  String _selectedSection = 'General';
  bool _isLoading = false;
  bool _isSaving = false;

  // Settings state
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _twoFactorAuth = true;
  bool _loginAlerts = true;
  bool _autoApproveKYC = false;
  bool _maintenanceMode = false;
  double _withdrawalFee = 2.0;
  double _transferFee = 1.0;
  double _billPaymentFee = 1.5;

  // Password change state
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSystemConfig();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Load system configuration from API
  Future<void> _loadSystemConfig() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _settingsService.getSystemConfig();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (response.success && response.data != null) {
        final config = response.data!;

        // Extract notification settings
        final notifications = config['notifications'] as Map<String, dynamic>?;
        if (notifications != null) {
          _emailNotifications = notifications['email_enabled'] as bool? ?? true;
          _smsNotifications = notifications['sms_enabled'] as bool? ?? false;
          _pushNotifications = notifications['push_enabled'] as bool? ?? true;
        }

        // Extract security settings
        final security = config['security'] as Map<String, dynamic>?;
        if (security != null) {
          _twoFactorAuth = security['two_factor_auth_required'] as bool? ?? true;
          _loginAlerts = security['login_alerts_enabled'] as bool? ?? true;
        }

        // Extract fee settings
        final fees = config['fees'] as Map<String, dynamic>?;
        if (fees != null) {
          _withdrawalFee = (fees['withdrawal_fee_percent'] as num?)?.toDouble() ?? 2.0;
          _transferFee = (fees['transfer_fee_percent'] as num?)?.toDouble() ?? 1.0;
          _billPaymentFee = (fees['bill_payment_fee_percent'] as num?)?.toDouble() ?? 1.5;
        }

        // Extract admin controls
        final adminControls = config['admin_controls'] as Map<String, dynamic>?;
        if (adminControls != null) {
          _autoApproveKYC = adminControls['auto_approve_kyc'] as bool? ?? false;
          _maintenanceMode = adminControls['maintenance_mode'] as bool? ?? false;
        }

        setState(() {});
      }
    }
  }

  /// Save notification settings
  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isSaving = true;
    });

    final response = await _settingsService.updateNotificationSettings(
      emailNotifications: _emailNotifications,
      smsNotifications: _smsNotifications,
      pushNotifications: _pushNotifications,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to update settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Save fee settings
  Future<void> _saveFeeSettings() async {
    setState(() {
      _isSaving = true;
    });

    final response = await _settingsService.updateFeeSettings(
      withdrawalFee: _withdrawalFee,
      transferFee: _transferFee,
      billPaymentFee: _billPaymentFee,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fee settings updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to update fee settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Change password
  Future<void> _changePassword() async {
    // Validate passwords
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all password fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final response = await _settingsService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to change password'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Show loading indicator while loading config
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (isMobile || isTablet) {
      // Mobile/Tablet Layout: Section selector at top
      return SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with section dropdown
            Text(
              'Settings',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            // Section Dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.gray300),
              ),
              child: DropdownButton<String>(
                value: _selectedSection,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  _buildDropdownItem(Icons.settings, 'General'),
                  _buildDropdownItem(Icons.person, 'Profile'),
                  _buildDropdownItem(Icons.security, 'Security'),
                  _buildDropdownItem(Icons.notifications, 'Notifications'),
                  _buildDropdownItem(Icons.attach_money, 'Fees'),
                  _buildDropdownItem(Icons.admin_panel_settings, 'Admin'),
                  _buildDropdownItem(Icons.build, 'System'),
                  _buildDropdownItem(Icons.info, 'About'),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Content
            _buildContent(authProvider, isMobile),
          ],
        ),
      );
    }

    // Desktop Layout: Sidebar + Content
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        Container(
          width: 280,
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [AppColors.shadowSmall],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space24),
              _buildSidebarItem(Icons.settings, 'General', 'General'),
              _buildSidebarItem(Icons.person, 'Profile', 'Profile'),
              _buildSidebarItem(Icons.security, 'Security', 'Security'),
              _buildSidebarItem(Icons.notifications, 'Notifications', 'Notifications'),
              _buildSidebarItem(Icons.attach_money, 'Fees & Charges', 'Fees'),
              _buildSidebarItem(Icons.admin_panel_settings, 'Admin Controls', 'Admin'),
              _buildSidebarItem(Icons.build, 'System', 'System'),
              _buildSidebarItem(Icons.info, 'About', 'About'),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.space24),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: _buildContent(authProvider, false),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AuthProvider authProvider, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                // General Settings
                if (_selectedSection == 'General') ...[
                  Text(
                    'General Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Manage general application settings',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Application Settings',
                    [
                      _buildSettingRow(
                        'Application Name',
                        'TCC Admin',
                        trailing: const Icon(Icons.edit, size: 20),
                      ),
                      _buildSettingRow(
                        'Version',
                        '1.0.0',
                      ),
                      _buildSettingRow(
                        'Environment',
                        'Development',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'DEV',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Profile Settings
                if (_selectedSection == 'Profile') ...[
                  Text(
                    'Profile Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Manage your profile information',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Admin Information',
                    [
                      _buildSettingRow(
                        'Name',
                        authProvider.admin?.name ?? 'N/A',
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            // TODO: Edit name
                          },
                        ),
                      ),
                      _buildSettingRow(
                        'Email',
                        authProvider.admin?.email ?? 'N/A',
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            // TODO: Edit email
                          },
                        ),
                      ),
                      _buildSettingRow(
                        'Role',
                        authProvider.admin?.role.name ?? 'N/A',
                      ),
                      _buildSettingRow(
                        'Last Login',
                        authProvider.admin?.lastLogin.toString() ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSettingsCard(
                    'Change Password',
                    [
                      _buildPasswordField('Current Password'),
                      _buildPasswordField('New Password'),
                      _buildPasswordField('Confirm New Password'),
                      const SizedBox(height: AppTheme.space16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _changePassword,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : const Text('Update Password'),
                      ),
                    ],
                  ),
                ],

                // Security Settings
                if (_selectedSection == 'Security') ...[
                  Text(
                    'Security Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Manage security and authentication settings',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Authentication',
                    [
                      _buildSwitchRow(
                        'Two-Factor Authentication',
                        'Require 2FA for all logins',
                        _twoFactorAuth,
                        (value) {
                          setState(() {
                            _twoFactorAuth = value;
                          });
                        },
                      ),
                      _buildSwitchRow(
                        'Login Alerts',
                        'Get notified of new login attempts',
                        _loginAlerts,
                        (value) {
                          setState(() {
                            _loginAlerts = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSettingsCard(
                    'Session Management',
                    [
                      _buildSettingRow(
                        'Active Sessions',
                        '2 devices',
                        trailing: TextButton(
                          onPressed: () {
                            // TODO: View sessions
                          },
                          child: const Text('View All'),
                        ),
                      ),
                      _buildSettingRow(
                        'Session Timeout',
                        '30 minutes',
                        trailing: const Icon(Icons.edit, size: 20),
                      ),
                    ],
                  ),
                ],

                // Notification Settings
                if (_selectedSection == 'Notifications') ...[
                  Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Configure notification preferences',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Notification Channels',
                    [
                      _buildSwitchRow(
                        'Email Notifications',
                        'Receive notifications via email',
                        _emailNotifications,
                        (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                          _saveNotificationSettings();
                        },
                      ),
                      _buildSwitchRow(
                        'SMS Notifications',
                        'Receive notifications via SMS',
                        _smsNotifications,
                        (value) {
                          setState(() {
                            _smsNotifications = value;
                          });
                          _saveNotificationSettings();
                        },
                      ),
                      _buildSwitchRow(
                        'Push Notifications',
                        'Receive push notifications',
                        _pushNotifications,
                        (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                ],

                // Fees Settings
                if (_selectedSection == 'Fees') ...[
                  Text(
                    'Fees & Charges',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Manage transaction fees and charges',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Transaction Fees',
                    [
                      _buildSliderRow(
                        'Withdrawal Fee',
                        _withdrawalFee,
                        (value) {
                          setState(() {
                            _withdrawalFee = value;
                          });
                        },
                      ),
                      _buildSliderRow(
                        'Transfer Fee',
                        _transferFee,
                        (value) {
                          setState(() {
                            _transferFee = value;
                          });
                        },
                      ),
                      _buildSliderRow(
                        'Bill Payment Fee',
                        _billPaymentFee,
                        (value) {
                          setState(() {
                            _billPaymentFee = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveFeeSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],

                // Admin Controls
                if (_selectedSection == 'Admin') ...[
                  Text(
                    'Admin Controls',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Advanced administrative controls',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Automation',
                    [
                      _buildSwitchRow(
                        'Auto-Approve KYC',
                        'Automatically approve KYC submissions',
                        _autoApproveKYC,
                        (value) {
                          setState(() {
                            _autoApproveKYC = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSettingsCard(
                    'Admin Users',
                    [
                      _buildSettingRow(
                        'Total Admins',
                        '5',
                        trailing: ElevatedButton(
                          onPressed: () {
                            // TODO: Manage admins
                          },
                          child: const Text('Manage'),
                        ),
                      ),
                    ],
                  ),
                ],

                // System Settings
                if (_selectedSection == 'System') ...[
                  Text(
                    'System Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'System configuration and maintenance',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'System Status',
                    [
                      _buildSwitchRow(
                        'Maintenance Mode',
                        'Enable maintenance mode',
                        _maintenanceMode,
                        (value) {
                          setState(() {
                            _maintenanceMode = value;
                          });
                        },
                        isDangerous: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSettingsCard(
                    'Cache & Storage',
                    [
                      _buildSettingRow(
                        'Cache Size',
                        '245 MB',
                        trailing: OutlinedButton(
                          onPressed: () {
                            // TODO: Clear cache
                          },
                          child: const Text('Clear Cache'),
                        ),
                      ),
                    ],
                  ),
                ],

                // About
                if (_selectedSection == 'About') ...[
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSettingsCard(
                    'Application Information',
                    [
                      _buildSettingRow('Name', 'TCC Admin Panel'),
                      _buildSettingRow('Version', '1.0.0'),
                      _buildSettingRow('Build', '100'),
                      _buildSettingRow('License', 'Proprietary'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSettingsCard(
                    'Support',
                    [
                      _buildSettingRow(
                        'Documentation',
                        'View documentation',
                        trailing: const Icon(Icons.open_in_new, size: 20),
                      ),
                      _buildSettingRow(
                        'Contact Support',
                        'support@tcc.sl',
                        trailing: const Icon(Icons.email, size: 20),
                      ),
                    ],
                  ),
                ],
      ],
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(IconData icon, String title) {
    return DropdownMenuItem(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.space12),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, String section) {
    final isSelected = _selectedSection == section;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSection = section;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space8),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    final isMobile = context.isMobile;
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          trailing ??
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    String description,
    bool value,
    Function(bool) onChanged, {
    bool isDangerous = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDangerous ? AppColors.error : AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 5,
            divisions: 50,
            activeColor: AppColors.accentBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    TextEditingController? controller;
    if (label == 'Current Password') {
      controller = _currentPasswordController;
    } else if (label == 'New Password') {
      controller = _newPasswordController;
    } else if (label == 'Confirm New Password') {
      controller = _confirmPasswordController;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }
}
