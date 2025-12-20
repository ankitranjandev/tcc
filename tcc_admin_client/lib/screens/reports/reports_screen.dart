import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../services/mock_data_service.dart';
import '../../services/reports_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/dialogs/export_dialog.dart';

/// Reports and Analytics Screen
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final mockData = MockDataService();
  final _reportsService = ReportsService();
  final _exportService = ExportService();
  String _selectedPeriod = 'This Month';
  String _selectedReportType = 'Overview';
  bool _isLoading = false;
  bool _isLoadingAnalytics = false;
  String? _errorMessage;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  /// Load analytics data from backend
  Future<void> _loadAnalytics() async {
    if (_isLoadingAnalytics) return;

    setState(() {
      _isLoadingAnalytics = true;
      _errorMessage = null;
    });

    final dateRange = _getDateRange();

    try {
      final response = await _reportsService.getAnalytics(
        startDate: dateRange['from'],
        endDate: dateRange['to'],
      );

      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
          if (response.success && response.data != null) {
            _analyticsData = response.data;
          } else {
            _errorMessage = response.error?.message ?? 'Failed to load analytics';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
          _errorMessage = 'Error loading analytics: $e';
        });
      }
    }
  }

  /// Get date range based on selected period
  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    DateTime from;
    DateTime to = now;

    switch (_selectedPeriod) {
      case 'Today':
        from = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        from = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(from.year, from.month, from.day);
        break;
      case 'This Month':
        from = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        from = DateTime(now.year, now.month - 1, 1);
        to = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'This Year':
        from = DateTime(now.year, 1, 1);
        break;
      default:
        from = DateTime(now.year, now.month, 1);
    }

    return {'from': from, 'to': to};
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Use analytics data if available, otherwise fall back to mock data
    final dashStats = _analyticsData != null
      ? _transformAnalyticsToStats(_analyticsData!)
      : mockData.dashboardStats;
    final chartData = mockData.chartData;

    // Show error snackbar if there's an error
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ),
        );
      });
    }

    return Stack(
      children: [
        SingleChildScrollView(
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
                  'Reports & Analytics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'View comprehensive reports and analytics',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                // Period Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray300),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    underline: const SizedBox(),
                    isExpanded: true,
                    items: [
                      'Today',
                      'This Week',
                      'This Month',
                      'Last Month',
                      'This Year'
                    ]
                        .map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadAnalytics();
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                OutlinedButton.icon(
                  onPressed: _showExportDialog,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                  style: OutlinedButton.styleFrom(
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
                      'Reports & Analytics',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'View comprehensive reports and analytics',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Period Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        items: [
                          'Today',
                          'This Week',
                          'This Month',
                          'Last Month',
                          'This Year'
                        ]
                            .map((period) => DropdownMenuItem(
                                  value: period,
                                  child: Text(period),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPeriod = value!;
                          });
                          _loadAnalytics();
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    OutlinedButton.icon(
                      onPressed: _showExportDialog,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                      style: OutlinedButton.styleFrom(
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

          // Report Type Tabs
          if (isMobile || isTablet)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [AppColors.shadowSmall],
                ),
                child: Row(
                  children: [
                    _buildTab('Overview', Icons.dashboard, isMobile: true),
                    _buildTab('Transactions', Icons.swap_horiz, isMobile: true),
                    _buildTab('Users', Icons.people, isMobile: true),
                    _buildTab('Revenue', Icons.trending_up, isMobile: true),
                    _buildTab('Investments', Icons.account_balance, isMobile: true),
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
              child: Row(
                children: [
                  _buildTab('Overview', Icons.dashboard),
                  _buildTab('Transactions', Icons.swap_horiz),
                  _buildTab('Users', Icons.people),
                  _buildTab('Revenue', Icons.trending_up),
                  _buildTab('Investments', Icons.account_balance),
                ],
              ),
            ),
          SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

          // Overview Report
          if (_selectedReportType == 'Overview') ...[
            // Key Metrics
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
              childAspectRatio: isMobile ? 2.5 : (isTablet ? 2.0 : 1.8),
              children: [
                _buildMetricCard(
                  'Total Users',
                  dashStats['totalUsers'].toString(),
                  '+${dashStats['userGrowth']}%',
                  true,
                  Icons.people,
                  AppColors.accentBlue,
                ),
                _buildMetricCard(
                  'Total Transactions',
                  dashStats['totalTransactions'].toString(),
                  '+${dashStats['transactionGrowth']}%',
                  true,
                  Icons.swap_horiz,
                  AppColors.success,
                ),
                _buildMetricCard(
                  'Total Revenue',
                  Formatters.formatCurrencyCompact(dashStats['totalRevenue']),
                  '+${dashStats['revenueGrowth']}%',
                  true,
                  Icons.account_balance_wallet,
                  AppColors.warning,
                ),
                _buildMetricCard(
                  'Active Agents',
                  dashStats['totalAgents'].toString(),
                  '+${dashStats['agentGrowth']}%',
                  true,
                  Icons.store,
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

            // Charts Row/Column
            if (isMobile || isTablet)
              Column(
                children: [
                  // Transaction Trend Chart
                  Container(
                    padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [AppColors.shadowSmall],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Trends',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildLegend('Deposits', AppColors.success),
                            _buildLegend('Withdrawals', AppColors.error),
                            _buildLegend('Transfers', AppColors.info),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space24),
                        SizedBox(
                          height: 250,
                          child: _buildTransactionChart(
                              chartData['transactionTrend']),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space24),

                  // Revenue by Category
                  Container(
                    padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [AppColors.shadowSmall],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue by Category',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space24),
                        ...(chartData['revenueByCategory'] as List).map((item) {
                          final total = (chartData['revenueByCategory'] as List)
                              .fold<double>(0, (sum, i) => sum + _toDouble(i['amount']));
                          final percentage = (_toDouble(item['amount']) / total) * 100;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space16),
                            child: _buildRevenueItem(
                              item['category'],
                              Formatters.formatCurrencyCompact(item['amount']),
                              percentage,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Trend Chart
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [AppColors.shadowSmall],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction Trends',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildLegend('Deposits', AppColors.success),
                                  const SizedBox(width: 16),
                                  _buildLegend('Withdrawals', AppColors.error),
                                  const SizedBox(width: 16),
                                  _buildLegend('Transfers', AppColors.info),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space24),
                          SizedBox(
                            height: 250,
                            child: _buildTransactionChart(
                                chartData['transactionTrend']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),

                  // Revenue by Category
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [AppColors.shadowSmall],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),
                          ...(chartData['revenueByCategory'] as List).map((item) {
                            final total = (chartData['revenueByCategory'] as List)
                                .fold<double>(0, (sum, i) => sum + _toDouble(i['amount']));
                            final percentage = (_toDouble(item['amount']) / total) * 100;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.space16),
                              child: _buildRevenueItem(
                                item['category'],
                                Formatters.formatCurrencyCompact(item['amount']),
                                percentage,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

            // Investment Distribution
            Container(
              padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [AppColors.shadowSmall],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Distribution',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  if (isMobile || isTablet)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppTheme.space12,
                      mainAxisSpacing: AppTheme.space12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
                      children: (chartData['investmentDistribution'] as List)
                          .map<Widget>((item) {
                        return _buildInvestmentCard(
                          item['category'],
                          item['percentage'],
                          Formatters.formatCurrencyCompact(item['amount']),
                        );
                      }).toList(),
                    )
                  else
                    Row(
                      children: (chartData['investmentDistribution'] as List)
                          .map<Widget>((item) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildInvestmentCard(
                              item['category'],
                              item['percentage'],
                              Formatters.formatCurrencyCompact(item['amount']),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],

          // Pending Actions
          SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),
          Container(
            padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [AppColors.shadowSmall],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Actions',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                GridView.count(
                  crossAxisCount: Responsive.gridColumns(
                    context,
                    mobile: 2,
                    tablet: 2,
                    desktop: 4,
                  ),
                  crossAxisSpacing: AppTheme.space16,
                  mainAxisSpacing: AppTheme.space16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isMobile ? 1.2 : (isTablet ? 1.5 : 1.3),
                  children: [
                    _buildPendingCard(
                      'Pending KYC',
                      dashStats['pendingKyc'].toString(),
                      Icons.verified_user,
                      AppColors.warning,
                    ),
                    _buildPendingCard(
                      'Pending Withdrawals',
                      dashStats['pendingWithdrawals'].toString(),
                      Icons.south,
                      AppColors.error,
                    ),
                    _buildPendingCard(
                      'Pending Deposits',
                      dashStats['pendingDeposits'].toString(),
                      Icons.north,
                      AppColors.success,
                    ),
                    _buildPendingCard(
                      'Agent Verifications',
                      dashStats['pendingAgentVerifications'].toString(),
                      Icons.store,
                      AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
      // Loading overlay
      if (_isLoadingAnalytics)
        Container(
          color: Colors.black26,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Loading Analytics...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Load specific report data based on type
  Future<void> _loadReportData(String reportType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dateRange = _getDateRange();

    try {
      switch (reportType) {
        case 'Transactions':
          final response = await _reportsService.getTransactionReport(
            startDate: dateRange['from'],
            endDate: dateRange['to'],
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (!response.success) {
              _errorMessage = response.error?.message ?? 'Failed to load transaction report';
            }
          }
          break;
        case 'Users':
          final response = await _reportsService.getUserActivityReport(
            startDate: dateRange['from'],
            endDate: dateRange['to'],
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (!response.success) {
              _errorMessage = response.error?.message ?? 'Failed to load user report';
            }
          }
          break;
        case 'Revenue':
          final response = await _reportsService.getRevenueReport(
            startDate: dateRange['from'],
            endDate: dateRange['to'],
            groupBy: 'day',
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (!response.success) {
              _errorMessage = response.error?.message ?? 'Failed to load revenue report';
            }
          }
          break;
        case 'Investments':
          final response = await _reportsService.getInvestmentReport(
            startDate: dateRange['from'],
            endDate: dateRange['to'],
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (!response.success) {
              _errorMessage = response.error?.message ?? 'Failed to load investment report';
            }
          }
          break;
        default:
          // Overview doesn't need specific report data
          setState(() {
            _isLoading = false;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading report: $e';
        });
      }
    }
  }

  Widget _buildTab(String title, IconData icon, {bool isMobile = false}) {
    final isSelected = _selectedReportType == title;
    return isMobile
        ? InkWell(
            onTap: () {
              setState(() {
                _selectedReportType = title;
              });
              _loadReportData(title);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space16,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedReportType = title;
                });
                _loadReportData(title);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildMetricCard(String title, String value, String change,
      bool isPositive, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionChart(List data) {
    final maxValue = data.fold<int>(0, (max, item) {
      final deposits = _toInt(item['deposits']);
      final withdrawals = _toInt(item['withdrawals']);
      final transfers = _toInt(item['transfers']);
      final total = deposits + withdrawals + transfers;
      return total > max ? total : max;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map<Widget>((item) {
        final deposits = _toInt(item['deposits']);
        final withdrawals = _toInt(item['withdrawals']);
        final transfers = _toInt(item['transfers']);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          height: (deposits / maxValue) * 200,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Container(
                          height: (withdrawals / maxValue) * 200,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Container(
                          height: (transfers / maxValue) * 200,
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (item['date'] as String).split('-')[2],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueItem(String category, String amount, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildInvestmentCard(String category, double percentage, String amount) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.space12),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Transform analytics data to dashboard stats format
  /// Helper function to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper function to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> _transformAnalyticsToStats(Map<String, dynamic> analytics) {
    final transactions = analytics['transactions'] as Map<String, dynamic>? ?? {};
    final users = analytics['users'] as Map<String, dynamic>? ?? {};
    // final investments = analytics['investments'] as Map<String, dynamic>? ?? {};
    final agents = analytics['agents'] as Map<String, dynamic>? ?? {};

    return {
      'totalUsers': _toInt(users['total_users']),
      'totalTransactions': _toInt(transactions['total_count']),
      'totalRevenue': _toDouble(transactions['total_volume']),
      'totalAgents': _toInt(agents['total_agents']),
      'userGrowth': _calculateGrowth(
        _toInt(users['new_users_today']),
        _toInt(users['total_users']),
      ),
      'transactionGrowth': 12.5, // Mock for now
      'revenueGrowth': 8.2, // Mock for now
      'agentGrowth': 5.1, // Mock for now
      'pendingKyc': _toInt(users['kyc_pending_users']),
      'pendingWithdrawals': 0, // Not in analytics endpoint
      'pendingDeposits': 0, // Not in analytics endpoint
      'pendingAgentVerifications': _toInt(agents['pending_verification']),
    };
  }

  double _calculateGrowth(int newCount, int totalCount) {
    if (totalCount == 0) return 0.0;
    return ((newCount / totalCount) * 100).toDouble();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Report',
        subtitle: 'Export $_selectedReportType report for $_selectedPeriod',
        filters: {
          'Report Type': _selectedReportType,
          'Period': _selectedPeriod,
        },
        onExport: (format) async {
          final dateRange = _getDateRange();
          final response = await _exportService.exportReports(
            format: format,
            reportType: _selectedReportType.toLowerCase(),
            startDate: dateRange['from'],
            endDate: dateRange['to'],
          );
          
          if (!response.success) {
            throw Exception(response.message ?? 'Export failed');
          }
        },
      ),
    );
  }

}
