import 'package:flutter/material.dart';
import '../../models/vote_model.dart';
import '../../config/app_colors.dart';

class CastVoteScreen extends StatefulWidget {
  final ElectionModel election;

  const CastVoteScreen({super.key, required this.election});

  @override
  State<CastVoteScreen> createState() => _CastVoteScreenState();
}

class _CastVoteScreenState extends State<CastVoteScreen> {
  String? _selectedOptionId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cast Your Vote'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Election Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryOrange, Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.election.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.election.question,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.people,
                              '${widget.election.totalVotes} votes',
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.access_time,
                              _formatTimeRemaining(widget.election.timeRemaining),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Voting Charge Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Voting charge: SLL ${widget.election.votingCharge.toStringAsFixed(0)} will be deducted from your wallet',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options Header
                  const Text(
                    'Select Your Choice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Poll Options
                  ...widget.election.options.map((option) => _buildOptionCard(option)),

                  const SizedBox(height: 16),

                  // Important Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Important',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Once you cast your vote, it cannot be changed. Please review your selection carefully.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedOptionId == null || _isSubmitting
                      ? null
                      : _confirmAndSubmitVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cast Vote',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(PollOption option) {
    final isSelected = _selectedOptionId == option.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOptionId = option.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryOrange : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryOrange : Colors.black,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndSubmitVote() {
    final selectedOption = widget.election.options
        .firstWhere((opt) => opt.id == _selectedOptionId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are voting for:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedOption.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Voting charge of SLL ${widget.election.votingCharge.toStringAsFixed(0)} will be deducted from your wallet.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitVote();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Confirm Vote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote cast successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cast vote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h remaining';
    } else {
      return '${duration.inMinutes}m remaining';
    }
  }
}
