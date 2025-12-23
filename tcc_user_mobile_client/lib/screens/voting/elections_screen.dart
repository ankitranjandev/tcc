import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/election_model.dart';
import '../../services/election_service.dart';
import 'election_details_screen.dart';
import 'election_results_screen.dart';

class ElectionsScreen extends StatefulWidget {
  const ElectionsScreen({Key? key}) : super(key: key);

  @override
  State<ElectionsScreen> createState() => _ElectionsScreenState();
}

class _ElectionsScreenState extends State<ElectionsScreen>
    with SingleTickerProviderStateMixin {
  final ElectionService _electionService = ElectionService();
  late TabController _tabController;

  List<Election> _activeElections = [];
  List<Election> _closedElections = [];

  bool _isLoadingActive = true;
  bool _isLoadingClosed = true;
  String _activeError = '';
  String _closedError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchActiveElections();
    _fetchClosedElections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveElections() async {
    setState(() {
      _isLoadingActive = true;
      _activeError = '';
    });

    try {
      final elections = await _electionService.getActiveElections();
      setState(() {
        _activeElections = elections;
        _isLoadingActive = false;
      });
    } catch (e) {
      setState(() {
        _activeError = e.toString();
        _isLoadingActive = false;
      });
    }
  }

  Future<void> _fetchClosedElections() async {
    setState(() {
      _isLoadingClosed = true;
      _closedError = '';
    });

    try {
      final elections = await _electionService.getClosedElections();
      setState(() {
        _closedElections = elections;
        _isLoadingClosed = false;
      });
    } catch (e) {
      setState(() {
        _closedError = e.toString();
        _isLoadingClosed = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchActiveElections(),
      _fetchClosedElections(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Voting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Open Elections'),
            Tab(text: 'Closed Elections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveElections(),
          _buildClosedElections(),
        ],
      ),
    );
  }

  Widget _buildActiveElections() {
    if (_isLoadingActive) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeError.isNotEmpty) {
      return _buildErrorView(_activeError, _fetchActiveElections);
    }

    if (_activeElections.isEmpty) {
      return _buildEmptyView(
        icon: Icons.how_to_vote_outlined,
        message: 'No active elections at the moment',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveElections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeElections.length,
        itemBuilder: (context, index) {
          final election = _activeElections[index];
          return _buildElectionCard(election, isActive: true);
        },
      ),
    );
  }

  Widget _buildClosedElections() {
    if (_isLoadingClosed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_closedError.isNotEmpty) {
      return _buildErrorView(_closedError, _fetchClosedElections);
    }

    if (_closedElections.isEmpty) {
      return _buildEmptyView(
        icon: Icons.history,
        message: 'You haven\'t participated in any elections yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchClosedElections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _closedElections.length,
        itemBuilder: (context, index) {
          final election = _closedElections[index];
          return _buildElectionCard(election, isActive: false);
        },
      ),
    );
  }

  Widget _buildElectionCard(Election election, {required bool isActive}) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ElectionDetailsScreen(election: election),
              ),
            ).then((_) {
              _fetchActiveElections();
              _fetchClosedElections();
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ElectionResultsScreen(election: election),
              ),
            );
          }
        },
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (election.hasVoted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'VOTED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                election.question,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Le ${election.votingCharge.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.how_to_vote, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${election.totalVotes} votes'),
                ],
              ),
              const SizedBox(height: 8),
              if (isActive) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      election.timeRemainingText,
                      style: const TextStyle(color: Colors.orange),
                    ),
                    const Spacer(),
                    Text(
                      'Ends: ${dateFormat.format(election.endTime)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'You voted: ${election.options.firstWhere((o) => o.id == election.userVote?.optionId).optionText}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                if (election.userVote?.voteCharge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cost: Le ${election.userVote!.voteCharge!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
