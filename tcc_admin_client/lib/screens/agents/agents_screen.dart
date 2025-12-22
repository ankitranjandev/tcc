import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/agent_model.dart';
import '../../models/bank_account_model.dart';
import '../../services/agent_management_service.dart';
import '../../services/bank_account_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/add_agent_dialog.dart';
import '../../widgets/dialogs/export_dialog.dart';
import '../kyc/kyc_review_dialog.dart';

/// Agents List Screen
class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final _agentService = AgentManagementService();
  final _exportService = ExportService();
  List<AgentModel> _agents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterStatus = 'All';
  final String _filterVerificationStatus = 'All';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalAgents = 0;
  final int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _agentService.getAgents(
      page: _currentPage,
      perPage: _pageSize,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      status: _filterStatus != 'All' ? _filterStatus : null,
      verificationStatus: _filterVerificationStatus != 'All' ? _filterVerificationStatus : null,
    );

    if (response.success && response.data != null) {
      setState(() {
        _agents = response.data!.data;
        _totalPages = response.data!.totalPages;
        _totalAgents = response.data!.total;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load agents';
        _isLoading = false;
      });
    }
  }

  Future<void> _addAgent(AgentModel agent) async {
    // Refresh the list to include the newly added agent
    await _loadAgents();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
    _loadAgents();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
      _loadAgents();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadAgents();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadAgents();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Agents',
        subtitle: 'Export agent data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterStatus != 'All') 'Status': _filterStatus,
        },
        onExport: (format) async {
          final response = await _exportService.exportUsers(
            format: format,
            search: _searchQuery.isNotEmpty ? _searchQuery : null,
            role: 'AGENT',
            status: _filterStatus == 'All' ? null : _filterStatus,
          );
          
          if (!response.success) {
            throw Exception(response.message ?? 'Export failed');
          }
        },
      ),
    );
  }

  void _showKYCReviewDialog(AgentModel agent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KYCReviewDialog(
        agent: agent,
        onStatusChanged: () {
          // Reload agents after status change
          _loadAgents();
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
            CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Loading agents...',
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
              onPressed: _loadAgents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    final agents = _agents;

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
                  'Agents Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Manage and monitor all agents',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to KYC submissions with agent filter
                          Navigator.pushNamed(context, '/kyc-submissions');
                        },
                        icon: const Icon(Icons.verified_user, size: 18),
                        label: const Text('Review KYC'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                            vertical: AppTheme.space12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddAgentDialog(
                              onAgentAdded: _addAgent,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Agent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                            vertical: AppTheme.space12,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      'Agents Management',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Manage and monitor all agents',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to KYC submissions with agent filter
                        Navigator.pushNamed(context, '/kyc-submissions');
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Review All KYC'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space20,
                          vertical: AppTheme.space16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddAgentDialog(
                            onAgentAdded: _addAgent,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Agent'),
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
            crossAxisSpacing: isMobile ? AppTheme.space12 : AppTheme.space16,
            mainAxisSpacing: isMobile ? AppTheme.space12 : AppTheme.space16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 3 : 2.5,
            children: [
              _buildStatCard(
                context,
                'Total Agents',
                _totalAgents.toString(),
                Icons.store,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Active Agents',
                agents.where((a) => a.status.name == 'ACTIVE').length.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              InkWell(
                onTap: () {
                  // Navigate to KYC Submissions screen with agent filter
                  Navigator.pushNamed(context, '/kyc-submissions');
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: _buildStatCard(
                  context,
                  'Pending KYC (Click to Review)',
                  agents.where((a) => a.verificationStatus.name == 'PENDING').length.toString(),
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
              _buildStatCard(
                context,
                'Total Commission',
                Formatters.formatCurrencyCompact(
                  agents.fold(0.0, (sum, agent) => sum + agent.totalCommissionEarned),
                ),
                Icons.money,
                AppColors.success,
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
                          hintText: 'Search by name, business, email, or phone...',
                          hintStyle: TextStyle(fontSize: isMobile ? 14 : null),
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
                            borderSide: BorderSide(color: Colors.orange, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? AppTheme.space12 : AppTheme.space16,
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
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? AppTheme.space12 : AppTheme.space16,
                            horizontal: AppTheme.space16,
                          ),
                        ),
                        items: ['All', 'ACTIVE', 'INACTIVE', 'SUSPENDED']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: _onFilterChanged,
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
                              vertical: isMobile ? AppTheme.space12 : AppTheme.space16,
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
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search by name, business, email, or phone...',
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
                              borderSide: BorderSide(color: Colors.orange, width: 2),
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
                            labelText: 'Status Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                          items: ['All', 'ACTIVE', 'INACTIVE', 'SUSPENDED']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: _onFilterChanged,
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

                // Agents List
                if (isMobile || isTablet)
                  Column(
                    children: agents.map((agent) => _buildAgentCard(agent)).toList(),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Agent ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Agent Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Business Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Contact',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Verification',
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
                          'Commission',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total Earned',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Joined',
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
                    rows: agents.map((agent) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              agent.id.length >= 8 ? agent.id.substring(0, 8) : agent.id,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                      child: Text(
                                        agent.firstName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (agent.isAvailable)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      agent.fullName,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (agent.isAvailable)
                                      Text(
                                        'Available',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  agent.businessName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Reg: ${agent.businessRegistrationNumber}',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  agent.email,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  agent.phone,
                                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              agent.location,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            StatusBadge(status: agent.verificationStatus.name),
                          ),
                          DataCell(
                            StatusBadge(status: agent.status.name),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Text(
                                '${agent.commissionRate}%',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(agent.totalCommissionEarned),
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatDate(agent.createdAt),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility, color: AppColors.info, size: 20),
                                  onPressed: () {
                                    // TODO: View agent details
                                  },
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                                  onPressed: () {
                                    // TODO: Edit agent
                                  },
                                  tooltip: 'Edit Agent',
                                ),
                                if (agent.verificationStatus.name == 'PENDING' ||
                                    agent.verificationStatus.name == 'SUBMITTED')
                                  IconButton(
                                    icon: Icon(Icons.verified_user, color: AppColors.warning, size: 20),
                                    onPressed: () => _showKYCReviewDialog(agent),
                                    tooltip: 'Review KYC Documents',
                                  ),
                                IconButton(
                                  icon: Icon(
                                    agent.status.name == 'ACTIVE'
                                        ? Icons.block
                                        : Icons.check_circle,
                                    color: agent.status.name == 'ACTIVE'
                                        ? AppColors.error
                                        : AppColors.success,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // TODO: Toggle agent status
                                  },
                                  tooltip: agent.status.name == 'ACTIVE'
                                      ? 'Suspend Agent'
                                      : 'Activate Agent',
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
                      'Showing ${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize > _totalAgents ? _totalAgents : _currentPage * _pageSize} of $_totalAgents agents',
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
                            color: Colors.orange,
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
            padding: EdgeInsets.all(isMobile ? AppTheme.space8 : AppTheme.space12),
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
                const SizedBox(height: 2),
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

  Widget _buildAgentCard(AgentModel agent) {
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
          // Agent Header
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    child: Text(
                      agent.firstName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (agent.isAvailable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      agent.businessName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: agent.status.name),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Agent Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.id.length >= 8 ? agent.id.substring(0, 8) : agent.id,
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
                      'Location',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Text(
                      'Phone',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.phone,
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
                      'Commission',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '${agent.commissionRate}%',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Status Badges
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      agent.verificationStatus.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatCurrency(agent.totalCommissionEarned),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatDate(agent.createdAt),
                      style: TextStyle(
                        fontSize: 11,
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
                    // TODO: View agent details
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Edit agent
                  },
                  icon: Icon(Icons.edit, size: 18, color: AppColors.warning),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                  ),
                ),
              ),
              if (agent.verificationStatus.name == 'PENDING' || agent.verificationStatus.name == 'SUBMITTED') ...[
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showKYCReviewDialog(agent);
                    },
                    icon: Icon(Icons.verified_user, size: 18, color: AppColors.white),
                    label: Text(
                      'Review KYC',
                      style: TextStyle(color: AppColors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
