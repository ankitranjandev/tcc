import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../models/transaction_model.dart';
import '../badges/status_badge.dart';

/// Dialog for viewing transaction details
class TransactionDetailsDialog extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          transaction.id,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Status badge
              StatusBadge(
                status: transaction.status.displayName,
                color: _getStatusColor(transaction.status),
              ),
              const SizedBox(height: AppTheme.space24),

              // Transaction Overview
              _buildDetailSection('Transaction Overview', [
                _buildDetailRow('Type', transaction.type.displayName),
                _buildDetailRow(
                  'Amount',
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##0.00').format(transaction.amount)}',
                ),
                _buildDetailRow(
                  'Fee',
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##0.00').format(transaction.fee)}',
                ),
                _buildDetailRow(
                  'Total',
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##0.00').format(transaction.total)}',
                ),
              ]),
              const SizedBox(height: AppTheme.space24),

              // User Information
              _buildDetailSection('User Information', [
                if (transaction.userName != null)
                  _buildDetailRow('User', transaction.userName!),
                _buildDetailRow('User ID', transaction.userId),
                if (transaction.agentName != null)
                  _buildDetailRow('Agent', transaction.agentName!),
                if (transaction.agentId != null)
                  _buildDetailRow('Agent ID', transaction.agentId!),
              ]),
              const SizedBox(height: AppTheme.space24),

              // Payment Details
              if (transaction.paymentMethod != null || transaction.description != null)
                _buildDetailSection('Payment Details', [
                  if (transaction.paymentMethod != null)
                    _buildDetailRow('Payment Method', transaction.paymentMethod!.replaceAll('_', ' ')),
                  if (transaction.description != null)
                    _buildDetailRow('Description', transaction.description!),
                ]),
              if (transaction.paymentMethod != null || transaction.description != null)
                const SizedBox(height: AppTheme.space24),

              // Timeline
              _buildDetailSection('Timeline', [
                _buildDetailRow(
                  'Created At',
                  DateFormat('MMM dd, yyyy HH:mm:ss').format(transaction.createdAt),
                ),
                if (transaction.completedAt != null)
                  _buildDetailRow(
                    'Completed At',
                    DateFormat('MMM dd, yyyy HH:mm:ss').format(transaction.completedAt!),
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
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
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

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
      case TransactionStatus.rejected:
        return AppColors.error;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.processing:
        return AppColors.info;
    }
  }
}
