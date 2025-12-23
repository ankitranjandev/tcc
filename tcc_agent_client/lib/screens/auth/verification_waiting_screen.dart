import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/kyc_service.dart';
import '../../utils/responsive_helper.dart';

class VerificationWaitingScreen extends StatefulWidget {
  const VerificationWaitingScreen({super.key});

  @override
  State<VerificationWaitingScreen> createState() =>
      _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends State<VerificationWaitingScreen> {
  final _kycService = KYCService();
  bool _isRefreshing = false;
  bool _isLoading = true;
  String _kycStatus = 'PENDING';
  List<Map<String, dynamic>> _documents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }

  Future<void> _loadKYCStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _kycService.getKYCStatus();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _kycStatus = data['kyc_status'] ?? 'PENDING';
          _documents = List<Map<String, dynamic>>.from(data['documents'] ?? []);
          _isLoading = false;
        });

        // If approved, navigate to dashboard
        if (_kycStatus == 'APPROVED') {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.refreshProfile();
          // Router will handle automatic navigation based on auth state
        }
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load KYC status';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    await _loadKYCStatus();

    if (!mounted) return;

    setState(() => _isRefreshing = false);

    // Show appropriate message based on status
    if (_kycStatus == 'APPROVED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account verified! You can now start working as an agent.',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else if (_kycStatus == 'REJECTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your KYC has been rejected. Please resubmit.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Verification still pending. We\'ll notify you once approved.',
          ),
          backgroundColor: AppColors.infoBlue,
        ),
      );
    }
  }

  void _handleResubmit() {
    // Navigate back to KYC screen to resubmit
    context.go('/kyc-verification');
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
      // Router will handle automatic navigation to login
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadKYCStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
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
                            color:
                                (_kycStatus == 'APPROVED'
                                        ? AppColors.successGreen
                                        : _kycStatus == 'REJECTED'
                                        ? AppColors.errorRed
                                        : AppColors.warningOrange)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _kycStatus == 'APPROVED'
                                ? Icons.check_circle_outline
                                : _kycStatus == 'REJECTED'
                                ? Icons.cancel_outlined
                                : Icons.pending_actions_outlined,
                            size: 60,
                            color: _kycStatus == 'APPROVED'
                                ? AppColors.successGreen
                                : _kycStatus == 'REJECTED'
                                ? AppColors.errorRed
                                : AppColors.warningOrange,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Header
                        Text(
                          _kycStatus == 'APPROVED'
                              ? 'Verification Approved!'
                              : _kycStatus == 'REJECTED'
                              ? 'Verification Rejected'
                              : 'Verification Pending',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _kycStatus == 'APPROVED'
                              ? 'Congratulations! Your account has been verified.'
                              : _kycStatus == 'REJECTED'
                              ? 'Please review the issues and resubmit your documents.'
                              : 'Thank you for registering as a TCC Agent!',
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
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningOrange.withValues(
                                        alpha: 0.1,
                                      ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

                        // Rejection Reasons (if rejected)
                        if (_kycStatus == 'REJECTED') ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.errorRed.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppColors.errorRed,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Rejection Reasons',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._documents
                                    .where(
                                      (doc) =>
                                          doc['status'] == 'REJECTED' &&
                                          doc['rejection_reason'] != null &&
                                          (doc['rejection_reason'] as String)
                                              .isNotEmpty,
                                    )
                                    .map((doc) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              margin: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.errorRed,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                doc['rejection_reason'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Info Boxes
                        if (_kycStatus != 'REJECTED') ...[
                          _buildInfoBox(
                            icon: Icons.hourglass_empty,
                            title: 'What\'s Next?',
                            description:
                                'Our admin team is reviewing your documents. This usually takes 24-48 hours.',
                            color: AppColors.infoBlue,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoBox(
                            icon: Icons.notifications_active_outlined,
                            title: 'We\'ll Notify You',
                            description:
                                'You\'ll receive an email and SMS notification once your account is verified.',
                            color: AppColors.secondaryTeal,
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons
                          if (_kycStatus == 'REJECTED') ...[
                            ElevatedButton.icon(
                              onPressed: _handleResubmit,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Resubmit Documents'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ] else if (_kycStatus == 'APPROVED') ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to dashboard (router will handle)
                                context.go('/dashboard');
                              },
                              icon: const Icon(Icons.dashboard),
                              label: const Text('Go to Dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: _isRefreshing ? null : _handleRefresh,
                              icon: _isRefreshing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(
                                _isRefreshing ? 'Checking...' : 'Check Status',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],

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
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusItem(
    IconData icon,
    String title,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
