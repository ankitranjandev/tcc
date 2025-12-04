import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/bill_payment_model.dart';
import '../../services/bill_payment_service.dart';
import '../../utils/csv_export.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';

/// Bill Payments Screen
class BillPaymentsScreen extends StatefulWidget {
  const BillPaymentsScreen({super.key});

  @override
  State<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends State<BillPaymentsScreen> {
  final BillPaymentService _billPaymentService = BillPaymentService();
  String _searchQuery = '';
  String _filterService = 'All';
  String _filterStatus = 'All';
  bool _isLoading = true;
  List<BillPaymentModel> _billPayments = [];
  String? _errorMessage;
  final int _currentPage = 1;
  // TODO: Add pagination UI and make _currentPage non-final when implementing page navigation
  // int _totalPages = 1;

  // Computed properties
  List<BillPaymentModel> get billPayments => _billPayments;

  List<BillPaymentModel> get filteredPayments {
    return _billPayments.where((payment) {
      // Apply filters
      if (_filterService != 'All' && payment.billType != _filterService) {
        return false;
      }
      if (_filterStatus != 'All' && payment.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return payment.referenceNumber.toLowerCase().contains(query) ||
               payment.accountNumber.toLowerCase().contains(query) ||
               payment.customerName.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadBillPayments();
  }

  Future<void> _loadBillPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _billPaymentService.getBillPayments(
      page: _currentPage,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      billType: _filterService != 'All' ? _filterService : null,
      status: _filterStatus != 'All' ? _filterStatus : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _billPayments = response.data!.data;
          // TODO: Use totalPages when pagination UI is added
          // _totalPages = response.data!.totalPages;
        } else {
          _errorMessage = response.error?.message ?? 'Failed to load bill payments';
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
              onPressed: _loadBillPayments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Calculate stats
    final totalAmount =
        _billPayments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final totalFees =
        _billPayments.fold<double>(0.0, (sum, payment) => sum + payment.fee);
    final completedCount =
        _billPayments.where((p) => p.status == 'COMPLETED').length;

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
                  'Bill Payments',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Monitor utility bill payments',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add service provider
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Service Providers'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space16,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                ElevatedButton.icon(
                  onPressed: () {
                    CsvExport.exportTransactions(billPayments);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                      'Bill Payments',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Monitor all utility bill payments',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Add service provider
                      },
                      icon: const Icon(Icons.business),
                      label: const Text('Service Providers'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24,
                          vertical: AppTheme.space16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    ElevatedButton.icon(
                      onPressed: () {
                        CsvExport.exportTransactions(billPayments);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
              desktop: 4,
            ),
            crossAxisSpacing: AppTheme.space16,
            mainAxisSpacing: AppTheme.space16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 2.5 : 2.8,
            children: [
              _buildStatCard(
                'Total Payments',
                billPayments.length.toString(),
                Icons.receipt_long,
                AppColors.accentBlue,
              ),
              _buildStatCard(
                'Total Amount',
                Formatters.formatCurrencyCompact(totalAmount),
                Icons.payments,
                AppColors.success,
              ),
              _buildStatCard(
                'Completed',
                completedCount.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              _buildStatCard(
                'Revenue (Fees)',
                Formatters.formatCurrencyCompact(totalFees),
                Icons.account_balance_wallet,
                AppColors.warning,
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppTheme.space24 : AppTheme.space32),

          // Service Type Quick Stats
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
                  'Services Overview',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space20),
                if (isMobile || isTablet)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppTheme.space12,
                    mainAxisSpacing: AppTheme.space12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildServiceCard('Electricity', Icons.flash_on, Colors.amber, 145),
                      _buildServiceCard('Water', Icons.water_drop, Colors.blue, 89),
                      _buildServiceCard('Internet', Icons.wifi, Colors.purple, 67),
                      _buildServiceCard('Mobile', Icons.phone_android, Colors.green, 234),
                      _buildServiceCard('DSTV', Icons.tv, Colors.red, 56),
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildServiceCard('Electricity', Icons.flash_on, Colors.amber, 145),
                      const SizedBox(width: AppTheme.space16),
                      _buildServiceCard('Water', Icons.water_drop, Colors.blue, 89),
                      const SizedBox(width: AppTheme.space16),
                      _buildServiceCard('Internet', Icons.wifi, Colors.purple, 67),
                      const SizedBox(width: AppTheme.space16),
                      _buildServiceCard('Mobile', Icons.phone_android, Colors.green, 234),
                      const SizedBox(width: AppTheme.space16),
                      _buildServiceCard('DSTV', Icons.tv, Colors.red, 56),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space32),

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
                if (isMobile || isTablet)
                  // Mobile/Tablet: Stacked Layout
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
                          hintText: 'Search by user, description...',
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

                      // Service Filter
                      DropdownButtonFormField<String>(
                        initialValue: _filterService,
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: [
                          'All',
                          'ELECTRICITY',
                          'WATER',
                          'INTERNET',
                          'MOBILE_RECHARGE'
                        ]
                            .map((service) => DropdownMenuItem(
                                  value: service,
                                  child: Text(service.replaceAll('_', ' ')),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterService = value!;
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
                        items: ['All', 'COMPLETED', 'PENDING', 'FAILED']
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
                            CsvExport.exportTransactions(billPayments);
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
                  // Desktop: Horizontal Layout
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
                            hintText: 'Search by user, description, or payment ID...',
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

                      // Service Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterService,
                          decoration: InputDecoration(
                            labelText: 'Service Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: [
                            'All',
                            'ELECTRICITY',
                            'WATER',
                            'INTERNET',
                            'MOBILE_RECHARGE'
                          ]
                              .map((service) => DropdownMenuItem(
                                    value: service,
                                    child: Text(service.replaceAll('_', ' ')),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterService = value!;
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
                          items: ['All', 'COMPLETED', 'PENDING', 'FAILED']
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
                          CsvExport.exportTransactions(billPayments);
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
                const SizedBox(height: AppTheme.space24),

                // Payments List - Conditional Rendering
                if (isMobile || isTablet)
                  // Mobile/Tablet: Card View
                  Column(
                    children: filteredPayments
                        .map((payment) => _buildPaymentCard(payment))
                        .toList(),
                  )
                else
                  // Desktop: Table View
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Payment ID',
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
                          'Service',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Description',
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
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date',
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
                    rows: filteredPayments.map((payment) {
                      // Extract service icon and color
                      final description = payment.description.toLowerCase();
                      IconData serviceIcon = Icons.receipt;
                      Color serviceColor = AppColors.gray500;
                      String serviceName = 'Other';

                      if (description.contains('electricity')) {
                        serviceIcon = Icons.flash_on;
                        serviceColor = Colors.amber;
                        serviceName = 'Electricity';
                      } else if (description.contains('water')) {
                        serviceIcon = Icons.water_drop;
                        serviceColor = Colors.blue;
                        serviceName = 'Water';
                      } else if (description.contains('internet')) {
                        serviceIcon = Icons.wifi;
                        serviceColor = Colors.purple;
                        serviceName = 'Internet';
                      } else if (description.contains('mobile')) {
                        serviceIcon = Icons.phone_android;
                        serviceColor = Colors.green;
                        serviceName = 'Mobile';
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            SelectableText(
                              '${payment.id.length >= 12 ? payment.id.substring(0, 12) : payment.id}...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              payment.user.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(serviceIcon, color: serviceColor, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  serviceName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                payment.description,
                                style: TextStyle(color: AppColors.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(payment.amount),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(payment.fee),
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(payment.totalAmount),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatDate(payment.createdAt),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            StatusBadge(status: payment.status),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility,
                                      color: AppColors.info, size: 20),
                                  onPressed: () {
                                    // TODO: View payment details
                                  },
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: Icon(Icons.receipt_long,
                                      color: AppColors.accentBlue, size: 20),
                                  onPressed: () {
                                    // TODO: Download receipt
                                  },
                                  tooltip: 'Receipt',
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
                      'Showing ${filteredPayments.length} of ${billPayments.length} payments',
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
                            color: AppColors.accentBlue,
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
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, Color color, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.space8),
            Text(
              name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              '$count payments',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BillPaymentModel payment) {
    // Extract service info from description
    final description = payment.description.toLowerCase();
    IconData serviceIcon = Icons.receipt;
    Color serviceColor = AppColors.gray500;
    String serviceName = 'Other';

    if (description.contains('electricity') || description.contains('edsa')) {
      serviceIcon = Icons.flash_on;
      serviceColor = Colors.amber;
      serviceName = 'Electricity';
    } else if (description.contains('water')) {
      serviceIcon = Icons.water_drop;
      serviceColor = Colors.blue;
      serviceName = 'Water';
    } else if (description.contains('internet')) {
      serviceIcon = Icons.wifi;
      serviceColor = Colors.purple;
      serviceName = 'Internet';
    } else if (description.contains('mobile')) {
      serviceIcon = Icons.phone_android;
      serviceColor = Colors.green;
      serviceName = 'Mobile';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service icon, name and status
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: serviceColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: serviceColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(serviceIcon, color: serviceColor, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'ID: ${payment.id.length >= 12 ? payment.id.substring(0, 12) : payment.id}...',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: payment.status),
              ],
            ),
          ),

          // Amount Section
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(payment.amount),
                      style: TextStyle(
                        fontSize: 20,
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
                      'Fee',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(payment.fee),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.gray500),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      'User:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        payment.user.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: AppColors.gray500),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        payment.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.gray500),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      Formatters.formatDate(payment.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions Section
          Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: View payment details
                    },
                    icon: Icon(Icons.visibility, size: 16, color: AppColors.info),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Download receipt
                    },
                    icon: Icon(Icons.receipt_long, size: 16, color: AppColors.accentBlue),
                    label: const Text('Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
