import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../utils/date_utils.dart' as date_utils;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();

  // Data state
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  Set<String> selectedTypes = {};
  DateTimeRange? dateRange;
  double? minAmount;
  double? maxAmount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _transactionService.getTransactionHistory(
        limit: 100, // Load more transactions
      );

      if (result['success']) {
        final data = result['data']['data'];
        final transactionsData = data['transactions'] as List;

        setState(() {
          _allTransactions = transactionsData
              .map((json) => TransactionModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load transactions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
              ),
              if (selectedTypes.isNotEmpty || dateRange != null || minAmount != null || maxAmount != null)
                Positioned(
                  right: 8,
                  top: 8,
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
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Successful'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: _isLoading && _allTransactions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null && _allTransactions.isEmpty
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(_applyFilters(_allTransactions)),
                    _buildTransactionList(_applyFilters(_allTransactions
                        .where((t) => t.status == 'COMPLETED')
                        .toList())),
                    _buildTransactionList(_applyFilters(_allTransactions
                        .where((t) => t.status == 'PENDING')
                        .toList())),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(
            'Failed to load transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Theme.of(context).disabledColor),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isCredit = transaction.isCredit;
    final currencyFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 2);

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/transactions/${transaction.id}', extra: transaction);
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCredit
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: isCredit ? AppColors.success : AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description ?? 'Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (transaction.recipient != null)
              Text(
                transaction.recipient!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            if (transaction.accountInfo != null)
              Text(
                transaction.accountInfo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            SizedBox(height: 4),
            Text(
              date_utils.DateUtils.formatTransactionDate(transaction.date),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(
                  alpha: date_utils.DateUtils.isValidDate(transaction.date) ? 1.0 : 0.5,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : ''}${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCredit ? AppColors.success : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(context, transaction.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(context, transaction.status),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      // Type filter
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(transaction.type)) {
        return false;
      }

      // Date range filter
      if (dateRange != null) {
        if (transaction.date.isBefore(dateRange!.start) ||
            transaction.date.isAfter(dateRange!.end.add(Duration(days: 1)))) {
          return false;
        }
      }

      // Amount range filter
      final amount = transaction.amount.abs();
      if (minAmount != null && amount < minAmount!) {
        return false;
      }
      if (maxAmount != null && amount > maxAmount!) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Handle
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedTypes.clear();
                              dateRange = null;
                              minAmount = null;
                              maxAmount = null;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: Text('Clear All'),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Transaction Type Filter
                        Text(
                          'Transaction Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip('DEPOSIT', 'Deposit', setModalState),
                            _buildFilterChip('WITHDRAWAL', 'Withdrawal', setModalState),
                            _buildFilterChip('TRANSFER', 'Transfer', setModalState),
                            _buildFilterChip('BILL_PAYMENT', 'Bill Payment', setModalState),
                            _buildFilterChip('INVESTMENT', 'Investment', setModalState),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Date Range Filter
                        Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: dateRange,
                            );
                            if (picked != null) {
                              setModalState(() {
                                dateRange = picked;
                              });
                            }
                          },
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            dateRange == null
                                ? 'Select Date Range'
                                : '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange!.end)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.all(16),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        if (dateRange != null) ...[
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                dateRange = null;
                              });
                            },
                            icon: Icon(Icons.clear, size: 16),
                            label: Text('Clear Date Range'),
                          ),
                        ],
                        SizedBox(height: 24),

                        // Amount Range Filter
                        Text(
                          'Amount Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Min Amount',
                                  prefixText: 'TCC',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    minAmount = double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Max Amount',
                                  prefixText: 'TCC',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    maxAmount = double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Apply Button
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Apply Filters'),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, StateSetter setModalState) {
    final isSelected = selectedTypes.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          if (selected) {
            selectedTypes.add(value);
          } else {
            selectedTypes.remove(value);
          }
        });
      },
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : Colors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'DEPOSIT':
        return Icons.add_circle_outline;
      case 'WITHDRAWAL':
        return Icons.remove_circle_outline;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'BILL_PAYMENT':
        return Icons.receipt;
      case 'INVESTMENT':
        return Icons.trending_up;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }
}
