import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../wallet/wallet_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WalletScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Profile Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile view coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.firstName ?? 'User',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View Profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // KYC Status Banner
              if (user != null && !user.isKycApproved) ...[
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: () {
                      // Navigate to status screen if KYC is pending, otherwise to verification
                      if (user.isKycPending) {
                        context.push('/kyc-status');
                      } else {
                        context.push('/kyc-verification');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getKycBannerColor(user.kycStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getKycBannerColor(user.kycStatus).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getKycBannerColor(user.kycStatus).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getKycIcon(user.kycStatus),
                              color: _getKycBannerColor(user.kycStatus),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getKycTitle(user.kycStatus),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getKycBannerColor(user.kycStatus),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _getKycMessage(user.kycStatus),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 32),
              Divider(),
              SizedBox(height: 16),

              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notification',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  activeThumbColor: AppColors.primaryBlue,
                ),
                onTap: null,
              ),
              _buildMenuItem(
                context,
                icon: Icons.account_balance,
                title: 'Banks',
                onTap: () {
                  _showBanksDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.headset_mic_outlined,
                title: 'Support',
                onTap: () {
                  _showSupportDialog(context);
                },
              ),

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),

              _buildMenuItem(
                context,
                icon: Icons.description_outlined,
                title: 'Terms and conditions',
                onTap: () {
                  _showTermsDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  _showPrivacyDialog(context);
                },
              ),

              SizedBox(height: 32),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () {
                    authProvider.logout();
                    context.go('/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.power_settings_new),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primaryBlue,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  static void _showBanksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance, color: AppColors.primaryBlue),
            SizedBox(width: 12),
            Text('My Banks'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBankCard('HDFC Bank', '********2193'),
            SizedBox(height: 12),
            _buildBankCard('SBI Bank', '********4567'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Add bank feature coming soon!')),
              );
            },
            child: Text('Add Bank'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBankCard(String bankName, String accountNumber) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card, color: AppColors.primaryBlue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName, style: TextStyle(fontWeight: FontWeight.w600)),
                Text(accountNumber, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.headset_mic, color: AppColors.primaryBlue),
            SizedBox(width: 12),
            Text('Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email, color: AppColors.primaryBlue),
              title: Text('Email'),
              subtitle: Text('support@tcc.com'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppColors.primaryBlue),
              title: Text('Phone'),
              subtitle: Text('+232 123 456 789'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.chat, color: AppColors.primaryBlue),
              title: Text('Live Chat'),
              subtitle: Text('Available 24/7'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            '1. Acceptance of Terms\n\n'
            'By accessing and using TCC services, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
            '2. Use License\n\n'
            'Permission is granted to temporarily download one copy of the materials on TCC\'s app for personal, non-commercial transitory viewing only.\n\n'
            '3. Disclaimer\n\n'
            'The materials on TCC\'s app are provided on an \'as is\' basis. TCC makes no warranties, expressed or implied.\n\n'
            '4. Limitations\n\n'
            'In no event shall TCC or its suppliers be liable for any damages arising out of the use or inability to use the materials on TCC\'s app.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            '1. Information We Collect\n\n'
            'We collect information you provide directly to us, such as when you create an account, make transactions, or contact us for support.\n\n'
            '2. How We Use Your Information\n\n'
            'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.\n\n'
            '3. Information Sharing\n\n'
            'We do not share your personal information with third parties except as described in this privacy policy.\n\n'
            '4. Data Security\n\n'
            'We implement appropriate security measures to protect your personal information from unauthorized access.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  static Color _getKycBannerColor(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }

  static IconData _getKycIcon(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time;
      case 'REJECTED':
        return Icons.error_outline;
      default:
        return Icons.verified_user_outlined;
    }
  }

  static String _getKycTitle(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
        return 'KYC Verification Pending';
      case 'REJECTED':
        return 'KYC Verification Failed';
      default:
        return 'Complete KYC Verification';
    }
  }

  static String _getKycMessage(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
        return 'Your documents are being reviewed';
      case 'REJECTED':
        return 'Please resubmit your documents';
      default:
        return 'Verify your identity to access all features';
    }
  }
}
