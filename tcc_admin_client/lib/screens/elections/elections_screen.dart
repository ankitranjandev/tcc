import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/election_model.dart';
import '../../services/election_service.dart';
import '../../widgets/dialogs/create_election_dialog.dart';
import '../../widgets/dialogs/edit_election_dialog.dart';
import 'election_details_screen.dart';

class ElectionsScreen extends StatefulWidget {
  const ElectionsScreen({super.key});

  @override
  State<ElectionsScreen> createState() => _ElectionsScreenState();
}

class _ElectionsScreenState extends State<ElectionsScreen> with SingleTickerProviderStateMixin {
  final ElectionService _electionService = ElectionService();
  List<Election> _elections = [];
  List<Election> _filteredElections = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'all'; // all, active, ended, paused
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'all';
            break;
          case 1:
            _selectedFilter = 'active';
            break;
          case 2:
            _selectedFilter = 'paused';
            break;
          case 3:
            _selectedFilter = 'ended';
            break;
        }
        _applyFilter();
      });
    });
    _fetchElections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchElections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final elections = await _electionService.getAllElections();
      setState(() {
        _elections = elections;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredElections = _elections;
      } else {
        _filteredElections = _elections.where((e) => e.status == _selectedFilter).toList();
      }
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreateElectionDialog(),
    );

    if (result == true) {
      _fetchElections();
    }
  }

  Future<void> _showEditDialog(Election election) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditElectionDialog(election: election),
    );

    if (result == true) {
      _fetchElections();
    }
  }

  Future<void> _endElection(Election election) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Election'),
        content: Text('Are you sure you want to end "${election.title}"?'),
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
        await _electionService.endElection(election.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election ended successfully')),
          );
        }
        _fetchElections();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _togglePause(Election election) async {
    try {
      if (election.isPaused) {
        await _electionService.resumeElection(election.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election resumed successfully')),
          );
        }
      } else {
        await _electionService.pauseElection(election.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election paused successfully')),
          );
        }
      }
      _fetchElections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteElection(Election election) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Election'),
        content: Text(
          election.hasVotes
              ? 'This election has votes and cannot be deleted.'
              : 'Are you sure you want to delete "${election.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (!election.hasVotes)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _electionService.deleteElection(election.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Election deleted successfully')),
          );
        }
        _fetchElections();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
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
        title: const Text('E-Voting Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchElections,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Paused'),
            Tab(text: 'Ended'),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Election'),
      ),
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
              onPressed: _fetchElections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredElections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No elections yet'
                  : 'No $_selectedFilter elections',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_selectedFilter == 'all') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showCreateDialog,
                child: const Text('Create First Election'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchElections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredElections.length,
        itemBuilder: (context, index) {
          final election = _filteredElections[index];
          return _buildElectionCard(election);
        },
      ),
    );
  }

  Widget _buildElectionCard(Election election) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final now = DateTime.now();
    final timeRemaining = election.endTime.difference(now);
    final daysRemaining = timeRemaining.inDays;
    final hoursRemaining = timeRemaining.inHours % 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ElectionDetailsScreen(electionId: election.id),
            ),
          ).then((_) => _fetchElections());
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(election.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      election.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(election.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                election.question,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.how_to_vote, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${election.totalVotes} votes'),
                  const SizedBox(width: 16),
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Le ${election.totalRevenue.toStringAsFixed(2)} revenue'),
                  const SizedBox(width: 16),
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Le ${election.votingCharge.toStringAsFixed(2)}/vote'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Ends: ${dateFormat.format(election.endTime)}'),
                  if (election.isActive && timeRemaining.isNegative == false) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($daysRemaining days, $hoursRemaining hours left)',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (election.isActive) ...[
                    ElevatedButton.icon(
                      onPressed: () => _togglePause(election),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _endElection(election),
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('End'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                  if (election.isPaused)
                    ElevatedButton.icon(
                      onPressed: () => _togglePause(election),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (!election.hasVotes && !election.isEnded)
                    OutlinedButton.icon(
                      onPressed: () => _showEditDialog(election),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ElectionDetailsScreen(electionId: election.id),
                        ),
                      ).then((_) => _fetchElections());
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (!election.hasVotes)
                    OutlinedButton.icon(
                      onPressed: () => _deleteElection(election),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
