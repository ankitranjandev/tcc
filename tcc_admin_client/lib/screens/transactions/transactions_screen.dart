import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/export_dialog.dart';
import '../../widgets/dialogs/transaction_details_dialog.dart';

/// Transactions List Screen
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _transactionService = TransactionService();
  final _exportService = ExportService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterType = 'All';
  String _filterStatus = 'All';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalTransactions = 0;
  final int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _transactionService.getTransactions(
      page: _currentPage,
      perPage: _pageSize,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _filterType != 'All' ? _filterType : null,
      status: _filterStatus != 'All' ? _filterStatus : null,
    );

    if (response.success && response.data != null) {
      setState(() {
        _transactions = response.data!.data;
        _totalPages = response.data!.totalPages;
        _totalTransactions = response.data!.total;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load transactions';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
    _loadTransactions();
  }

  void _onTypeFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterType = value;
        _currentPage = 1;
      });
      _loadTransactions();
    }
  }

  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
      _loadTransactions();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadTransactions();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadTransactions();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Transactions',
        subtitle: 'Export transaction data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterType != 'All') 'Type': _filterType,
          if (_filterStatus != 'All') 'Status': _filterStatus,
        },
        onExport: (format) async {
          final response = await _exportService.exportTransactions(
            format: format,
            search: _searchQuery.isNotEmpty ? _searchQuery : null,
            type: _filterType == 'All' ? null : _filterType,
            status: _filterStatus == 'All' ? null : _filterStatus,
          );
          
          if (!response.success) {
            throw Exception(response.message ?? 'Export failed');
          }
        },
      ),
    );
  }

  String _convertEnumToUpperSnakeCase(String enumName) {
    // Convert camelCase to UPPER_SNAKE_CASE
    return enumName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(0)}',
    ).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Show loading indicator
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accentBlue),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Loading transactions...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Show error message
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppTheme.space16),
            Text(
              _errorMessage,
              style: TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
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

    final transactions = _transactions;

    // Calculate stats
    final totalAmount = transactions.fold<double>(
      0.0,
      (sum, txn) => sum + txn.amount,
    );
    final pendingCount = transactions.where((t) => _convertEnumToUpperSnakeCase(t.status.name) == 'PENDING').length;
    final completedCount = transactions.where((t) => _convertEnumToUpperSnakeCase(t.status.name) == 'COMPLETED').length;
    final failedCount = transactions.where((t) => _convertEnumToUpperSnakeCase(t.status.name) == 'FAILED').length;

    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Transactions Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Monitor all transactions',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Filter by date range
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Date Range'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space20,
                      vertical: AppTheme.space16,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showExportDialog();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space16,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions Management',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Monitor all transactions across the platform',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Filter by date range
                      },
                      icon: const Icon(Icons.date_range),
                      label: const Text('Date Range'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space20,
                          vertical: AppTheme.space16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showExportDialog();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24,
                          vertical: AppTheme.space16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

          // Stats Cards
          GridView.count(
            crossAxisCount: Responsive.gridColumns(
              context,
              mobile: 1,
              tablet: 2,
              desktop: 5,
            ),
            crossAxisSpacing: AppTheme.space16,
            mainAxisSpacing: AppTheme.space16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 3.5 : (isTablet ? 2.8 : 3.0),
            children: [
              _buildStatCard(
                'Total Transactions',
                transactions.length.toString(),
                Icons.receipt_long,
                Colors.purple,
              ),
              _buildStatCard(
                'Total Volume',
                Formatters.formatCurrencyCompact(totalAmount),
                Icons.attach_money,
                AppColors.success,
              ),
              _buildStatCard(
                'Pending',
                pendingCount.toString(),
                Icons.pending,
                AppColors.warning,
              ),
              _buildStatCard(
                'Completed',
                completedCount.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              _buildStatCard(
                'Failed',
                failedCount.toString(),
                Icons.error,
                AppColors.error,
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

          // Filters and Search
          Container(
            padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [AppColors.shadowSmall],
            ),
            child: Column(
              children: [
                if (isMobile)
                  Column(
                    children: [
                      // Search Bar
                      TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: Icon(Icons.search, color: AppColors.gray500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      // Type Filter
                      DropdownButtonFormField<String>(
                        initialValue: _filterType,
                        decoration: InputDecoration(
                          labelText: 'Transaction Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'INVESTMENT', 'INVESTMENT_RETURN', 'VOTING', 'REFUND', 'COMMISSION', 'AGENT_CREDIT']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.replaceAll('_', ' ')),
                                ))
                            .toList(),
                        onChanged: _onTypeFilterChanged,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      // Status Filter
                      DropdownButtonFormField<String>(
                        initialValue: _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: _onStatusFilterChanged,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search by transaction ID, user ID, or agent ID...',
                            prefixIcon: Icon(Icons.search, color: AppColors.gray500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Type Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterType,
                          decoration: InputDecoration(
                            labelText: 'Transaction Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: ['All', 'DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'INVESTMENT', 'VOTING']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.replaceAll('_', ' ')),
                                  ))
                              .toList(),
                          onChanged: _onTypeFilterChanged,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Status Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Status Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: ['All', 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: _onStatusFilterChanged,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space24),

                // Transactions List
                if (isMobile || isTablet)
                  Column(
                    children: transactions.map((txn) => _buildTransactionCard(txn)).toList(),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Agent',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Fee',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date & Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    rows: transactions.map((txn) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SelectableText(
                              '${txn.id.length >= 12 ? txn.id.substring(0, 12) : txn.id}...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(_convertEnumToUpperSnakeCase(txn.type.name)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTypeIcon(_convertEnumToUpperSnakeCase(txn.type.name)),
                                    color: _getTypeColor(_convertEnumToUpperSnakeCase(txn.type.name)),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _convertEnumToUpperSnakeCase(txn.type.name).replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: _getTypeColor(_convertEnumToUpperSnakeCase(txn.type.name)),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              txn.userId.length >= 8 ? txn.userId.substring(0, 8) : txn.userId,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              txn.agentId != null
                                  ? (txn.agentId!.length >= 8 ? txn.agentId!.substring(0, 8) : txn.agentId!)
                                  : 'N/A',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(txn.amount),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(txn.fee),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            StatusBadge(status: _convertEnumToUpperSnakeCase(txn.status.name)),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Formatters.formatDate(txn.createdAt),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  Formatters.formatTime(txn.createdAt),
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility, color: AppColors.info, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => TransactionDetailsDialog(
                                        transaction: txn,
                                      ),
                                    );
                                  },
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: Icon(Icons.download, color: AppColors.gray600, size: 20),
                                  onPressed: () {
                                    // TODO: Download receipt
                                  },
                                  tooltip: 'Download Receipt',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                if (!isMobile && !isTablet) const SizedBox(height: AppTheme.space24),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize > _totalTransactions ? _totalTransactions : _currentPage * _pageSize} of $_totalTransactions transactions',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                          child: const Text('Previous'),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '$_currentPage',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        TextButton(
                          onPressed: _currentPage < _totalPages ? _goToNextPage : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.space16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    final upperType = type.contains('_') ? type : _convertEnumToUpperSnakeCase(type);
    switch (upperType) {
      case 'DEPOSIT':
        return AppColors.success;
      case 'WITHDRAWAL':
        return AppColors.error;
      case 'TRANSFER':
        return AppColors.info;
      case 'BILL_PAYMENT':
        return Colors.orange;
      case 'INVESTMENT':
        return Colors.purple;
      case 'INVESTMENT_RETURN':
        return Colors.green;
      case 'VOTING':
        return Colors.pink;
      case 'REFUND':
        return Colors.amber;
      case 'COMMISSION':
        return Colors.teal;
      case 'AGENT_CREDIT':
        return Colors.indigo;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getTypeIcon(String type) {
    final upperType = type.contains('_') ? type : _convertEnumToUpperSnakeCase(type);
    switch (upperType) {
      case 'DEPOSIT':
        return Icons.arrow_downward;
      case 'WITHDRAWAL':
        return Icons.arrow_upward;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'BILL_PAYMENT':
        return Icons.receipt;
      case 'INVESTMENT':
        return Icons.trending_up;
      case 'INVESTMENT_RETURN':
        return Icons.trending_up;
      case 'VOTING':
        return Icons.how_to_vote;
      case 'REFUND':
        return Icons.keyboard_return;
      case 'COMMISSION':
        return Icons.monetization_on;
      case 'AGENT_CREDIT':
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildTransactionCard(dynamic txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: _getTypeColor(_convertEnumToUpperSnakeCase(txn.type.name)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  _getTypeIcon(_convertEnumToUpperSnakeCase(txn.type.name)),
                  color: _getTypeColor(_convertEnumToUpperSnakeCase(txn.type.name)),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _convertEnumToUpperSnakeCase(txn.type.name).replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${txn.id.length >= 12 ? txn.id.substring(0, 12) : txn.id}...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _convertEnumToUpperSnakeCase(txn.status.name)),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Amount
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(txn.amount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (txn.fee > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fee: ${Formatters.formatCurrency(txn.fee)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Transaction Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txn.userId.length >= 8 ? txn.userId.substring(0, 8) : txn.userId,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent ID',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txn.agentId != null
                          ? (txn.agentId!.length >= 8 ? txn.agentId!.substring(0, 8) : txn.agentId!)
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Date & Time
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                Formatters.formatDate(txn.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                Formatters.formatTime(txn.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => TransactionDetailsDialog(
                        transaction: txn,
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility, size: 18, color: AppColors.info),
                  label: Text(
                    'View',
                    style: TextStyle(color: AppColors.info),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
