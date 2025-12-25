import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../services/dashboard_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/cards/stat_card.dart';

/// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic>? _stats;
  final List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch dashboard stats
      final statsResponse = await _dashboardService.getDashboardStats();

      if (statsResponse.success && statsResponse.data != null) {
        setState(() {
          _stats = statsResponse.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = statsResponse.message ?? 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: isMobile
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.displaySmall,
                      ),
                      SizedBox(height: isMobile ? AppTheme.space4 : AppTheme.space8),
                      Text(
                        'Overview of your admin panel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: isMobile ? 14 : null,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            SizedBox(height: isMobile ? AppTheme.space20 : AppTheme.space32),

            // KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = Responsive.gridColumns(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 5,
                );
                final spacing = isMobile ? AppTheme.space16 : AppTheme.space24;
                // Lower aspect ratio = taller cards (aspectRatio = width/height)
                final aspectRatio = isMobile ? 1.6 : 1.2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: aspectRatio,
                  children: [
                    StatCard(
                      title: 'Total Users',
                      value: Formatters.formatNumber(stats['totalUsers'] ?? 0),
                      icon: Icons.people,
                      iconColor: AppColors.accentBlue,
                      change: null, // Backend doesn't provide growth yet
                    ),
                    StatCard(
                      title: 'Active Agents',
                      value: Formatters.formatNumber(stats['activeAgents'] ?? 0),
                      icon: Icons.store,
                      iconColor: Colors.orange,
                      change: null,
                    ),
                    StatCard(
                      title: 'Total Transactions',
                      value: Formatters.formatNumber(stats['totalTransactions'] ?? 0),
                      icon: Icons.receipt_long,
                      iconColor: Colors.purple,
                      change: null,
                    ),
                    StatCard(
                      title: 'Total Revenue',
                      value: Formatters.formatCurrencyCompact(
                        (stats['totalRevenue'] ?? 0).toDouble(),
                      ),
                      icon: Icons.attach_money,
                      iconColor: AppColors.success,
                      change: null,
                    ),
                    StatCard(
                      title: 'Pending KYC',
                      value: Formatters.formatNumber(stats['pendingKycCount'] ?? 0),
                      icon: Icons.pending_actions,
                      iconColor: AppColors.warning,
                      change: null,
                      onTap: () {
                        context.go('/kyc-submissions');
                      },
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: isMobile ? AppTheme.space20 : AppTheme.space32),

            // Today's Stats Row
            Container(
              padding: EdgeInsets.all(
                isMobile ? AppTheme.space16 : AppTheme.space24,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [AppColors.shadowSmall],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Performance",
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTodayStatItem(
                          context,
                          icon: Icons.receipt,
                          label: 'Transactions',
                          value: Formatters.formatNumber(stats['todayTransactions'] ?? 0),
                          color: Colors.purple,
                        ),
                      ),
                      if (!isMobile) ...[
                        SizedBox(width: AppTheme.space24),
                        Expanded(
                          child: _buildTodayStatItem(
                            context,
                            icon: Icons.attach_money,
                            label: 'Revenue',
                            value: Formatters.formatCurrency((stats['todayRevenue'] ?? 0).toDouble()),
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isMobile) ...[
                    SizedBox(height: AppTheme.space16),
                    _buildTodayStatItem(
                      context,
                      icon: Icons.attach_money,
                      label: 'Revenue',
                      value: Formatters.formatCurrency((stats['todayRevenue'] ?? 0).toDouble()),
                      color: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: isMobile ? AppTheme.space20 : AppTheme.space32),

            // Quick Actions Section
            Flex(
              direction: isMobile || isTablet ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                isMobile || isTablet
                    ? _buildQuickActionsCard(context, stats)
                    : Expanded(
                        flex: 1,
                        child: _buildQuickActionsCard(context, stats),
                      ),

                SizedBox(
                  width: isMobile || isTablet ? 0 : AppTheme.space24,
                  height: isMobile || isTablet ? AppTheme.space20 : 0,
                ),

                // Recent Activity (Placeholder for now)
                isMobile || isTablet
                    ? _buildRecentActivityCard(context, _recentActivity)
                    : Expanded(
                        flex: 2,
                        child: _buildRecentActivityCard(context, _recentActivity),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            icon,
            color: color,
            size: context.isMobile ? 20 : 24,
          ),
        ),
        SizedBox(width: context.isMobile ? AppTheme.space12 : AppTheme.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.isMobile ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.isMobile ? AppTheme.space20 : AppTheme.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: context.isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.isMobile ? AppTheme.space16 : AppTheme.space20),
          _buildQuickActionItem(
            context,
            icon: Icons.check_circle_outline,
            label: 'Pending KYC',
            count: stats['pendingKYC'] ?? 0,
            color: AppColors.warning,
            onTap: () {
              context.go('/kyc-submissions');
            },
          ),
          const Divider(),
          _buildQuickActionItem(
            context,
            icon: Icons.payments_outlined,
            label: 'Pending Withdrawals',
            count: stats['pendingWithdrawals'] ?? 0,
            color: AppColors.error,
            onTap: () {
              // TODO: Navigate to withdrawals
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context,
    List<Map<String, dynamic>> recentActivity,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.isMobile ? AppTheme.space20 : AppTheme.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // View all activities
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: context.isMobile ? 13 : 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.isMobile ? AppTheme.space16 : AppTheme.space20),
          if (recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentActivity.map((activity) {
              final color = _getActivityColor(activity['color']);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: context.isMobile ? AppTheme.space12 : AppTheme.space16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActivityIcon(activity['icon']),
                        color: color,
                        size: context.isMobile ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: context.isMobile ? AppTheme.space8 : AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['message'],
                            style: TextStyle(
                              fontSize: context.isMobile ? 13 : 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatRelativeTime(
                              activity['timestamp'],
                            ),
                            style: TextStyle(
                              fontSize: context.isMobile ? 11 : 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.isMobile ? AppTheme.space4 : AppTheme.space8,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: context.isMobile ? 20 : 24,
            ),
            SizedBox(width: context.isMobile ? AppTheme.space8 : AppTheme.space12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.isMobile ? 13 : 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 8 : 12,
                vertical: context.isMobile ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: context.isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String colorName) {
    switch (colorName) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'payments':
        return Icons.payments;
      case 'person_add':
        return Icons.person_add;
      case 'account_balance':
        return Icons.account_balance;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }
}
