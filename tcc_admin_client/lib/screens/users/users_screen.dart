import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_management_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/add_user_dialog.dart';
import '../../widgets/dialogs/edit_user_dialog.dart';
import '../../widgets/dialogs/view_user_dialog.dart';
import '../../widgets/dialogs/export_dialog.dart';

/// Users List Screen
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _userService = UserManagementService();
  final _exportService = ExportService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterStatus = 'All';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  final int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _userService.getUsers(
      page: _currentPage,
      limit: _pageSize,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      isActive: _filterStatus == 'All'
          ? null
          : _filterStatus == 'active',
    );

    if (response.success && response.data != null) {
      setState(() {
        _users = response.data!.data;
        _totalPages = response.data!.totalPages;
        _totalUsers = response.data!.total;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load users';
        _isLoading = false;
      });
    }
  }

  Future<void> _addUser(UserModel user) async {
    // Refresh the list to include the newly added user
    await _loadUsers();
  }

  void _viewUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => ViewUserDialog(user: user),
    );
  }

  void _editUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUserUpdated: (updatedUser) async {
          // Refresh the list to show updated user
          await _loadUsers();
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final newStatus = user.status.name == 'active' ? 'INACTIVE' : 'ACTIVE';
    final action = newStatus == 'ACTIVE' ? 'activate' : 'suspend';

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Text('Are you sure you want to $action ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'ACTIVE' ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _userService.updateUserStatus(
        userId: user.id,
        status: newStatus,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${action}d successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh the list
          await _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to update user status'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
    _loadUsers();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
      _loadUsers();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadUsers();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadUsers();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export Users',
        subtitle: 'Export user data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterStatus != 'All') 'Status': _filterStatus,
        },
        onExport: (format) async {
          final response = await _exportService.exportUsers(
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
              onPressed: _loadUsers,
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

    final users = _users;

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
                      'Manage and monitor all consumers',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddUserDialog(
                              onUserAdded: _addUser,
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
                          'Manage and monitor all consumers',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddUserDialog(
                            onUserAdded: _addUser,
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
                users.length.toString(),
                Icons.people,
                AppColors.accentBlue,
              ),
              _buildStatCard(
                context,
                'Active Consumers',
                users.where((u) => u.status.name == 'active').length.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
              _buildStatCard(
                context,
                'Pending KYC',
                users.where((u) => u.kycStatus.name == 'pending').length.toString(),
                Icons.pending,
                AppColors.warning,
              ),
              _buildStatCard(
                context,
                'Suspended',
                users.where((u) => u.status.name == 'suspended').length.toString(),
                Icons.block,
                AppColors.error,
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
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, or phone...',
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
                                borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
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
                            items: ['All', 'active', 'inactive', 'suspended']
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
                    : Row(
                        children: [
                          // Search Bar
                          Expanded(
                            flex: 2,
                            child: TextField(
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search by name, email, or phone...',
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
                              items: ['All', 'active', 'inactive', 'suspended']
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

                // Users List/Table
                isMobile || isTablet
                    ? Column(
                        children: users.map((user) => _buildUserCard(user)).toList(),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                    columns: [
                      DataColumn(
                        label: Text(
                          'User ID',
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
                          'Account Status',
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
                    rows: users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              user.id.length >= 8 ? user.id.substring(0, 8) : user.id,
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
                                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                                  child: Text(
                                    user.firstName.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Text(
                                  user.fullName,
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
                              user.email,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            Text(
                              user.phone ?? 'N/A',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            StatusBadge(status: user.kycStatus.name),
                          ),
                          DataCell(
                            StatusBadge(status: user.status.name),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatCurrency(user.walletBalance),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              Formatters.formatDate(user.createdAt),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility, color: AppColors.info, size: 20),
                                  onPressed: () => _viewUserDetails(user),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                                  onPressed: () => _editUser(user),
                                  tooltip: 'Edit User',
                                ),
                                IconButton(
                                  icon: Icon(
                                    user.status.name == 'ACTIVE'
                                        ? Icons.block
                                        : Icons.check_circle,
                                    color: user.status.name == 'ACTIVE'
                                        ? AppColors.error
                                        : AppColors.success,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleUserStatus(user),
                                  tooltip: user.status.name == 'ACTIVE'
                                      ? 'Suspend User'
                                      : 'Activate User',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                        ),

                SizedBox(height: isMobile ? AppTheme.space16 : AppTheme.space24),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize > _totalUsers ? _totalUsers : _currentPage * _pageSize} of $_totalUsers consumers',
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

  Widget _buildUserCard(UserModel user) {
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
                  user.firstName.substring(0, 1).toUpperCase(),
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
                      user.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
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
              StatusBadge(status: user.status.name),
              StatusBadge(status: user.kycStatus.name),
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
                      Formatters.formatCurrency(user.walletBalance),
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
                      'Registered',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(user.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
                onPressed: () => _viewUserDetails(user),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                onPressed: () => _editUser(user),
                tooltip: 'Edit User',
              ),
              IconButton(
                icon: Icon(
                  user.status.name == 'ACTIVE' ? Icons.block : Icons.check_circle,
                  color: user.status.name == 'ACTIVE' ? AppColors.error : AppColors.success,
                  size: 20,
                ),
                onPressed: () => _toggleUserStatus(user),
                tooltip: user.status.name == 'ACTIVE' ? 'Suspend User' : 'Activate User',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
