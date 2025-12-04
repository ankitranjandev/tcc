import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/investment_model.dart';
import '../../services/investment_service.dart';
import '../../utils/csv_export.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';

/// Investments Screen
class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final InvestmentService _investmentService = InvestmentService();
  bool _isLoading = true;
  List<InvestmentModel> _investments = [];
  String? _errorMessage;
  final int _currentPage = 1;

  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _investmentService.getInvestments(
      page: _currentPage,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _filterCategory != 'All' ? _filterCategory : null,
      status: _filterStatus != 'All' ? _filterStatus : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _investments = response.data!.data;
        } else {
          _errorMessage = response.error?.message ?? 'Failed to load investments';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error message
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppTheme.space16),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            ElevatedButton(
              onPressed: _loadInvestments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredInvestments = _investments;

    // Calculate stats
    final totalInvested = _investments.fold<double>(
        0.0, (sum, inv) => sum + inv.amount);
    final activeCount =
        _investments.where((inv) => inv.status == 'ACTIVE').length;
    final maturedCount =
        _investments.where((inv) => inv.status == 'MATURED').length;
    final expectedReturns = _investments.fold<double>(
        0.0, (sum, inv) => sum + inv.expectedReturn);

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
                  'Investment Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Manage community investments',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Create investment opportunity
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Opportunity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
                      'Investment Management',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Monitor and manage all community investments',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Create investment opportunity
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Opportunity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space16,
                    ),
                  ),
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
              desktop: 4,
            ),
            crossAxisSpacing: AppTheme.space16,
            mainAxisSpacing: AppTheme.space16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 2.5 : 2.8,
            children: [
              _buildStatCard(
                'Total Invested',
                Formatters.formatCurrencyCompact(totalInvested),
                Icons.account_balance_wallet,
                AppColors.success,
              ),
              _buildStatCard(
                'Active',
                activeCount.toString(),
                Icons.trending_up,
                AppColors.warning,
              ),
              _buildStatCard(
                'Matured',
                maturedCount.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              _buildStatCard(
                'Expected Returns',
                Formatters.formatCurrencyCompact(expectedReturns),
                Icons.savings,
                AppColors.info,
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
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search investments...',
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
                            borderSide: BorderSide(color: AppColors.success, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      // Category Filter
                      DropdownButtonFormField<String>(
                        initialValue: _filterCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'AGRICULTURE', 'MINERALS', 'EDUCATION']
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.space12),
                      // Status Filter
                      DropdownButtonFormField<String>(
                        initialValue: _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'ONGOING', 'MATURED', 'CANCELLED']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.space12),
                      // Export Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            CsvExport.exportInvestments(_investments.map((e) => e.toJson()).toList());
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space24,
                              vertical: AppTheme.space16,
                            ),
                          ),
                        ),
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
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by user, category, or subcategory...',
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
                              borderSide: BorderSide(color: AppColors.success, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Category Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: ['All', 'AGRICULTURE', 'MINERALS', 'EDUCATION']
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Status Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: ['All', 'ONGOING', 'MATURED', 'CANCELLED']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Export Button
                      OutlinedButton.icon(
                        onPressed: () {
                          CsvExport.exportInvestments(_investments.map((e) => e.toJson()).toList());
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space24,
                            vertical: AppTheme.space20,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space24),

                // Investments List
                if (isMobile || isTablet)
                  Column(
                    children: filteredInvestments.map((inv) => _buildInvestmentCard(inv)).toList(),
                  )
                else
                  SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Investment ID',
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
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Amount Invested',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tenure',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Expected Return',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Maturity Date',
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
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    rows: filteredInvestments.map((investment) {
                      final id = investment.id;
                      final progress = investment.progressPercentage;
                      final status = investment.status;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              id.length >= 8 ? id.substring(0, 8) : id,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              investment.user.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  investment.category,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  investment.subCategory ?? 'N/A',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(investment.amount),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${investment.tenureMonths} months',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${investment.returnRate}%',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(investment.expectedReturn),
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: AppColors.gray200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            progress >= 100
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${progress.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatDate(investment.endDate),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            StatusBadge(status: status),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility, color: AppColors.info, size: 20),
                                  onPressed: () {
                                    // TODO: View investment details
                                  },
                                  tooltip: 'View Details',
                                ),
                                if (status == 'MATURED')
                                  IconButton(
                                    icon: Icon(Icons.payment,
                                        color: AppColors.success, size: 20),
                                    onPressed: () {
                                      // TODO: Process payout
                                    },
                                    tooltip: 'Process Payout',
                                  ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                                  onPressed: () {
                                    // TODO: Edit investment
                                  },
                                  tooltip: 'Edit',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppTheme.space24),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredInvestments.length} of ${_investments.length} investments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: null,
                          child: const Text('Previous'),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        TextButton(
                          onPressed: null,
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
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
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

  Widget _buildInvestmentCard(InvestmentModel investment) {
    final progress = investment.progressPercentage;

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.user.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${investment.category} • ${investment.subCategory ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: investment.status),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Investment Details
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Invested',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(investment.amount),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Return',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${investment.returnRate}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 100 ? AppColors.success : AppColors.warning,
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${investment.daysRemaining} days remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Dates
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(investment.startDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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
                      'Maturity Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(investment.endDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                    // TODO: View investment details
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
              const SizedBox(width: AppTheme.space8),
              if (investment.isMatured)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Process payout
                    },
                    icon: Icon(Icons.payment, size: 18, color: AppColors.white),
                    label: Text(
                      'Payout',
                      style: TextStyle(color: AppColors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Manage investment
                    },
                    icon: Icon(Icons.edit, size: 18, color: AppColors.warning),
                    label: Text(
                      'Manage',
                      style: TextStyle(color: AppColors.warning),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.warning),
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
