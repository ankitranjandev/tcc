import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/bank_account_model.dart';
import '../../models/consumer_model.dart';
import '../../models/user_model.dart';
import '../../services/bank_account_service.dart';
import '../../services/consumer_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/add_user_dialog.dart';
import '../../widgets/dialogs/export_dialog.dart';
import '../../services/kyc_service.dart';
import '../kyc/kyc_review_detail_screen.dart';

/// Consumers List Screen
/// Displays all consumers from TCC user mobile app
class ConsumersScreen extends StatefulWidget {
  const ConsumersScreen({super.key});

  @override
  State<ConsumersScreen> createState() => _ConsumersScreenState();
}

class _ConsumersScreenState extends State<ConsumersScreen> {
  final _consumerService = ConsumerService();
  final _exportService = ExportService();
  final _kycService = KycService();
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  List<ConsumerModel> _consumers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterKycStatus = 'All';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalConsumers = 0;
  final int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadConsumers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConsumers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _consumerService.getConsumers(
      page: _currentPage,
      limit: _pageSize,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      isActive: _filterStatus == 'All' ? null : _filterStatus == 'active',
      kycStatus: _filterKycStatus == 'All' ? null : _filterKycStatus.toUpperCase(),
    );

    if (response.success && response.data != null) {
      setState(() {
        _consumers = response.data!.data;
        _totalPages = response.data!.totalPages;
        _totalConsumers = response.data!.total;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load consumers';
        _isLoading = false;
      });
    }
  }

  Future<void> _addConsumer(UserModel user) async {
    // Refresh the list to include the newly added consumer
    await _loadConsumers();
  }

  void _viewConsumerDetails(ConsumerModel consumer) {
    // Convert ConsumerModel to UserModel for the dialog
    // Since the dialog expects UserModel, we'll create a compatible object
    showDialog(
      context: context,
      builder: (context) => _ConsumerDetailsDialog(consumer: consumer),
    );
  }

  Future<void> _toggleConsumerStatus(ConsumerModel consumer) async {
    final newStatus = consumer.status.name == 'active' ? 'INACTIVE' : 'ACTIVE';
    final action = newStatus == 'ACTIVE' ? 'activate' : 'suspend';

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text('Are you sure you want to $action ${consumer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'ACTIVE'
                  ? AppColors.success
                  : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _consumerService.updateConsumerStatus(
        consumerId: consumer.id,
        status: newStatus,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Consumer ${action}d successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadConsumers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Failed to update consumer status',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _reviewConsumerKyc(ConsumerModel consumer) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentBlue),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Loading KYC submission...',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Fetch KYC submissions for this consumer
      final response = await _kycService.getUserKycSubmissions(consumer.id);

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // Get the most recent submission
        final submission = response.data!.first;
        final submissionId = submission['id'] as String;

        // Navigate to KYC review detail screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KYCReviewDetailScreen(
              submissionId: submissionId,
              userId: consumer.id,
            ),
          ),
        );

        // Reload consumers after review
        await _loadConsumers();
      } else {
        // No KYC submission found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No KYC submission found for ${consumer.fullName}',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still showing
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading KYC submission: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _loadConsumers();
    });
  }

  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
      _loadConsumers();
    }
  }

  void _onKycFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterKycStatus = value;
        _currentPage = 1;
      });
      _loadConsumers();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadConsumers();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadConsumers();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Consumers',
        subtitle: 'Export consumer data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterStatus != 'All') 'Status': _filterStatus,
          if (_filterKycStatus != 'All') 'KYC Status': _filterKycStatus,
        },
        onExport: (format) async {
          debugPrint('=== CONSUMERS SCREEN: Export triggered ===');
          debugPrint('Format: $format');
          debugPrint('Search query: $_searchQuery');
          debugPrint('Filter status: $_filterStatus');
          debugPrint('Filter KYC status: $_filterKycStatus');

          final response = await _exportService.exportUsers(
            format: format,
            search: _searchQuery.isNotEmpty ? _searchQuery : null,
            role: 'USER',
            status: _filterStatus == 'All' ? null : _filterStatus.toUpperCase(),
            kycStatus: _filterKycStatus == 'All' ? null : _filterKycStatus.toUpperCase(),
          );

          debugPrint('Export service response received');
          debugPrint('Response success: ${response.success}');
          debugPrint('Response message: ${response.message}');

          if (!response.success) {
            debugPrint('Export failed - throwing exception');
            throw Exception(response.message ?? 'Export failed');
          }

          debugPrint('=== CONSUMERS SCREEN: Export completed successfully ===');
        },
      ),
    );
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
              'Loading consumers...',
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
              onPressed: _loadConsumers,
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

    final consumers = _consumers;

    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumers Management',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Manage and monitor all consumers from TCC User App',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddUserDialog(
                              onUserAdded: _addConsumer,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Consumer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                            vertical: AppTheme.space12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumers Management',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Manage and monitor all consumers from TCC User App',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddUserDialog(
                            onUserAdded: _addConsumer,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Consumer'),
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
          SizedBox(height: isMobile ? AppTheme.space20 : AppTheme.space32),

          // Stats Cards
          GridView.count(
            crossAxisCount: Responsive.gridColumns(
              context,
              mobile: 1,
              tablet: 2,
              desktop: 4,
            ),
            crossAxisSpacing: isMobile ? AppTheme.space12 : AppTheme.space16,
            mainAxisSpacing: isMobile ? AppTheme.space12 : AppTheme.space16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 3 : 2.5,
            children: [
              _buildStatCard(
                context,
                'Total Consumers',
                _totalConsumers.toString(),
                Icons.people,
                AppColors.accentBlue,
              ),
              _buildStatCard(
                context,
                'Active Consumers',
                consumers
                    .where((c) => c.status.name == 'active')
                    .length
                    .toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              InkWell(
                onTap: () {
                  // Navigate to KYC Submissions screen with consumer filter
                  Navigator.pushNamed(context, '/kyc-submissions');
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: _buildStatCard(
                  context,
                  'Pending KYC (Click to Review)',
                  consumers
                      .where((c) => c.kycStatus.name == 'pending')
                      .length
                      .toString(),
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
              _buildStatCard(
                context,
                'Total Investments',
                Formatters.formatCurrency(
                  consumers.fold(0.0, (sum, c) => sum + c.totalInvested),
                ),
                Icons.trending_up,
                AppColors.success,
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppTheme.space20 : AppTheme.space32),

          // Filters and Search
          Container(
            padding: EdgeInsets.all(
              isMobile ? AppTheme.space16 : AppTheme.space24,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [AppColors.shadowSmall],
            ),
            child: Column(
              children: [
                isMobile || isTablet
                    ? Column(
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, or phone...',
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 14 : null,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.gray500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.gray300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.gray300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.accentBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isMobile
                                    ? AppTheme.space12
                                    : AppTheme.space16,
                                horizontal: AppTheme.space16,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),

                          // Status Filter
                          DropdownButtonFormField<String>(
                            initialValue: _filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Status Filter',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isMobile
                                    ? AppTheme.space12
                                    : AppTheme.space16,
                                horizontal: AppTheme.space16,
                              ),
                            ),
                            items: ['All', 'active', 'inactive', 'suspended']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status == 'All' 
                                        ? 'All' 
                                        : status[0].toUpperCase() + status.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _onStatusFilterChanged,
                          ),
                          const SizedBox(height: AppTheme.space12),

                          // KYC Filter
                          DropdownButtonFormField<String>(
                            initialValue: _filterKycStatus,
                            decoration: InputDecoration(
                              labelText: 'KYC Status Filter',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isMobile
                                    ? AppTheme.space12
                                    : AppTheme.space16,
                                horizontal: AppTheme.space16,
                              ),
                            ),
                            items:
                                [
                                      'All',
                                      'pending',
                                      'approved',
                                      'rejected',
                                      'underReview',
                                    ]
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status == 'All' 
                                            ? 'All' 
                                            : status == 'underReview' 
                                              ? 'Under Review' 
                                              : status[0].toUpperCase() + status.substring(1),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: _onKycFilterChanged,
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.space20,
                                  vertical: isMobile
                                      ? AppTheme.space12
                                      : AppTheme.space16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Search Bar
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search by name, email, or phone...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.gray500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.gray300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.gray300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.accentBlue,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.gray50,
                              ),
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
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.gray50,
                              ),
                              items: ['All', 'active', 'inactive', 'suspended']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status == 'All' 
                                          ? 'All' 
                                          : status[0].toUpperCase() + status.substring(1),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onStatusFilterChanged,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),

                          // KYC Filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterKycStatus,
                              decoration: InputDecoration(
                                labelText: 'KYC Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.gray50,
                              ),
                              items:
                                  [
                                        'All',
                                        'pending',
                                        'approved',
                                        'rejected',
                                        'underReview',
                                      ]
                                      .map(
                                        (status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(
                                            status == 'All' 
                                              ? 'All' 
                                              : status == 'underReview' 
                                                ? 'Under Review' 
                                                : status[0].toUpperCase() + status.substring(1),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: _onKycFilterChanged,
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
                SizedBox(
                  height: isMobile ? AppTheme.space16 : AppTheme.space24,
                ),

                // Consumers List/Table
                isMobile || isTablet
                    ? Column(
                        children: consumers
                            .map((consumer) => _buildConsumerCard(consumer))
                            .toList(),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.gray50,
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Consumer ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Phone',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'KYC Status',
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
                                'Wallet Balance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Transactions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Registered',
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
                          rows: consumers.map((consumer) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    consumer.id.length >= 8
                                        ? consumer.id.substring(0, 8)
                                        : consumer.id,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.accentBlue
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          consumer.firstName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.accentBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space12),
                                      Text(
                                        consumer.fullName,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    consumer.email,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    consumer.phone ?? 'N/A',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  StatusBadge(status: consumer.kycStatus.name),
                                ),
                                DataCell(
                                  StatusBadge(status: consumer.status.name),
                                ),
                                DataCell(
                                  Text(
                                    Formatters.formatCurrency(
                                      consumer.walletBalance,
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    consumer.totalTransactions.toString(),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    Formatters.formatDate(consumer.createdAt),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.visibility,
                                          color: AppColors.info,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _viewConsumerDetails(consumer),
                                        tooltip: 'View Details',
                                      ),
                                      if (consumer.kycStatus.name == 'pending' ||
                                          consumer.kycStatus.name == 'underReview')
                                        IconButton(
                                          icon: Icon(
                                            Icons.verified_user,
                                            color: AppColors.warning,
                                            size: 20,
                                          ),
                                          onPressed: () => _reviewConsumerKyc(consumer),
                                          tooltip: 'Review KYC',
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          consumer.status.name == 'active'
                                              ? Icons.block
                                              : Icons.check_circle,
                                          color:
                                              consumer.status.name == 'active'
                                              ? AppColors.error
                                              : AppColors.success,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _toggleConsumerStatus(consumer),
                                        tooltip:
                                            consumer.status.name == 'active'
                                            ? 'Suspend Consumer'
                                            : 'Activate Consumer',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                SizedBox(
                  height: isMobile ? AppTheme.space16 : AppTheme.space24,
                ),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize > _totalConsumers ? _totalConsumers : _currentPage * _pageSize} of $_totalConsumers consumers',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _currentPage > 1
                              ? _goToPreviousPage
                              : null,
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
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
                          onPressed: _currentPage < _totalPages
                              ? _goToNextPage
                              : null,
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isMobile = context.isMobile;
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppColors.shadowSmall],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              isMobile ? AppTheme.space8 : AppTheme.space12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? AppTheme.space12 : AppTheme.space16),
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
                    fontSize: isMobile ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
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

  Widget _buildConsumerCard(ConsumerModel consumer) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                child: Text(
                  consumer.firstName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consumer.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consumer.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              StatusBadge(status: consumer.status.name),
              StatusBadge(status: consumer.kycStatus.name),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(consumer.walletBalance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
                      'Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consumer.totalTransactions.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.visibility, color: AppColors.info, size: 20),
                onPressed: () => _viewConsumerDetails(consumer),
                tooltip: 'View Details',
              ),
              if (consumer.kycStatus.name == 'pending' ||
                  consumer.kycStatus.name == 'underReview')
                IconButton(
                  icon: Icon(
                    Icons.verified_user,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  onPressed: () => _reviewConsumerKyc(consumer),
                  tooltip: 'Review KYC',
                ),
              IconButton(
                icon: Icon(
                  consumer.status.name == 'active'
                      ? Icons.block
                      : Icons.check_circle,
                  color: consumer.status.name == 'active'
                      ? AppColors.error
                      : AppColors.success,
                  size: 20,
                ),
                onPressed: () => _toggleConsumerStatus(consumer),
                tooltip: consumer.status.name == 'active'
                    ? 'Suspend Consumer'
                    : 'Activate Consumer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Consumer Details Dialog
class _ConsumerDetailsDialog extends StatefulWidget {
  final ConsumerModel consumer;

  const _ConsumerDetailsDialog({required this.consumer});

  @override
  State<_ConsumerDetailsDialog> createState() => _ConsumerDetailsDialogState();
}

class _ConsumerDetailsDialogState extends State<_ConsumerDetailsDialog> {
  final BankAccountService _bankAccountService = BankAccountService();
  List<BankAccountModel>? _bankAccounts;
  bool _isLoadingBankAccounts = true;
  String? _bankAccountsError;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() {
      _isLoadingBankAccounts = true;
      _bankAccountsError = null;
    });

    final response = await _bankAccountService.getUserBankAccounts(widget.consumer.id);

    if (mounted) {
      setState(() {
        _isLoadingBankAccounts = false;
        if (response.success && response.data != null) {
          _bankAccounts = response.data;
        } else {
          _bankAccountsError = response.error?.message ?? 'Failed to load bank accounts';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppTheme.space24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consumer Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                  child: Text(
                    widget.consumer.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Center(
                child: Text(
                  widget.consumer.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Center(
                child: Wrap(
                  spacing: AppTheme.space8,
                  alignment: WrapAlignment.center,
                  children: [
                    StatusBadge(status: widget.consumer.status.name),
                    StatusBadge(status: widget.consumer.kycStatus.name),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),
              const Divider(),
              const SizedBox(height: AppTheme.space24),
              _buildDetailRow('Email', widget.consumer.email),
              _buildDetailRow('Phone', widget.consumer.phone ?? 'N/A'),
              _buildDetailRow('Country Code', widget.consumer.countryCode ?? 'N/A'),
              _buildDetailRow('Address', widget.consumer.address ?? 'N/A'),
              _buildDetailRow(
                'Date of Birth',
                widget.consumer.dateOfBirth != null
                    ? Formatters.formatDate(widget.consumer.dateOfBirth!)
                    : 'N/A',
              ),
              _buildDetailRow(
                'Wallet Balance',
                Formatters.formatCurrency(widget.consumer.walletBalance),
              ),
              _buildDetailRow(
                'Total Transactions',
                widget.consumer.totalTransactions.toString(),
              ),
              _buildDetailRow(
                'Total Invested',
                Formatters.formatCurrency(widget.consumer.totalInvested),
              ),
              _buildDetailRow(
                'Has Bank Details',
                widget.consumer.hasBankDetails ? 'Yes' : 'No',
              ),
              _buildDetailRow(
                'Has Investments',
                widget.consumer.hasInvestments ? 'Yes' : 'No',
              ),
              _buildDetailRow(
                'Registered',
                Formatters.formatDate(widget.consumer.createdAt),
              ),
              _buildDetailRow(
                'Last Active',
                widget.consumer.lastActive != null
                    ? Formatters.formatDate(widget.consumer.lastActive!)
                    : 'N/A',
              ),
              const SizedBox(height: AppTheme.space16),
              const Divider(),
              const SizedBox(height: AppTheme.space16),
              _buildBankAccountsSection(),
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank Accounts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        _buildBankAccountsContent(),
      ],
    );
  }

  Widget _buildBankAccountsContent() {
    if (_isLoadingBankAccounts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
        ),
      );
    }

    if (_bankAccountsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Text(
            _bankAccountsError!,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_bankAccounts == null || _bankAccounts!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Text(
            'No bank accounts found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _bankAccounts!.asMap().entries.map((entry) {
        final index = entry.key;
        final account = entry.value;
        return Column(
          children: [
            if (index > 0) const SizedBox(height: AppTheme.space12),
            if (index > 0) const Divider(color: AppColors.gray300),
            if (index > 0) const SizedBox(height: AppTheme.space12),
            _buildBankAccountCard(account),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBankAccountCard(BankAccountModel account) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  account.bankName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  if (account.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space8,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(color: AppColors.accentBlue),
                      ),
                      child: Text(
                        'PRIMARY',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppTheme.space8),
                  if (account.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space8,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          _buildDetailRow('Account Holder', account.accountHolderName),
          _buildDetailRow('Account Number', account.accountNumberMasked),
          _buildDetailRow(
            'Added On',
            Formatters.formatDate(account.createdAt),
          ),
        ],
      ),
    );
  }
}
