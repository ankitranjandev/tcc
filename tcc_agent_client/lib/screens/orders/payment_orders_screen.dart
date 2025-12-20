import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class PaymentOrdersScreen extends StatefulWidget {
  const PaymentOrdersScreen({super.key});

  @override
  State<PaymentOrdersScreen> createState() => _PaymentOrdersScreenState();
}

class _PaymentOrdersScreenState extends State<PaymentOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data
  final List<Map<String, dynamic>> _pendingOrders = [
    {
      'id': 'PO123456',
      'sender_name': 'Alice Johnson',
      'sender_mobile': '232-76-111222',
      'recipient_name': 'Bob Smith',
      'recipient_mobile': '232-76-333444',
      'amount': 500000.0,
      'verification_code': '1234',
      'created_at': DateTime.now().subtract(const Duration(minutes: 15)),
      'status': 'pending',
    },
    {
      'id': 'PO123457',
      'sender_name': 'Charlie Brown',
      'sender_mobile': '232-76-555666',
      'recipient_name': 'Diana Prince',
      'recipient_mobile': '232-76-777888',
      'amount': 750000.0,
      'verification_code': '5678',
      'created_at': DateTime.now().subtract(const Duration(minutes: 45)),
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> _acceptedOrders = [
    {
      'id': 'PO123455',
      'sender_name': 'Eve Wilson',
      'sender_mobile': '232-76-999000',
      'recipient_name': 'Frank Castle',
      'recipient_mobile': '232-76-111999',
      'amount': 300000.0,
      'verification_code': '9012',
      'created_at': DateTime.now().subtract(const Duration(hours: 1)),
      'accepted_at': DateTime.now().subtract(const Duration(minutes: 30)),
      'status': 'accepted',
    },
  ];

  final List<Map<String, dynamic>> _completedOrders = [
    {
      'id': 'PO123454',
      'sender_name': 'Grace Lee',
      'sender_mobile': '232-76-222333',
      'recipient_name': 'Henry Ford',
      'recipient_mobile': '232-76-444555',
      'amount': 1000000.0,
      'verification_code': '3456',
      'created_at': DateTime.now().subtract(const Duration(hours: 3)),
      'completed_at': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'commission': 25000.0,
    },
    {
      'id': 'PO123453',
      'sender_name': 'Ian Wright',
      'sender_mobile': '232-76-666777',
      'recipient_name': 'Julia Roberts',
      'recipient_mobile': '232-76-888999',
      'amount': 450000.0,
      'verification_code': '7890',
      'created_at': DateTime.now().subtract(const Duration(hours: 5)),
      'completed_at': DateTime.now().subtract(const Duration(hours: 4)),
      'status': 'completed',
      'commission': 11250.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Orders'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingOrders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingOrders.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Accepted'),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_pendingOrders, 'pending'),
          _buildOrdersList(_acceptedOrders, 'accepted'),
          _buildOrdersList(_completedOrders, 'completed'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String status) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status == 'pending' ? 'pending' : status == 'accepted' ? 'accepted' : 'completed'} orders',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh orders from API
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], status);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String status) {
    final amount = order['amount'] as double;
    final createdAt = order['created_at'] as DateTime;
    final timeAgo = _getTimeAgo(createdAt);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending';
        break;
      case 'accepted':
        statusColor = AppColors.infoBlue;
        statusIcon = Icons.hourglass_empty;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help_outline;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to order detail screen (route not yet implemented)
          // context.push('/order-detail');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID
                  Text(
                    order['id'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amount
              Text(
                'TCC${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),

              const SizedBox(height: 16),

              // Sender & Recipient
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['sender_name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['recipient_name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: AppColors.borderLight),
              const SizedBox(height: 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (status == 'completed' && order['commission'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.commissionGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TCC${order['commission'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.commissionGreen,
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton(
                      onPressed: () {
                        // Navigate to order detail screen (route not yet implemented)
                        // context.push('/order-detail');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
