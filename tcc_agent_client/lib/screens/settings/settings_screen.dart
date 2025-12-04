import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.brightness_6,
                  title: 'Dark Mode',
                  subtitle: 'Toggle dark theme',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeTrackColor: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_active,
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeTrackColor: AppColors.primaryOrange,
                  ),
                ),
                Divider(height: 1, color: AppColors.borderLight),
                _buildSettingTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Receive email updates',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeTrackColor: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Security'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
                Divider(height: 1, color: AppColors.borderLight),
                _buildSettingTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face ID',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                    activeTrackColor: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Help & Support Section
          _buildSectionHeader('Help & Support'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'FAQs and guides',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1, color: AppColors.borderLight),
                _buildSettingTile(
                  icon: Icons.support_agent,
                  title: 'Contact Support',
                  subtitle: 'Get help from our team',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/support');
                  },
                ),
                Divider(height: 1, color: AppColors.borderLight),
                _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1, color: AppColors.borderLight),
                _buildSettingTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'Read terms of service',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: 'Version 1.0.0',
                  trailing: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryOrange, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
