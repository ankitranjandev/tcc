import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';

/// Topbar Component
class Topbar extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const Topbar({super.key, this.onMenuPressed});

  @override
  State<Topbar> createState() => _TopbarState();
}

class _TopbarState extends State<Topbar> {
  final _notificationButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isMobile = context.isMobile;

    return Container(
      height: AppTheme.topbarHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gray200,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.space16 : AppTheme.space32,
      ),
      child: Row(
        children: [
          // Hamburger Menu (mobile/tablet only)
          if (widget.onMenuPressed != null) ...[
            IconButton(
              icon: Icon(Icons.menu, color: AppColors.gray700),
              onPressed: widget.onMenuPressed,
              tooltip: 'Menu',
            ),
            SizedBox(width: isMobile ? AppTheme.space8 : AppTheme.space16),
          ],

          // Page Title (can be dynamic)
          Expanded(
            child: Text(
              isMobile
                  ? 'TCC Admin'
                  : 'Welcome, ${authProvider.admin?.name ?? 'Admin'}',
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Search
          if (!isMobile)
            IconButton(
              icon: Icon(Icons.search, color: AppColors.gray700),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'Search',
            ),

          if (!isMobile) const SizedBox(width: AppTheme.space8),

          // Notifications
          IconButton(
            key: _notificationButtonKey,
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.gray700),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),

          const SizedBox(width: AppTheme.space8),

          // Settings
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.gray700),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),

          const SizedBox(width: AppTheme.space16),

          // User Avatar and Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentBlue,
                child: Text(
                  authProvider.admin?.name.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: AppColors.gray700),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search users, agents, transactions...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.gray500),
                      ),
                      style: const TextStyle(fontSize: 18),
                      onSubmitted: (query) {
                        // TODO: Implement actual search
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Searching for: $query'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppTheme.space16),
              // Quick Links
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildQuickLink(context, Icons.people, 'Users', '/users'),
                  _buildQuickLink(context, Icons.store, 'Agents', '/agents'),
                  _buildQuickLink(context, Icons.receipt_long, 'Transactions', '/transactions'),
                  _buildQuickLink(context, Icons.trending_up, 'Investments', '/investments'),
                  _buildQuickLink(context, Icons.poll, 'E-Voting', '/e-voting'),
                  _buildQuickLink(context, Icons.bar_chart, 'Reports', '/reports'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.space8,
          horizontal: AppTheme.space12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray700),
            const SizedBox(width: AppTheme.space12),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final RenderBox button = _notificationButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [],
      elevation: 8,
    ).then((_) {
      // Menu closed
    });

    // Show custom notification panel
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Notification panel
          Positioned(
            top: AppTheme.topbarHeight + 8,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.space20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Mark all as read
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Mark all read',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Notifications list
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _buildNotificationItem(
                            context,
                            Icons.person_add,
                            'New User Registration',
                            'John Doe has registered and pending KYC approval',
                            DateTime.now().subtract(const Duration(minutes: 5)),
                            true,
                            AppColors.accentBlue,
                          ),
                          _buildNotificationItem(
                            context,
                            Icons.store,
                            'Agent Verification Request',
                            'Agent "ABC Store" submitted documents for verification',
                            DateTime.now().subtract(const Duration(hours: 1)),
                            true,
                            Colors.orange,
                          ),
                          _buildNotificationItem(
                            context,
                            Icons.account_balance_wallet,
                            'Large Transaction Alert',
                            'Transaction of Le 50,000 detected from user ID: USR123',
                            DateTime.now().subtract(const Duration(hours: 2)),
                            false,
                            AppColors.warning,
                          ),
                          _buildNotificationItem(
                            context,
                            Icons.trending_up,
                            'Investment Matured',
                            '5 investments have reached maturity and require payout',
                            DateTime.now().subtract(const Duration(hours: 3)),
                            false,
                            AppColors.success,
                          ),
                          _buildNotificationItem(
                            context,
                            Icons.poll,
                            'Poll Ending Soon',
                            'Community poll "Infrastructure Development" ends in 2 hours',
                            DateTime.now().subtract(const Duration(hours: 4)),
                            false,
                            AppColors.accentPurple,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Footer
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to notifications page
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        alignment: Alignment.center,
                        child: Text(
                          'View All Notifications',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    String title,
    String message,
    DateTime time,
    bool isUnread,
    Color iconColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        // TODO: Navigate to related item
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.accentBlue.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(time),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return Formatters.formatDate(time);
    }
  }
}
