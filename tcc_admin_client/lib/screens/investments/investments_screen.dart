import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/investment_model.dart';
import '../../models/investment_opportunity_model.dart';
import '../../services/investment_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/export_dialog.dart';
import '../../widgets/dialogs/create_opportunity_dialog.dart';
import '../../widgets/dialogs/edit_opportunity_dialog.dart';

/// Investments Screen
class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> with SingleTickerProviderStateMixin {
  final InvestmentService _investmentService = InvestmentService();
  final ExportService _exportService = ExportService();
  bool _isLoading = true;
  List<InvestmentModel> _investments = [];
  String? _errorMessage;
  final int _currentPage = 1;

  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';

  // Opportunities state
  List<InvestmentOpportunityModel> _opportunities = [];
  bool _isLoadingOpportunities = false;
  Map<String, int> _opportunityCounts = {
    'AGRICULTURE': 0,
    'EDUCATION': 0,
  };
  String _opportunityFilterCategory = 'All';
  String _opportunityFilterVisibility = 'All';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvestments();
    _loadOpportunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadOpportunities() async {
    setState(() {
      _isLoadingOpportunities = true;
    });

    final response = await _investmentService.getInvestmentOpportunities(
      category: _opportunityFilterCategory != 'All' ? _opportunityFilterCategory : null,
    );

    if (mounted) {
      setState(() {
        _isLoadingOpportunities = false;
        if (response.success && response.data != null) {
          _opportunities = response.data!.data
              .map((json) => InvestmentOpportunityModel.fromJson(json))
              .toList();
          _calculateOpportunityCounts();
        }
      });
    }
  }

  void _calculateOpportunityCounts() {
    _opportunityCounts = {
      'AGRICULTURE': _opportunities.where((o) => o.categoryName == 'AGRICULTURE').length,
      'EDUCATION': _opportunities.where((o) => o.categoryName == 'EDUCATION').length,
    };
  }

  bool _canCreateOpportunity() {
    return _opportunityCounts.values.any((count) => count < 16);
  }

  void _showCreateOpportunityDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateOpportunityDialog(
        opportunityCounts: _opportunityCounts,
        onOpportunityCreated: (opportunity) {
          _loadOpportunities();
        },
      ),
    );
  }

  void _showEditOpportunityDialog(InvestmentOpportunityModel opportunity) {
    showDialog(
      context: context,
      builder: (context) => EditOpportunityDialog(
        opportunity: opportunity,
        onOpportunityUpdated: (updatedOpportunity) {
          _loadOpportunities();
        },
      ),
    );
  }

  Future<void> _toggleOpportunityStatus(InvestmentOpportunityModel opportunity) async {
    final newStatus = !opportunity.isActive;

    final response = await _investmentService.updateInvestmentOpportunity(
      opportunityId: opportunity.id,
      status: newStatus ? 'ACTIVE' : 'HIDDEN',
    );

    if (response.success) {
      _loadOpportunities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opportunity ${newStatus ? 'shown' : 'hidden'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to toggle status'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

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
                  onPressed: _canCreateOpportunity() ? _showCreateOpportunityDialog : null,
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
                  onPressed: _canCreateOpportunity() ? _showCreateOpportunityDialog : null,
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

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [AppColors.shadowSmall],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'User Investments',
                ),
                Tab(
                  icon: Icon(Icons.business_center),
                  text: 'Opportunities',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Tab Content
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvestmentsTab(),
                _buildOpportunitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsTab() {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final filteredInvestments = _investments;

    return Column(
      children: [
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
                            _showExportDialog();
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
                          _showExportDialog();
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
      );
  }

  Widget _buildOpportunitiesTab() {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Apply filters
    List<InvestmentOpportunityModel> filteredOpportunities = _opportunities;

    if (_opportunityFilterCategory != 'All') {
      filteredOpportunities = filteredOpportunities
          .where((o) => o.categoryName == _opportunityFilterCategory)
          .toList();
    }

    if (_opportunityFilterVisibility != 'All') {
      final showActive = _opportunityFilterVisibility == 'Visible';
      filteredOpportunities = filteredOpportunities
          .where((o) => o.isActive == showActive)
          .toList();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [AppColors.shadowSmall],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _opportunityFilterCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'AGRICULTURE', 'EDUCATION']
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _opportunityFilterCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _opportunityFilterVisibility,
                        decoration: InputDecoration(
                          labelText: 'Visibility',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: ['All', 'Visible', 'Hidden']
                            .map((visibility) => DropdownMenuItem(
                                  value: visibility,
                                  child: Text(visibility),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _opportunityFilterVisibility = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                // Stats
                Row(
                  children: [
                    Text(
                      'Agriculture: ${_opportunityCounts['AGRICULTURE'] ?? 0}/16',
                      style: TextStyle(
                        color: (_opportunityCounts['AGRICULTURE'] ?? 0) >= 16
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space24),
                    Text(
                      'Education: ${_opportunityCounts['EDUCATION'] ?? 0}/16',
                      style: TextStyle(
                        color: (_opportunityCounts['EDUCATION'] ?? 0) >= 16
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${_opportunities.length} opportunities',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Opportunities List
          if (_isLoadingOpportunities)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.space32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredOpportunities.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.space32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [AppColors.shadowSmall],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.business_center, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'No opportunities found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Create your first investment opportunity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [AppColors.shadowSmall],
              ),
              child: isMobile || isTablet
                  ? Column(
                      children: filteredOpportunities
                          .map((opp) => _buildOpportunityCard(opp))
                          .toList(),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Title',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Category',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Min-Max Investment',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tenure',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Return Rate',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Units',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: filteredOpportunities.map((opp) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    opp.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space8,
                                    vertical: AppTheme.space4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: opp.categoryName == 'AGRICULTURE'
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  ),
                                  child: Text(
                                    opp.categoryDisplayName,
                                    style: TextStyle(
                                      color: opp.categoryName == 'AGRICULTURE'
                                          ? AppColors.success
                                          : AppColors.info,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'TCC ${Formatters.formatCurrencyCompact(opp.minInvestment)} - ${Formatters.formatCurrencyCompact(opp.maxInvestment)}',
                                ),
                              ),
                              DataCell(
                                Text('${opp.tenureMonths} months'),
                              ),
                              DataCell(
                                Text(
                                  '${opp.returnRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${opp.availableUnits}/${opp.totalUnits}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${opp.soldPercentage.toStringAsFixed(0)}% sold',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      opp.isActive ? Icons.visibility : Icons.visibility_off,
                                      size: 16,
                                      color: opp.isActive ? AppColors.success : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppTheme.space4),
                                    Text(
                                      opp.statusText,
                                      style: TextStyle(
                                        color: opp.isActive ? AppColors.success : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
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
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showEditOpportunityDialog(opp),
                                      tooltip: 'Edit',
                                      color: AppColors.primary,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        opp.isActive ? Icons.visibility_off : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => _toggleOpportunityStatus(opp),
                                      tooltip: opp.isActive ? 'Hide' : 'Show',
                                      color: opp.isActive ? AppColors.warning : AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(InvestmentOpportunityModel opportunity) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: opportunity.isActive ? AppColors.white : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: opportunity.isActive ? AppColors.borderLight : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: opportunity.categoryName == 'AGRICULTURE'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  opportunity.categoryDisplayName,
                  style: TextStyle(
                    color: opportunity.categoryName == 'AGRICULTURE'
                        ? AppColors.success
                        : AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            opportunity.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Investment Range',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'TCC ${Formatters.formatCurrencyCompact(opportunity.minInvestment)} - ${Formatters.formatCurrencyCompact(opportunity.maxInvestment)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Return Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '${opportunity.returnRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tenure',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '${opportunity.tenureMonths} months',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Units',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '${opportunity.availableUnits}/${opportunity.totalUnits} (${opportunity.soldPercentage.toStringAsFixed(0)}% sold)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Icon(
                opportunity.isActive ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: opportunity.isActive ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: AppTheme.space4),
              Text(
                opportunity.statusText,
                style: TextStyle(
                  color: opportunity.isActive ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditOpportunityDialog(opportunity),
                tooltip: 'Edit',
                color: AppColors.primary,
              ),
              IconButton(
                icon: Icon(
                  opportunity.isActive ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => _toggleOpportunityStatus(opportunity),
                tooltip: opportunity.isActive ? 'Hide' : 'Show',
                color: opportunity.isActive ? AppColors.warning : AppColors.success,
              ),
            ],
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Investments',
        subtitle: 'Export investment data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterCategory != 'All') 'Category': _filterCategory,
          if (_filterStatus != 'All') 'Status': _filterStatus,
        },
        onExport: (format) async {
          final response = await _exportService.exportInvestments(
            format: format,
            search: _searchQuery.isNotEmpty ? _searchQuery : null,
            status: _filterStatus == 'All' ? null : _filterStatus,
          );
          
          if (!response.success) {
            throw Exception(response.message ?? 'Export failed');
          }
        },
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
