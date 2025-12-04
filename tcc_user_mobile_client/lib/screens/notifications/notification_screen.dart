import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all as read',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 14,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(showAll: true),
          _buildNotificationList(showAll: false),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required bool showAll}) {
    // Sample notifications - replace with actual data
    final notifications = [
      {
        'title': 'Investment Matured',
        'message': 'Your Fixed Deposit of ₹50,000 has matured.',
        'time': '2 hours ago',
        'isRead': false,
        'type': 'investment',
      },
      {
        'title': 'Payment Received',
        'message': 'You received ₹15,000 from John Doe',
        'time': '5 hours ago',
        'isRead': true,
        'type': 'payment',
      },
      {
        'title': 'Gift Sent Successfully',
        'message': 'Your gift of ₹5,000 has been sent to Jane Smith',
        'time': '1 day ago',
        'isRead': true,
        'type': 'gift',
      },
      {
        'title': 'KYC Verification Complete',
        'message': 'Your KYC verification has been successfully completed',
        'time': '2 days ago',
        'isRead': true,
        'type': 'kyc',
      },
      {
        'title': 'New Investment Opportunity',
        'message': 'Check out the new Gold Investment plan with 12% returns',
        'time': '3 days ago',
        'isRead': false,
        'type': 'promo',
      },
    ];

    final filteredNotifications = showAll
        ? notifications
        : notifications.where((n) => !(n['isRead'] as bool)).toList();

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              showAll ? 'No notifications yet' : 'No unread notifications',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: filteredNotifications.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'investment':
        icon = Icons.trending_up;
        iconColor = AppColors.success;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = AppColors.primaryBlue;
        break;
      case 'gift':
        icon = Icons.card_giftcard;
        iconColor = AppColors.secondaryYellow;
        break;
      case 'kyc':
        icon = Icons.verified_user;
        iconColor = AppColors.success;
        break;
      case 'promo':
        icon = Icons.local_offer;
        iconColor = AppColors.secondaryYellow;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.primaryBlue;
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              notification['title']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          if (!notification['isRead'])
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            notification['message']!,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            notification['time']!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      onTap: () {
        // Handle notification tap
        _handleNotificationTap(notification);
      },
    );
  }

  void _markAllAsRead() {
    // Implement mark all as read functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark All as Read'),
        content: Text('Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement API call to mark all as read
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All notifications marked as read')),
              );
              setState(() {});
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Handle different notification types
    switch (notification['type']) {
      case 'investment':
        // Navigate to portfolio/investment details
        break;
      case 'payment':
        // Navigate to transaction details
        break;
      case 'gift':
        // Navigate to gift history
        break;
      case 'kyc':
        // Navigate to profile/KYC status
        break;
      case 'promo':
        // Navigate to investment opportunities
        break;
    }

    // Mark as read if unread
    if (!notification['isRead']) {
      setState(() {
        notification['isRead'] = true;
      });
    }
  }
}