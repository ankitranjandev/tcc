import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock data
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'transaction',
      'title': 'Transaction Completed',
      'message': 'You earned SLL 25,000 commission from transaction TXN123456',
      'date': DateTime.now().subtract(const Duration(minutes: 15)),
      'read': false,
      'icon': Icons.account_balance_wallet,
      'color': AppColors.successGreen,
    },
    {
      'id': '2',
      'type': 'order',
      'title': 'New Payment Order',
      'message': 'You have a new payment order from Alice Johnson - SLL 500,000',
      'date': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
      'icon': Icons.assignment,
      'color': AppColors.warningOrange,
    },
    {
      'id': '3',
      'type': 'credit',
      'title': 'Credit Request Approved',
      'message': 'Your credit request for SLL 5,000,000 has been approved',
      'date': DateTime.now().subtract(const Duration(hours: 3)),
      'read': true,
      'icon': Icons.check_circle,
      'color': AppColors.successGreen,
    },
    {
      'id': '4',
      'type': 'verification',
      'title': 'Account Verified',
      'message': 'Congratulations! Your agent account has been verified',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'icon': Icons.verified_user,
      'color': AppColors.infoBlue,
    },
    {
      'id': '5',
      'type': 'commission',
      'title': 'Weekly Commission Summary',
      'message': 'You earned SLL 125,000 in commissions this week',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
      'icon': Icons.trending_up,
      'color': AppColors.commissionGreen,
    },
  ];

  int get _unreadCount => _notifications.where((n) => !n['read']).length;

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        backgroundColor: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh notifications from API
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length + 1, // +1 for unread count banner
                itemBuilder: (context, index) {
                  if (index == 0 && _unreadCount > 0) {
                    return _buildUnreadBanner();
                  }

                  final notificationIndex = _unreadCount > 0 ? index - 1 : index;
                  if (notificationIndex >= _notifications.length) {
                    return const SizedBox();
                  }

                  return _buildNotificationCard(_notifications[notificationIndex]);
                },
              ),
            ),
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Unread notification${_unreadCount > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;
    final date = notification['date'] as DateTime;
    final icon = notification['icon'] as IconData;
    final color = notification['color'] as Color;

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isRead ? 0 : 2,
        color: isRead ? AppColors.backgroundLight : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRead ? AppColors.borderLight : color.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(notification['id']);
            }
            // Handle notification tap - navigate to relevant screen
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.errorRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
