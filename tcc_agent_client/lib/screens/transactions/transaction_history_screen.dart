import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'all';

  // Mock data
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN001',
      'type': 'deposit',
      'user_name': 'John Doe',
      'amount': 500000.0,
      'commission': 12500.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'TXN002',
      'type': 'withdrawal',
      'user_name': 'Jane Smith',
      'amount': 300000.0,
      'commission': 7500.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 'TXN003',
      'type': 'transfer',
      'user_name': 'Bob Johnson',
      'amount': 750000.0,
      'commission': 18750.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 'TXN004',
      'type': 'deposit',
      'user_name': 'Alice Williams',
      'amount': 1000000.0,
      'commission': 25000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'TXN005',
      'type': 'credit_request',
      'user_name': 'TCC Wallet',
      'amount': 5000000.0,
      'commission': 0.0,
      'status': 'approved',
      'date': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((txn) {
      if (_selectedFilter == 'all') return true;
      return txn['type'] == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.backgroundLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Deposits', 'deposit'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Withdrawals', 'withdrawal'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Transfers', 'transfer'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Credits', 'credit_request'),
                ],
              ),
            ),
          ),

          // Stats Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrangeLight,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Transactions',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_filteredTransactions.length}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Commission',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TCC${_calculateTotalCommission().toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_filteredTransactions[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primaryOrange,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = transaction['amount'] as double;
    final commission = transaction['commission'] as double;
    final date = transaction['date'] as DateTime;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'deposit':
        icon = Icons.add_circle_outline;
        iconColor = AppColors.successGreen;
        break;
      case 'withdrawal':
        icon = Icons.remove_circle_outline;
        iconColor = AppColors.errorRed;
        break;
      case 'transfer':
        icon = Icons.swap_horiz;
        iconColor = AppColors.infoBlue;
        break;
      case 'credit_request':
        icon = Icons.account_balance_wallet;
        iconColor = AppColors.secondaryTeal;
        break;
      default:
        icon = Icons.circle_outlined;
        iconColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),

            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['user_name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'TCC${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['id'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (commission > 0)
                        Text(
                          'Commission: SLL ${commission.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.commissionGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
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

  double _calculateTotalCommission() {
    return _filteredTransactions.fold(
      0.0,
      (sum, txn) => sum + (txn['commission'] as double),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add more filter options here
            Text('More filters coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
