import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/election_model.dart';
import '../../services/election_service.dart';

class ElectionDetailsScreen extends StatefulWidget {
  final int electionId;

  const ElectionDetailsScreen({Key? key, required this.electionId}) : super(key: key);

  @override
  State<ElectionDetailsScreen> createState() => _ElectionDetailsScreenState();
}

class _ElectionDetailsScreenState extends State<ElectionDetailsScreen> {
  final ElectionService _electionService = ElectionService();
  ElectionStats? _stats;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchElectionStats();
  }

  Future<void> _fetchElectionStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stats = await _electionService.getElectionStats(widget.electionId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _endElection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Election'),
        content: Text('Are you sure you want to end "${_stats?.election.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Election'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _electionService.endElection(widget.electionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election ended successfully')),
          );
        }
        _fetchElectionStats();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _togglePause() async {
    if (_stats == null) return;

    try {
      if (_stats!.election.isPaused) {
        await _electionService.resumeElection(widget.electionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election resumed successfully')),
          );
        }
      } else {
        await _electionService.pauseElection(widget.electionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election paused successfully')),
          );
        }
      }
      _fetchElectionStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _downloadResults() {
    if (_stats == null) return;

    // Create CSV content
    final csv = StringBuffer();
    csv.writeln('Election: ${_stats!.election.title}');
    csv.writeln('Question: ${_stats!.election.question}');
    csv.writeln('Status: ${_stats!.election.status}');
    csv.writeln('Total Votes: ${_stats!.election.totalVotes}');
    csv.writeln('Total Revenue: Le ${_stats!.election.totalRevenue.toStringAsFixed(2)}');
    csv.writeln('');
    csv.writeln('Vote Distribution:');
    csv.writeln('Option,Votes,Percentage');
    for (var option in _stats!.options) {
      csv.writeln('"${option.optionText}",${option.voteCount},${option.percentage?.toStringAsFixed(2)}%');
    }
    csv.writeln('');
    csv.writeln('Voter Details:');
    csv.writeln('User ID,Name,Option Selected,Vote Charge,Voted At');
    for (var voter in _stats!.voters) {
      csv.writeln('${voter.userId},"${voter.fullName}","${voter.optionText}",Le ${voter.voteCharge.toStringAsFixed(2)},${voter.votedAt}');
    }

    // Show dialog with CSV content (in real app, this would trigger download)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Election Results (CSV)'),
        content: SingleChildScrollView(
          child: SelectableText(
            csv.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'ended':
        return Colors.grey;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchElectionStats,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchElectionStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _fetchElectionStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildElectionInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildStatistics(),
            const SizedBox(height: 24),
            _buildVoteDistribution(),
            const SizedBox(height: 24),
            _buildVotersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionInfo() {
    final election = _stats!.election;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    election.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(election.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    election.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(election.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              election.question,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Voting Charge', 'Le ${election.votingCharge.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: _buildInfoItem('Start Time', dateFormat.format(election.startTime)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('End Time', dateFormat.format(election.endTime)),
                ),
                if (election.endedAt != null)
                  Expanded(
                    child: _buildInfoItem('Ended At', dateFormat.format(election.endedAt!)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final election = _stats!.election;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (election.isActive) ...[
          ElevatedButton.icon(
            onPressed: _togglePause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause Election'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          ElevatedButton.icon(
            onPressed: _endElection,
            icon: const Icon(Icons.stop),
            label: const Text('End Election'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
        if (election.isPaused)
          ElevatedButton.icon(
            onPressed: _togglePause,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume Election'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ElevatedButton.icon(
          onPressed: _downloadResults,
          icon: const Icon(Icons.download),
          label: const Text('Download Results'),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final election = _stats!.election;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Votes',
                    election.totalVotes.toString(),
                    Icons.how_to_vote,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    'Le ${election.totalRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vote Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stats!.options.isEmpty)
              const Text('No votes cast yet', style: TextStyle(color: Colors.grey))
            else
              ..._stats!.options.map((option) {
                final percentage = option.percentage ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              option.optionText,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${option.voteCount} votes (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVotersList() {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voters (${_stats!.voters.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stats!.voters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No votes cast yet', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('User ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Option Selected')),
                    DataColumn(label: Text('Charge')),
                    DataColumn(label: Text('Voted At')),
                  ],
                  rows: _stats!.voters.map((voter) {
                    return DataRow(cells: [
                      DataCell(Text(voter.userId.toString())),
                      DataCell(Text(voter.fullName)),
                      DataCell(Text(voter.optionText)),
                      DataCell(Text('Le ${voter.voteCharge.toStringAsFixed(2)}')),
                      DataCell(Text(dateFormat.format(voter.votedAt))),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
