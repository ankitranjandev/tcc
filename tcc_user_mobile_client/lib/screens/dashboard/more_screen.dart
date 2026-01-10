import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_account_provider.dart';
import '../../models/bank_account_model.dart';
import '../../widgets/authenticated_image.dart';
import '../profile/profile_screen.dart';
import '../profile/manage_bank_account_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch bank accounts when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBankAccounts();
    });
  }

  Future<void> _loadBankAccounts() async {
    final provider = Provider.of<BankAccountProvider>(context, listen: false);
    await provider.fetchAccounts();
  }

  String _getFixedImageUrl(String url) {
    return AppConstants.getImageUrl(url);
  }

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
                child: Text(
                  'My Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Profile Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
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
                          child: user?.profilePicture != null
                              ? ClipOval(
                                  child: AuthenticatedImage(
                                    key: ValueKey(user!.profilePicture!),
                                    imageUrl: _getFixedImageUrl(user.profilePicture!),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryBlue,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 40,
                                        color: AppColors.primaryBlue,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
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
                              Row(
                                children: [
                                  Text(
                                    user?.firstName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (user != null && user.isKycApproved) ...[
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.verified,
                                      size: 20,
                                      color: AppColors.success,
                                    ),
                                  ],
                                ],
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
                      // Navigate to status screen if KYC is in progress, otherwise to verification
                      if (_isKycInProgress(user.kycStatus)) {
                        context.push('/kyc-status');
                      } else if (user.isKycRejected) {
                        context.push('/kyc-verification');
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
                icon: Icons.headset_mic_outlined,
                title: 'Support',
                onTap: () {
                  _showSupportDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.account_balance,
                title: 'Banks',
                onTap: () {
                  _showBanksDialog(context);
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

  void _showBanksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<BankAccountProvider>(
        builder: (context, provider, child) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Bank Accounts'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 400),
              child: provider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : provider.accounts.isEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bank accounts added',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add a bank account to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...provider.accounts.map((account) => Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: _buildBankCard(
                                      context,
                                      account,
                                      onEdit: () async {
                                        Navigator.pop(dialogContext);
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ManageBankAccountScreen(account: account),
                                          ),
                                        );
                                        if (result == true && mounted) {
                                          _loadBankAccounts();
                                        }
                                      },
                                      onDelete: () async {
                                        final confirm = await _showDeleteConfirmation(context, account);
                                        if (confirm == true) {
                                          final success = await provider.deleteAccount(account.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Bank account deleted'
                                                      : 'Failed to delete bank account',
                                                ),
                                                backgroundColor:
                                                    success ? AppColors.success : AppColors.error,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      onSetPrimary: account.isPrimary
                                          ? null
                                          : () async {
                                              final success = await provider.setPrimaryAccount(account.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Primary account updated'
                                                          : 'Failed to update primary account',
                                                    ),
                                                    backgroundColor:
                                                        success ? AppColors.success : AppColors.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                    ),
                                  )),
                            ],
                          ),
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageBankAccountScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadBankAccounts();
                  }
                },
                icon: Icon(Icons.add),
                label: Text('Add Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, BankAccountModel account) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bank Account'),
        content: Text(
          'Are you sure you want to delete ${account.bankName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(
    BuildContext context,
    BankAccountModel account, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onSetPrimary,
  }) {
    return InkWell(
      onTap: () => _showBankAccountOptions(context, account, onEdit, onDelete, onSetPrimary),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: account.isPrimary ? AppColors.primaryBlue : Colors.grey.shade300,
            width: account.isPrimary ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance, color: AppColors.primaryBlue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    account.displayAccountNumber,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (account.isPrimary)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Primary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(width: 8),
            Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showBankAccountOptions(
    BuildContext context,
    BankAccountModel account,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onSetPrimary,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryBlue),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            if (!account.isPrimary)
              ListTile(
                leading: Icon(Icons.star, color: AppColors.warning),
                title: Text('Set as Primary'),
                onTap: () {
                  Navigator.pop(context);
                  onSetPrimary?.call();
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
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
            InkWell(
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'support@tcc.com',
                );
                try {
                  final bool canLaunch = await canLaunchUrl(emailUri);
                  if (canLaunch) {
                    await launchUrl(emailUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No email app found. Contact: support@tcc.com'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email: support@tcc.com'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: ListTile(
                leading: Icon(Icons.email, color: AppColors.primaryBlue),
                title: Text('Email'),
                subtitle: Text('support@tcc.com'),
                contentPadding: EdgeInsets.zero,
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
            InkWell(
              onTap: () async {
                final Uri phoneUri = Uri(
                  scheme: 'tel',
                  path: '+232123456789',
                );
                try {
                  final bool canLaunch = await canLaunchUrl(phoneUri);
                  if (canLaunch) {
                    await launchUrl(phoneUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No phone app found. Call: +232 123 456 789'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phone: +232 123 456 789'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: ListTile(
                leading: Icon(Icons.phone, color: AppColors.primaryBlue),
                title: Text('Phone'),
                subtitle: Text('+232 123 456 789'),
                contentPadding: EdgeInsets.zero,
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
            InkWell(
              onTap: () async {
                final Uri whatsappUri = Uri.parse('https://wa.me/232123456789');
                try {
                  final bool canLaunch = await canLaunchUrl(whatsappUri);
                  if (canLaunch) {
                    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('WhatsApp not installed. Number: +232 123 456 789'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('WhatsApp: +232 123 456 789'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: ListTile(
                leading: Icon(Icons.chat, color: AppColors.primaryBlue),
                title: Text('WhatsApp'),
                subtitle: Text('+232 123 456 789'),
                contentPadding: EdgeInsets.zero,
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
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

  static bool _isKycInProgress(String kycStatus) {
    final status = kycStatus.toUpperCase();
    return status == 'PENDING' ||
           status == 'PROCESSING' ||
           status == 'IN_PROGRESS' ||
           status == 'SUBMITTED';
  }

  static Color _getKycBannerColor(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return AppColors.warning;
      case 'REJECTED':
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }

  static IconData _getKycIcon(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return Icons.access_time;
      case 'REJECTED':
      case 'FAILED':
        return Icons.error_outline;
      default:
        return Icons.verified_user_outlined;
    }
  }

  static String _getKycTitle(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return 'KYC Verification in Progress';
      case 'REJECTED':
      case 'FAILED':
        return 'KYC Verification Failed';
      default:
        return 'Complete KYC Verification';
    }
  }

  static String _getKycMessage(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return 'Your documents are being reviewed. This usually takes 1-2 business days';
      case 'REJECTED':
      case 'FAILED':
        return 'Please resubmit your documents';
      default:
        return 'Verify your identity to access all features';
    }
  }
}
