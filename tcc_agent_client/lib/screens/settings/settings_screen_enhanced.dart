import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_colors.dart';
import '../../providers/theme_provider.dart';
import 'change_password_screen.dart';

class SettingsScreenEnhanced extends StatefulWidget {
  const SettingsScreenEnhanced({super.key});

  @override
  State<SettingsScreenEnhanced> createState() => _SettingsScreenEnhancedState();
}

class _SettingsScreenEnhancedState extends State<SettingsScreenEnhanced> {
  PackageInfo? _packageInfo;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: '+232 76 123 456',
            trailing: const Text(
              'Verified',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'agent@example.com',
            trailing: const Text(
              'Verified',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch between light and dark theme',
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          _buildSettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: () => _showLanguageSelector(),
          ),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive notifications for updates',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // TODO: Update notification preferences
            },
          ),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'Allow location tracking for orders',
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
              // TODO: Update location preferences
            },
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Security & Privacy'),
          _buildSettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face ID',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Enable biometric auth
              },
              activeThumbColor: AppColors.primaryOrange,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.lock_clock_outlined,
            title: 'Auto Lock',
            subtitle: '5 minutes',
            onTap: () {
              // TODO: Show auto lock duration selector
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              // TODO: Navigate to terms
            },
          ),

          const SizedBox(height: 24),

          // Data & Storage Section
          _buildSectionHeader('Data & Storage'),
          _buildSettingsTile(
            icon: Icons.download_outlined,
            title: 'Download My Data',
            subtitle: 'Export your account data',
            onTap: () {
              _showComingSoonDialog('Data Export');
            },
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: '24 MB cached data',
            onTap: () => _showClearCacheDialog(),
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              // TODO: Navigate to help center
            },
          ),
          _buildSettingsTile(
            icon: Icons.chat_outlined,
            title: 'Contact Support',
            subtitle: 'Send us a message',
            onTap: () {
              // TODO: Navigate to support chat
            },
          ),
          _buildSettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () {
              _showComingSoonDialog('Bug Report');
            },
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: _packageInfo != null
                ? 'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                : 'Loading...',
          ),
          _buildSettingsTile(
            icon: Icons.update_outlined,
            title: 'Check for Updates',
            subtitle: 'You have the latest version',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You are using the latest version'),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.rate_review_outlined,
            title: 'Rate the App',
            subtitle: 'Share your feedback',
            onTap: () {
              _showComingSoonDialog('App Rating');
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delete Account Button
          TextButton(
            onPressed: () => _showDeleteAccountDialog(),
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryOrange,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, size: 20)
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryOrange,
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('English'),
              trailing: _selectedLanguage == 'English'
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Krio'),
              trailing: _selectedLanguage == 'Krio'
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Krio';
                });
                Navigator.pop(context);
                _showComingSoonDialog('Krio Language');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog('Account Deletion');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data. The app may take longer to load initially.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
