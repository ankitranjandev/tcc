import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../models/agent_model.dart';
import '../../services/mock_data_service.dart';

class AgentSearchScreen extends StatefulWidget {
  const AgentSearchScreen({super.key});

  @override
  State<AgentSearchScreen> createState() => _AgentSearchScreenState();
}

class _AgentSearchScreenState extends State<AgentSearchScreen> {
  final MockDataService _mockService = MockDataService();
  final TextEditingController _searchController = TextEditingController();

  List<AgentModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchType = 'location';

  // Mock user location (Freetown, Sierra Leone)
  final double _userLatitude = 8.4657;
  final double _userLongitude = -13.2317;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAgents() async {
    if (_searchController.text.trim().isEmpty && _searchType != 'location') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a search term'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      List<AgentModel> results;

      switch (_searchType) {
        case 'location':
          results = await _mockService.searchAgentsByLocation(
            latitude: _userLatitude,
            longitude: _userLongitude,
            radiusKm: 50.0,
          );
          break;
        case 'phone':
          results = await _mockService.searchAgentsByPhone(
            _searchController.text.trim(),
          );
          break;
        case 'branch':
          results = await _mockService.searchAgentsByBankBranch(
            _searchController.text.trim(),
          );
          break;
        default:
          results = [];
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching agents: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openMaps(AgentModel agent) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${agent.latitude},${agent.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _callAgent(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make call'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Agent'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Type Selector
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search By',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSearchTypeChip('location', 'Nearby', Icons.location_on),
                      SizedBox(width: 8),
                      _buildSearchTypeChip('phone', 'Phone', Icons.phone),
                      SizedBox(width: 8),
                      _buildSearchTypeChip('branch', 'Bank Branch', Icons.account_balance),
                    ],
                  ),
                ],
              ),
            ),

            // Search Input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (_searchType != 'location')
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _searchType == 'phone'
                            ? 'Enter phone number'
                            : 'Enter bank or branch name',
                        prefixIcon: Icon(
                          _searchType == 'phone' ? Icons.phone : Icons.account_balance,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      onSubmitted: (_) => _searchAgents(),
                    ),

                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _searchAgents,
                      icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.search),
                      label: Text(
                        _isLoading ? 'Searching...' : 'Search Agents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            Divider(),

            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeChip(String type, String label, IconData icon) {
    final isSelected = _searchType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _searchType = type;
            _searchResults = [];
            _hasSearched = false;
            _searchController.clear();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).iconTheme.color,
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: Theme.of(context).dividerColor,
            ),
            SizedBox(height: 16),
            Text(
              'Search for agents near you',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Find TCC agents by location, phone number, or bank branch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).dividerColor,
            ),
            SizedBox(height: 16),
            Text(
              'No agents found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final agent = _searchResults[index];
        return _buildAgentCard(agent);
      },
    );
  }

  Widget _buildAgentCard(AgentModel agent) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    agent.firstName[0] + agent.lastName[0],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: AppColors.secondaryYellow),
                          SizedBox(width: 4),
                          Text(
                            agent.rating?.toStringAsFixed(1) ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${agent.totalTransactions ?? 0} transactions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),

            // Contact Information
            _buildInfoRow(Icons.phone, agent.phoneNumber),
            SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, agent.address),
            SizedBox(height: 8),
            _buildInfoRow(Icons.account_balance, agent.bankName),
            SizedBox(height: 8),
            _buildInfoRow(Icons.location_city, '${agent.bankBranchName}, ${agent.bankBranchAddress}'),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callAgent(agent.phoneNumber),
                    icon: Icon(Icons.phone, size: 18),
                    label: Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMaps(agent),
                    icon: Icon(Icons.directions, size: 18),
                    label: Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}
