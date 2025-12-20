import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vote_model.dart';
import '../../config/app_colors.dart';

class ElectionResultsScreen extends StatelessWidget {
  final ElectionModel election;

  const ElectionResultsScreen({super.key, required this.election});

  @override
  Widget build(BuildContext context) {
    final totalVotes = election.options.fold<int>(
      0,
      (sum, option) => sum + option.voteCount,
    );

    // Sort options by vote count
    final sortedOptions = List<PollOption>.from(election.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Results'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Election Info Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: election.isClosed
                      ? [Colors.grey[700]!, Colors.grey[600]!]
                      : [AppColors.primaryOrange, const Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          election.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          election.isClosed ? 'CLOSED' : 'ONGOING',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    election.question,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Votes',
                          totalVotes.toString(),
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Revenue',
                          'TCC${(election.totalRevenue ?? 0).toStringAsFixed(0)}',
                          Icons.monetization_on,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Started',
                          DateFormat('MMM dd, yyyy').format(election.startDate),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Ended',
                          DateFormat('MMM dd, yyyy').format(election.endDate),
                          Icons.event_available,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Vote Status
            if (election.hasVoted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You voted for:',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sortedOptions
                                .firstWhere((opt) => opt.id == election.userVote)
                                .label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Results Header
            const Text(
              'Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Results List
            ...sortedOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final percentage = totalVotes > 0
                  ? (option.voteCount / totalVotes * 100)
                  : 0.0;
              final isWinning = index == 0;
              final isUserVote = election.userVote == option.id;

              return _buildResultCard(
                option,
                percentage,
                isWinning: isWinning,
                isUserVote: isUserVote,
              );
            }),

            const SizedBox(height: 24),

            // Winner Announcement
            if (election.isClosed && sortedOptions.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Winning Option',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sortedOptions.first.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${sortedOptions.first.voteCount} votes (${(sortedOptions.first.voteCount / totalVotes * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    PollOption option,
    double percentage, {
    bool isWinning = false,
    bool isUserVote = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning
              ? AppColors.primaryOrange
              : (isUserVote ? Colors.green : Colors.grey[300]!),
          width: isWinning || isUserVote ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option Header
          Row(
            children: [
              if (isWinning)
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              if (isWinning) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isWinning ? FontWeight.bold : FontWeight.w600,
                    color: isWinning ? AppColors.primaryOrange : Colors.black,
                  ),
                ),
              ),
              if (isUserVote)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your Vote',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isWinning ? AppColors.primaryOrange : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${option.voteCount} ${option.voteCount == 1 ? 'vote' : 'votes'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isWinning ? AppColors.primaryOrange : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
