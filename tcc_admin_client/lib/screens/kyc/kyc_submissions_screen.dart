import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../services/kyc_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import 'kyc_review_detail_screen.dart';

class KYCSubmissionsScreen extends StatefulWidget {
  const KYCSubmissionsScreen({super.key});

  @override
  State<KYCSubmissionsScreen> createState() => _KYCSubmissionsScreenState();
}

class _KYCSubmissionsScreenState extends State<KYCSubmissionsScreen> {
  final KycService _kycService = KycService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'ALL';
  String _selectedUserType = 'ALL'; // New filter for user type
  int _currentPage = 1;
  final int _limit = 20;
  int _totalPages = 1;

  final List<String> _statusFilters = ['ALL', 'PENDING', 'SUBMITTED', 'APPROVED', 'REJECTED'];
  final List<String> _userTypeFilters = ['ALL', 'CONSUMER', 'AGENT']; // Filter options

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _kycService.getKycSubmissions(
        page: _currentPage,
        perPage: _limit,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        userType: _selectedUserType == 'ALL' ? null : _selectedUserType.toLowerCase(),
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;
        setState(() {
          _submissions = paginatedData.data;
          _totalPages = paginatedData.totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load submissions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleSearch(String value) {
    setState(() {
      _currentPage = 1;
    });
    _loadSubmissions();
  }

  void _handleStatusFilter(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
    });
    _loadSubmissions();
  }

  void _handleUserTypeFilter(String userType) {
    setState(() {
      _selectedUserType = userType;
      _currentPage = 1;
    });
    _loadSubmissions();
  }

  void _handlePageChange(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadSubmissions();
  }

  void _handleViewSubmission(Map<String, dynamic> submission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KYCReviewDetailScreen(
          submissionId: submission['id'],
          userId: submission['user_id'],
        ),
      ),
    ).then((_) {
      // Refresh list when returning from detail screen
      _loadSubmissions();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'SUBMITTED':
        return AppColors.warning;
      case 'PENDING':
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Submissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
            color: AppColors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onSubmitted: _handleSearch,
                ),
                SizedBox(height: isMobile ? AppTheme.space12 : AppTheme.space16),
                // User Type Filter Chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _userTypeFilters.map((userType) {
                          final isSelected = _selectedUserType == userType;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppTheme.space8),
                            child: FilterChip(
                              label: Text(userType),
                              selected: isSelected,
                              onSelected: (_) => _handleUserTypeFilter(userType),
                              selectedColor: AppColors.accentPurple.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.accentPurple,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                // Status Filter Chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((status) {
                          final isSelected = _selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppTheme.space8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => _handleStatusFilter(status),
                              selectedColor: AppColors.accentBlue.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.accentBlue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Text(
                                'Error Loading Submissions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.space24),
                              ElevatedButton.icon(
                                onPressed: _loadSubmissions,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _submissions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppTheme.space16),
                                Text(
                                  'No submissions found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.all(
                                    isMobile ? AppTheme.space16 : AppTheme.space24,
                                  ),
                                  itemCount: _submissions.length,
                                  itemBuilder: (context, index) {
                                    final submission = _submissions[index];
                                    return _buildSubmissionCard(
                                      context,
                                      submission,
                                      isMobile,
                                    );
                                  },
                                ),
                              ),
                              // Pagination
                              if (_totalPages > 1)
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.space16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    border: Border(
                                      top: BorderSide(
                                        color: AppColors.divider,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 1
                                            ? () => _handlePageChange(_currentPage - 1)
                                            : null,
                                      ),
                                      const SizedBox(width: AppTheme.space16),
                                      Text(
                                        'Page $_currentPage of $_totalPages',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space16),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _currentPage < _totalPages
                                            ? () => _handlePageChange(_currentPage + 1)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    Map<String, dynamic> submission,
    bool isMobile,
  ) {
    final name = '${submission['first_name'] ?? ''} ${submission['last_name'] ?? ''}'.trim();
    final email = submission['email'] ?? '';
    final phone = submission['phone'] ?? '';
    final status = submission['kyc_status'] ?? 'PENDING';
    final submittedAt = submission['submitted_at'];
    final documentCount = submission['document_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: InkWell(
        onTap: () => _handleViewSubmission(submission),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.space12 : AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Unknown User',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    '$documentCount document${documentCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (submittedAt != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      Formatters.formatDate(DateTime.parse(submittedAt)),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
