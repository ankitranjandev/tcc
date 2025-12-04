import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vote_model.dart';
import '../../config/app_colors.dart';
import 'cast_vote_screen.dart';
import 'election_results_screen.dart';

class ElectionsScreen extends StatefulWidget {
  const ElectionsScreen({super.key});

  @override
  State<ElectionsScreen> createState() => _ElectionsScreenState();
}

class _ElectionsScreenState extends State<ElectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;

  // Mock data - Replace with API call
  final List<ElectionModel> _openElections = [
    ElectionModel(
      id: '1',
      title: 'Community Development Project',
      question: 'Which project should we prioritize this year?',
      options: [
        PollOption(id: '1', electionId: '1', label: 'New School Building', voteCount: 45),
        PollOption(id: '2', electionId: '1', label: 'Water Supply System', voteCount: 32),
        PollOption(id: '3', electionId: '1', label: 'Road Construction', voteCount: 28),
      ],
      votingCharge: 100.0,
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      status: 'open',
      totalVotes: 105,
      totalRevenue: 10500.0,
      hasVoted: false,
    ),
    ElectionModel(
      id: '2',
      title: 'Budget Allocation 2024',
      question: 'How should we allocate the community budget?',
      options: [
        PollOption(id: '4', electionId: '2', label: 'Infrastructure', voteCount: 23),
        PollOption(id: '5', electionId: '2', label: 'Education', voteCount: 19),
        PollOption(id: '6', electionId: '2', label: 'Healthcare', voteCount: 15),
      ],
      votingCharge: 50.0,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      status: 'open',
      totalVotes: 57,
      totalRevenue: 2850.0,
      hasVoted: true,
      userVote: '4',
    ),
  ];

  final List<ElectionModel> _closedElections = [
    ElectionModel(
      id: '3',
      title: 'Market Renovation Decision',
      question: 'Should we renovate the central market?',
      options: [
        PollOption(id: '7', electionId: '3', label: 'Yes, renovate completely', voteCount: 89),
        PollOption(id: '8', electionId: '3', label: 'Partial renovation', voteCount: 45),
        PollOption(id: '9', electionId: '3', label: 'No, keep as is', voteCount: 12),
      ],
      votingCharge: 75.0,
      startDate: DateTime.now().subtract(const Duration(days: 15)),
      endDate: DateTime.now().subtract(const Duration(days: 3)),
      status: 'closed',
      totalVotes: 146,
      totalRevenue: 10950.0,
      hasVoted: true,
      userVote: '7',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Open Elections',
              icon: Badge(
                label: Text(_openElections.length.toString()),
                child: const Icon(Icons.how_to_vote),
              ),
            ),
            Tab(
              text: 'Closed Elections',
              icon: Badge(
                label: Text(_closedElections.length.toString()),
                child: const Icon(Icons.poll),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOpenElections(),
          _buildClosedElections(),
        ],
      ),
    );
  }

  Widget _buildOpenElections() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_openElections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ballot_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Open Elections',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new elections',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement API refresh
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _openElections.length,
        itemBuilder: (context, index) {
          return _buildElectionCard(_openElections[index], isOpen: true);
        },
      ),
    );
  }

  Widget _buildClosedElections() {
    if (_closedElections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Closed Elections',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _closedElections.length,
      itemBuilder: (context, index) {
        return _buildElectionCard(_closedElections[index], isOpen: false);
      },
    );
  }

  Widget _buildElectionCard(ElectionModel election, {required bool isOpen}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isOpen && !election.hasVoted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CastVoteScreen(election: election),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ElectionResultsScreen(election: election),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge and Charge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? (election.hasVoted
                              ? Colors.green.withValues(alpha: 0.1)
                              : AppColors.primaryOrange.withValues(alpha: 0.1))
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpen
                              ? (election.hasVoted
                                  ? Icons.check_circle
                                  : Icons.radio_button_checked)
                              : Icons.archive,
                          size: 16,
                          color: isOpen
                              ? (election.hasVoted
                                  ? Colors.green
                                  : AppColors.primaryOrange)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOpen
                              ? (election.hasVoted ? 'Voted' : 'Open')
                              : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? (election.hasVoted
                                    ? Colors.green
                                    : AppColors.primaryOrange)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SLL ${election.votingCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                election.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Question
              Text(
                election.question,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${election.totalVotes} votes',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    isOpen
                        ? 'Ends ${DateFormat('MMM dd').format(election.endDate)}'
                        : 'Ended ${DateFormat('MMM dd').format(election.endDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time Remaining (for open elections)
              if (isOpen)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeRemaining(election.timeRemaining),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (!election.hasVoted)
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primaryOrange,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'} remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'} remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes remaining';
    } else {
      return 'Closing soon';
    }
  }
}
