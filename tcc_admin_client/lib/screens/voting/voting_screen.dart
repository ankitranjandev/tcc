import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/poll_model.dart';
import '../../services/poll_service.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/dialogs/create_poll_dialog.dart';
import '../../widgets/dialogs/export_dialog.dart';

/// E-Voting Screen
class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final PollService _pollService = PollService();
  final ExportService _exportService = ExportService();
  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _isLoading = true;
  List<PollModel> _polls = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _pollService.getAllPolls();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _polls = response.data!;
        } else {
          _errorMessage = response.error?.message ?? 'Failed to load polls';
        }
      });
    }
  }

  Future<void> _publishPoll(String pollId) async {
    final response = await _pollService.publishPoll(pollId);

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll published successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPolls();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to publish poll'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        title: 'Export E-Voting Data',
        subtitle: 'Export poll and voting data in your preferred format',
        filters: {
          if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
          if (_filterStatus != 'All') 'Status': _filterStatus,
        },
        onExport: (format) async {
          final response = await _exportService.exportEVoting(
            format: format,
            status: _filterStatus == 'All' ? null : _filterStatus,
          );
          
          if (!response.success) {
            throw Exception(response.message ?? 'Export failed');
          }
        },
      ),
    );
  }

  Future<void> _showCreatePollDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CreatePollDialog(
        onPollCreated: (poll) {
          // Refresh the polls list
          _loadPolls();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Filter polls based on search and status
    final filteredPolls = _polls.where((poll) {
      final matchesSearch =
          poll.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              poll.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _filterStatus == 'All' || poll.status == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    // Calculate stats
    final totalPolls = _polls.length;
    final activePolls = _polls.where((p) => p.status == 'ACTIVE').length;
    final totalVotes = _polls.fold<int>(0, (sum, poll) => sum + poll.totalVotes);
    final totalRevenue = _polls.fold<double>(0.0, (sum, poll) => sum + poll.totalRevenue);

    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentPurple,
        ),
      );
    }

    // Show error message
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppTheme.space16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            ElevatedButton.icon(
              onPressed: _loadPolls,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolls,
      color: AppColors.accentPurple,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Page Header
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'E-Voting Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Create and manage community polls and voting',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                ElevatedButton.icon(
                  onPressed: _showCreatePollDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Poll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
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
                      'E-Voting Management',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Create and manage community polls and voting',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showCreatePollDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Poll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
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
                'Total Polls',
                totalPolls.toString(),
                Icons.poll,
                AppColors.accentPurple,
              ),
              _buildStatCard(
                'Active Polls',
                activePolls.toString(),
                Icons.how_to_vote,
                AppColors.success,
              ),
              _buildStatCard(
                'Total Votes',
                totalVotes.toString(),
                Icons.people,
                AppColors.info,
              ),
              _buildStatCard(
                'Revenue',
                Formatters.formatCurrencyCompact(totalRevenue),
                Icons.account_balance_wallet,
                AppColors.warning,
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
                          hintText: 'Search polls by title...',
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
                            borderSide:
                                BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
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
                        ),
                        items: ['All', 'ACTIVE', 'ENDED', 'DRAFT']
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

                      // Action Buttons Row
                      Row(
                        children: [
                          // Refresh Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loadPolls,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space24,
                                  vertical: AppTheme.space16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),

                          // Export Button
                          Expanded(
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
                            hintText: 'Search polls by title or question...',
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
                              borderSide:
                                  BorderSide(color: AppColors.accentPurple, width: 2),
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
                          items: ['All', 'ACTIVE', 'ENDED', 'DRAFT']
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

                      // Refresh Button
                      IconButton(
                        onPressed: _loadPolls,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh polls',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(AppTheme.space20),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),

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
                const SizedBox(height: AppTheme.space24),

                // Polls List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPolls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.space16),
                  itemBuilder: (context, index) {
                    final poll = filteredPolls[index];
                    return _buildPollCard(poll, isMobile, isTablet);
                  },
                ),

                if (filteredPolls.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.poll_outlined,
                              size: 64, color: AppColors.gray400),
                          const SizedBox(height: AppTheme.space16),
                          Text(
                            'No polls found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppTheme.space24),

                // Pagination
                if (filteredPolls.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${filteredPolls.length} of ${_polls.length} polls',
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
                              color: AppColors.accentPurple,
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
      ),
    );
  }

  Widget _buildPollCard(PollModel poll, bool isMobile, bool isTablet) {
    final status = poll.status;
    final title = poll.title;
    final description = poll.description;
    final options = poll.options;
    final votingCharge = poll.voteCharge;
    final totalVotes = poll.totalVotes;
    final totalRevenue = poll.totalRevenue;
    final startDate = poll.startDate;
    final endDate = poll.endDate;

    // Calculate total votes for percentage
    final totalOptionsVotes = options.fold<int>(0, (sum, opt) => sum + opt.votes);

    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.poll, color: AppColors.accentPurple, size: 20),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: AppTheme.space20),

          // Options
          Column(
            children: options.map<Widget>((option) {
              final optionText = option.optionText;
              final votes = option.votes;
              final percentage = totalOptionsVotes > 0 ? (votes / totalOptionsVotes) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          optionText,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$votes votes (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.gray200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.space20),

          // Stats Row/Grid
          if (isMobile || isTablet)
            // Mobile/Tablet: 2-column grid
            Wrap(
              spacing: AppTheme.space16,
              runSpacing: AppTheme.space16,
              children: [
                _buildPollStat(Icons.how_to_vote, 'Total Votes', totalVotes.toString()),
                _buildPollStat(Icons.attach_money, 'Charge',
                    Formatters.formatCurrency(votingCharge)),
                _buildPollStat(Icons.account_balance_wallet, 'Revenue',
                    Formatters.formatCurrency(totalRevenue)),
                _buildPollStat(Icons.calendar_today, 'Start',
                    Formatters.formatDate(startDate)),
                _buildPollStat(
                    Icons.event, 'End', Formatters.formatDate(endDate)),
              ],
            )
          else
            // Desktop: Horizontal row
            Row(
              children: [
                _buildPollStat(Icons.how_to_vote, 'Total Votes', totalVotes.toString()),
                const SizedBox(width: AppTheme.space24),
                _buildPollStat(Icons.attach_money, 'Voting Charge',
                    Formatters.formatCurrency(votingCharge)),
                const SizedBox(width: AppTheme.space24),
                _buildPollStat(Icons.account_balance_wallet, 'Revenue',
                    Formatters.formatCurrency(totalRevenue)),
                const SizedBox(width: AppTheme.space24),
                _buildPollStat(Icons.calendar_today, 'Start',
                    Formatters.formatDate(startDate)),
                const SizedBox(width: AppTheme.space24),
                _buildPollStat(
                    Icons.event, 'End', Formatters.formatDate(endDate)),
              ],
            ),

          const SizedBox(height: AppTheme.space20),

          // Actions
          if (isMobile || isTablet)
            // Mobile/Tablet: Stacked layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status == 'DRAFT')
                  ElevatedButton.icon(
                    onPressed: () => _publishPoll(poll.pollId),
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                if (status == 'DRAFT') const SizedBox(height: AppTheme.space8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: View details
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Edit poll
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    if (status == 'ACTIVE') ...[
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: End poll
                          },
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('End Poll'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Delete poll
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            )
          else
            // Desktop: Horizontal layout
            Row(
              children: [
                if (status == 'DRAFT')
                  ElevatedButton.icon(
                    onPressed: () => _publishPoll(poll.pollId),
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                const SizedBox(width: AppTheme.space12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: View details
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: AppTheme.space12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Edit poll
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                if (status == 'ACTIVE') ...[
                  const SizedBox(width: AppTheme.space12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: End poll
                    },
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('End Poll'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    // TODO: Delete poll
                  },
                  tooltip: 'Delete Poll',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPollStat(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
