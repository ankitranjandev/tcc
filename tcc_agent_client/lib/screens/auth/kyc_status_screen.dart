import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';
import 'dart:async';

class KYCStatusScreen extends StatefulWidget {
  const KYCStatusScreen({super.key});

  @override
  State<KYCStatusScreen> createState() => _KYCStatusScreenState();
}

class _KYCStatusScreenState extends State<KYCStatusScreen> {
  Timer? _statusCheckTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
    _checkInitialStatus();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    // Poll every 30 seconds for status updates
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshStatus();
    });
  }

  Future<void> _checkInitialStatus() async {
    await _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfile();

      // Check if status changed to approved
      if (authProvider.agent?.kycStatus == 'APPROVED') {
        _statusCheckTimer?.cancel();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('KYC Approved! Redirecting to dashboard...'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        context.go('/dashboard');
      }
    } catch (e) {
      // Error refreshing status - silently ignore
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleReupload() {
    // Navigate back to KYC verification screen to reupload documents
    context.go('/kyc-verification');
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _navigateToDashboard() {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'KYC Verification Status',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isMobile ? 20 : 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _isRefreshing ? null : _refreshStatus,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final agent = authProvider.agent;
          final kycStatus = agent?.kycStatus ?? 'PENDING';
          final rejectionReason = agent?.rejectionReason;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusIcon(kycStatus),
                      const SizedBox(height: 32),
                      _buildStatusTitle(kycStatus),
                      const SizedBox(height: 16),
                      _buildStatusMessage(kycStatus, rejectionReason),
                      const SizedBox(height: 32),
                      _buildStatusCard(kycStatus, agent?.firstName, agent?.lastName),
                      const SizedBox(height: 24),
                      _buildTimelineProgress(kycStatus),
                      const SizedBox(height: 40),
                      _buildActionButtons(kycStatus),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (status) {
      case 'APPROVED':
        iconData = Icons.check_circle;
        iconColor = AppColors.successGreen;
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        break;
      case 'REJECTED':
        iconData = Icons.cancel;
        iconColor = AppColors.errorRed;
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.1);
        break;
      case 'SUBMITTED':
      case 'PENDING':
      default:
        iconData = Icons.access_time;
        iconColor = AppColors.primaryOrange;
        backgroundColor = AppColors.primaryOrange.withValues(alpha: 0.1);
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 50,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusTitle(String status) {
    String title;
    Color textColor;

    switch (status) {
      case 'APPROVED':
        title = 'KYC Approved!';
        textColor = AppColors.successGreen;
        break;
      case 'REJECTED':
        title = 'KYC Rejected';
        textColor = AppColors.errorRed;
        break;
      case 'SUBMITTED':
        title = 'Under Review';
        textColor = AppColors.primaryOrange;
        break;
      case 'PENDING':
      default:
        title = 'Verification Pending';
        textColor = AppColors.primaryOrange;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildStatusMessage(String status, String? rejectionReason) {
    String message;

    switch (status) {
      case 'APPROVED':
        message = 'Congratulations! Your KYC verification has been approved. You can now access all features.';
        break;
      case 'REJECTED':
        message = rejectionReason != null && rejectionReason.isNotEmpty
            ? 'Reason: $rejectionReason\n\nPlease review the issue and resubmit your documents.'
            : 'Your KYC verification was rejected. Please resubmit your documents with the required corrections.';
        break;
      case 'SUBMITTED':
        message = 'Your documents are being reviewed by our admin team. This usually takes 24-48 hours.';
        break;
      case 'PENDING':
      default:
        message = 'Your KYC verification is pending. Please submit your documents to proceed.';
    }

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildStatusCard(String status, String? firstName, String? lastName) {
    final userName = firstName != null && lastName != null
        ? '$firstName $lastName'
        : 'Agent';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'KYC Status: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'APPROVED':
        label = 'Verified';
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.2);
        textColor = AppColors.successGreen;
        break;
      case 'REJECTED':
        label = 'Rejected';
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.2);
        textColor = AppColors.errorRed;
        break;
      case 'SUBMITTED':
        label = 'Under Review';
        backgroundColor = AppColors.primaryOrange.withValues(alpha: 0.2);
        textColor = AppColors.primaryOrange;
        break;
      case 'PENDING':
      default:
        label = 'Pending';
        backgroundColor = AppColors.warningYellow.withValues(alpha: 0.2);
        textColor = AppColors.warningYellow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTimelineProgress(String status) {
    final steps = [
      {'label': 'Registration', 'completed': true},
      {'label': 'Document Submission', 'completed': status != 'PENDING'},
      {'label': 'Admin Review', 'completed': status == 'APPROVED'},
      {'label': 'Verification Complete', 'completed': status == 'APPROVED'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.map((step) => _buildTimelineItem(
          step['label'] as String,
          step['completed'] as bool,
        )),
      ],
    );
  }

  Widget _buildTimelineItem(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? AppColors.successGreen
                  : AppColors.borderLight,
            ),
            child: completed
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: completed
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (completed)
            Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.successGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    switch (status) {
      case 'APPROVED':
        return ElevatedButton(
          onPressed: _navigateToDashboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Go to Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case 'REJECTED':
        return Column(
          children: [
            ElevatedButton(
              onPressed: _handleReupload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Re-upload Documents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _handleLogout,
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );

      case 'SUBMITTED':
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isRefreshing ? null : _refreshStatus,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                _isRefreshing ? 'Checking...' : 'Check Status',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Auto-refreshing every 30 seconds',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );

      case 'PENDING':
      default:
        return ElevatedButton(
          onPressed: () => context.go('/kyc-verification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Submit KYC Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}