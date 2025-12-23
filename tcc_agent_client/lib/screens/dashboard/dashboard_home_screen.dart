import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/agent_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _isActive = true; // Mock status - in real app, this comes from agent model

  // Mock data (will be replaced with real data from API)
  final double _todayEarnings = 125000; // SLL
  final int _todayTransactions = 12;
  final int _pendingOrders = 3;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _toggleStatus() {
    setState(() => _isActive = !_isActive);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isActive ? 'You are now Active and visible to users' : 'You are now Inactive',
        ),
        backgroundColor: _isActive ? AppColors.successGreen : AppColors.textSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showKycRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.warningOrange),
            const SizedBox(width: 12),
            const Text('KYC Required'),
          ],
        ),
        content: const Text(
          'You need to complete your KYC verification to use this feature. Please complete your KYC submission and wait for admin approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/kyc-status');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Check KYC Status'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final agent = authProvider.agent;
    final isKycApproved = authProvider.isKycApproved;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryOrange,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryOrangeDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Good ${_getGreeting()}, ${agent?.firstName ?? 'Agent'}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.white.withValues(alpha: 0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TCC${(agent?.walletBalance ?? 0).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: AppColors.white.withValues(alpha: 0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _toggleStatus,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: (_isActive ? AppColors.successGreen : AppColors.textSecondary)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isActive ? AppColors.successGreen : AppColors.textSecondary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _isActive ? AppColors.successGreen : AppColors.textSecondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: _isActive ? AppColors.successGreen : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: AppColors.white, size: 22),
                                  onPressed: () {
                                    context.push('/notifications');
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KYC Status Banner
                if (!isKycApproved) ...[
                  _buildKycStatusBanner(agent),
                  const SizedBox(height: 16),
                ],

                // Wallet Balance Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.primaryOrangeLight,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wallet Balance',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.account_balance_wallet,
                              color: AppColors.white.withValues(alpha: 0.9),
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'TCC${(agent?.walletBalance ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: isKycApproved
                            ? () {
                                context.push('/credit-request');
                              }
                            : _showKycRequiredDialog,
                          icon: Icon(
                            isKycApproved ? Icons.add : Icons.lock_outline,
                            size: 20,
                          ),
                          label: Text(isKycApproved ? 'Request Credit' : 'KYC Required'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: isKycApproved
                              ? AppColors.primaryOrange
                              : AppColors.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Today's Stats
                Text(
                  "Today's Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        title: 'Earnings',
                        value: 'TCC$_todayEarnings',
                        color: AppColors.commissionGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt_long,
                        title: 'Transactions',
                        value: '$_todayTransactions',
                        color: AppColors.infoBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: isMobile ? 2 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Add Money',
                      subtitle: isKycApproved ? 'To User Account' : 'KYC Required',
                      color: AppColors.successGreen,
                      isLocked: !isKycApproved,
                      onTap: () {
                        if (isKycApproved) {
                          context.push('/add-money');
                        } else {
                          _showKycRequiredDialog();
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.assignment,
                      title: 'Payment Orders',
                      subtitle: isKycApproved ? '$_pendingOrders Pending' : 'KYC Required',
                      color: AppColors.warningOrange,
                      isLocked: !isKycApproved,
                      onTap: () {
                        if (isKycApproved) {
                          context.push('/payment-orders');
                        } else {
                          _showKycRequiredDialog();
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.history,
                      title: 'History',
                      subtitle: isKycApproved ? 'View Transactions' : 'KYC Required',
                      color: AppColors.infoBlue,
                      isLocked: !isKycApproved,
                      onTap: () {
                        if (isKycApproved) {
                          context.push('/transaction-history');
                        } else {
                          _showKycRequiredDialog();
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.account_balance,
                      title: 'Commission',
                      subtitle: isKycApproved ? 'View Earnings' : 'KYC Required',
                      color: AppColors.secondaryTeal,
                      isLocked: !isKycApproved,
                      onTap: () {
                        if (isKycApproved) {
                          context.push('/commission-dashboard');
                        } else {
                          _showKycRequiredDialog();
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 80), // Extra space for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycStatusBanner(AgentModel? agent) {
    final kycStatus = agent?.kycStatus ?? 'PENDING';

    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    switch (kycStatus) {
      case 'PENDING':
        backgroundColor = AppColors.warningOrange.withValues(alpha: 0.1);
        iconColor = AppColors.warningOrange;
        icon = Icons.pending_actions;
        title = 'KYC Verification Pending';
        message = 'Please complete your KYC verification to access all features.';
        break;
      case 'SUBMITTED':
        backgroundColor = AppColors.infoBlue.withValues(alpha: 0.1);
        iconColor = AppColors.infoBlue;
        icon = Icons.hourglass_empty;
        title = 'KYC Under Review';
        message = 'Your KYC documents are being reviewed. You will be notified once approved.';
        break;
      case 'REJECTED':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        iconColor = Colors.red;
        icon = Icons.cancel;
        title = 'KYC Rejected';
        message = 'Your KYC was rejected. Please resubmit with correct information.';
        break;
      default:
        backgroundColor = AppColors.warningOrange.withValues(alpha: 0.1);
        iconColor = AppColors.warningOrange;
        icon = Icons.warning;
        title = 'KYC Required';
        message = 'Complete your KYC verification to access features.';
    }

    return Card(
      elevation: 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => context.push('/kyc-status'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: iconColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
