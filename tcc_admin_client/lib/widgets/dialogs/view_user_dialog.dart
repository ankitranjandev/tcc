import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';

/// Dialog for viewing user details
class ViewUserDialog extends StatelessWidget {
  final UserModel user;

  const ViewUserDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppTheme.space32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // User avatar and name
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                    child: Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Status badges
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space8,
                children: [
                  _buildStatusBadge(
                    user.status.displayName,
                    user.status.name == 'ACTIVE' ? AppColors.success : AppColors.error,
                  ),
                  _buildStatusBadge(
                    'KYC: ${user.kycStatus.displayName}',
                    _getKycStatusColor(user.kycStatus),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Details sections
              _buildDetailSection('Personal Information', [
                _buildDetailRow('First Name', user.firstName),
                _buildDetailRow('Last Name', user.lastName),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Phone', user.phone ?? 'N/A'),
                if (user.address != null)
                  _buildDetailRow('Address', user.address!),
              ]),
              const SizedBox(height: AppTheme.space24),

              _buildDetailSection('Account Information', [
                _buildDetailRow('User ID', user.id),
                _buildDetailRow('Status', user.status.displayName),
                _buildDetailRow('KYC Status', user.kycStatus.displayName),
                _buildDetailRow(
                  'Wallet Balance',
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##0.00').format(user.walletBalance)}',
                ),
                _buildDetailRow(
                  'Created At',
                  DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt),
                ),
                if (user.lastActive != null)
                  _buildDetailRow(
                    'Last Active',
                    DateFormat('MMM dd, yyyy HH:mm').format(user.lastActive!),
                  ),
              ]),
              const SizedBox(height: AppTheme.space24),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space16,
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getKycStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.pending:
        return AppColors.info;
    }
  }
}
