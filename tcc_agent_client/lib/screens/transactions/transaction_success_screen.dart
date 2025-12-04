import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class TransactionSuccessScreen extends StatelessWidget {
  const TransactionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    // Mock data - in real app, this comes from arguments
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final amount = 1000000.0;
    final commission = 25000.0;
    final userName = 'John Doe';
    final dateTime = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.successGreen,
        foregroundColor: Colors.white,
        leading: const SizedBox(), // Remove back button
        title: const Text('Transaction Successful'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 80,
                        color: AppColors.successGreen,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Transaction Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Money added to user wallet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Transaction Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Amount
                            Text(
                              'Amount Added',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SLL ${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),

                            const SizedBox(height: 24),
                            Divider(color: AppColors.borderLight),
                            const SizedBox(height: 20),

                            // Transaction Details
                            _buildDetailRow(
                              'Transaction ID',
                              transactionId,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'User',
                              userName,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Date & Time',
                              '${dateTime.day}/${dateTime.month}/${dateTime.year} '
                              '${dateTime.hour.toString().padLeft(2, '0')}:'
                              '${dateTime.minute.toString().padLeft(2, '0')}',
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Your Commission',
                              'SLL ${commission.toStringAsFixed(2)}',
                              valueColor: AppColors.commissionGreen,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Status',
                              'Completed',
                              valueColor: AppColors.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Commission Earned Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.commissionGreen,
                            AppColors.commissionGreen.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commission Earned',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SLL ${commission.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.infoBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.infoBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'User has received SMS confirmation. Receipt is available in transaction history.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Share receipt functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Receipt shared successfully'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        // Navigate back to dashboard
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
