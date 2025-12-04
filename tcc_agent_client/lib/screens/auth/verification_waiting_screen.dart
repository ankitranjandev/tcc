import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';

class VerificationWaitingScreen extends StatefulWidget {
  const VerificationWaitingScreen({super.key});

  @override
  State<VerificationWaitingScreen> createState() => _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends State<VerificationWaitingScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();

    if (!mounted) return;

    setState(() => _isRefreshing = false);

    // Check if verification status has changed
    if (!authProvider.isPendingVerification) {
      if (authProvider.isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account verified! You can now start working as an agent.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.go('/dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification still pending. We\'ll notify you once approved.'),
          backgroundColor: AppColors.infoBlue,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions_outlined,
                      size: 60,
                      color: AppColors.warningOrange,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Header
                  Text(
                    'Verification Pending',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Thank you for registering as a TCC Agent!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.schedule,
                                color: AppColors.warningOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verification Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppConstants.verificationWaitTime} Hours',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: AppColors.borderLight),
                        const SizedBox(height: 20),
                        _buildStatusItem(
                          Icons.check_circle,
                          'Registration',
                          'Completed',
                          AppColors.successGreen,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          Icons.check_circle,
                          'KYC Documents',
                          'Submitted',
                          AppColors.successGreen,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          Icons.check_circle,
                          'Bank Details',
                          'Submitted',
                          AppColors.successGreen,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          Icons.pending,
                          'Admin Verification',
                          'Pending',
                          AppColors.warningOrange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info Boxes
                  _buildInfoBox(
                    icon: Icons.hourglass_empty,
                    title: 'What\'s Next?',
                    description: 'Our admin team is reviewing your documents. This usually takes 24-48 hours.',
                    color: AppColors.infoBlue,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoBox(
                    icon: Icons.notifications_active_outlined,
                    title: 'We\'ll Notify You',
                    description: 'You\'ll receive an email and SMS notification once your account is verified.',
                    color: AppColors.secondaryTeal,
                  ),

                  const SizedBox(height: 32),

                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRefreshing ? 'Checking...' : 'Check Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),

                  const SizedBox(height: 32),

                  // Support Info
                  Text(
                    'Need help? Contact support at support@tcc.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String title, String status, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
