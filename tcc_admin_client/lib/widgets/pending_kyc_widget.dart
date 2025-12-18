import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../services/kyc_service.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class PendingKYCWidget extends StatefulWidget {
  const PendingKYCWidget({super.key});

  @override
  State<PendingKYCWidget> createState() => _PendingKYCWidgetState();
}

class _PendingKYCWidgetState extends State<PendingKYCWidget> {
  final KycService _kycService = KycService();
  int _pendingCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadPendingKYC();
  }

  Future<void> _loadPendingKYC() async {
    try {
      setState(() => _isLoading = true);

      // Get pending count
      final countResponse = await _kycService.getPendingKycCount();
      if (countResponse.success) {
        _pendingCount = countResponse.data ?? 0;
      }

      // Get recent pending submissions
      final submissionsResponse = await _kycService.getKycSubmissions(
        status: 'SUBMITTED',
        perPage: 5,
      );

      if (submissionsResponse.success && submissionsResponse.data != null) {
        _recentSubmissions = submissionsResponse.data!.items;
      }
    } catch (e) {
      developer.log('Error loading pending KYC: $e', name: 'PendingKYCWidget');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToKYCPage() {
    context.go('/agents?kyc_filter=pending');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _navigateToKYCPage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_late,
                      color: AppColors.warningOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending KYC',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            _pendingCount.toString(),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Action Required',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              if (_pendingCount > 0) ...[
                const SizedBox(height: 16),
                Divider(color: AppColors.borderLight),
                const SizedBox(height: 16),

                // Recent submissions
                Text(
                  'Recent Submissions',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (_recentSubmissions.isNotEmpty)
                  ...List.generate(
                    _recentSubmissions.length > 3 ? 3 : _recentSubmissions.length,
                    (index) => _buildSubmissionItem(_recentSubmissions[index]),
                  )
                else
                  Text(
                    'No pending submissions',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                const SizedBox(height: 16),

                // View all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToKYCPage,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      'Review All $_pendingCount Pending',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (!_isLoading) ...[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.successGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All KYC requests processed',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No pending verifications',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(Map<String, dynamic> submission) {
    final userName = '${submission['first_name'] ?? ''} ${submission['last_name'] ?? ''}'.trim();
    final submittedAt = submission['created_at'] != null
        ? _formatTimeAgo(DateTime.parse(submission['created_at']))
        : 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? userName : 'Unknown User',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  submittedAt,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Pending',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warningOrange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}