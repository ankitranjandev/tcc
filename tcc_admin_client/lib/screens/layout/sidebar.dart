import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Sidebar Navigation
class Sidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onItemTap;

  const Sidebar({
    super.key,
    required this.currentRoute,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      width: AppTheme.sidebarWidth,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          // Logo and Brand
          Container(
            height: AppTheme.topbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.accentBlue,
                  size: 32,
                ),
                const SizedBox(width: AppTheme.space12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TCC Admin',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: AppColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.gray800, height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space24,
              ),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Users',
                  route: '/users',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store,
                  label: 'Agents',
                  route: '/agents',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Transactions',
                  route: '/transactions',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up,
                  label: 'Investments',
                  route: '/investments',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.receipt_outlined,
                  activeIcon: Icons.receipt,
                  label: 'Bill Payments',
                  route: '/bill-payments',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.how_to_vote_outlined,
                  activeIcon: Icons.how_to_vote,
                  label: 'E-Voting',
                  route: '/e-voting',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Reports',
                  route: '/reports',
                ),
                const SizedBox(height: AppTheme.space8),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),

          // User Profile Section
          const Divider(color: AppColors.gray800, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accentBlue,
                  child: Text(
                    authProvider.admin?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authProvider.admin?.name ?? 'Admin',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authProvider.admin?.role.displayName ?? 'Admin',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: AppColors.gray500,
                  ),
                  onPressed: () {
                    authProvider.logout();
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    int? badge,
  }) {
    final isActive = currentRoute.startsWith(route);

    return InkWell(
      onTap: () {
        context.go(route);
        onItemTap?.call();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.white : AppColors.gray500,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.white : AppColors.gray400,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null && badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  badge > 99 ? '99+' : badge.toString(),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
