import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String billType;
  final String provider;
  final double amount;
  final String accountNumber;
  final String paymentMethod;
  final String transactionId;

  const PaymentSuccessScreen({
    super.key,
    required this.billType,
    required this.provider,
    required this.amount,
    required this.accountNumber,
    required this.paymentMethod,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(height: 40),

                      // Success Animation
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 60,
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Payment Successful!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        currencyFormat.format(amount),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      SizedBox(height: 32),

                      // Transaction Details Card
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              context,
                              'Transaction ID',
                              transactionId,
                              canCopy: true,
                            ),
                            Divider(height: 24),
                            _buildDetailRow(
                              context,
                              'Date & Time',
                              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                            ),
                            Divider(height: 24),
                            _buildDetailRow(context, 'Provider', provider),
                            Divider(height: 24),
                            _buildDetailRow(context, 'Bill Type', billType),
                            Divider(height: 24),
                            _buildDetailRow(context, 'Account', accountNumber),
                            Divider(height: 24),
                            _buildDetailRow(context, 'Payment Method', paymentMethod),
                            Divider(height: 24),
                            _buildDetailRow(
                              context,
                              'Status',
                              'Success',
                              statusColor: AppColors.success,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Additional Info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'A confirmation has been sent to your registered mobile number and email.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryBlue,
                                  height: 1.4,
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
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement download receipt
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Receipt downloaded successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: Icon(Icons.download),
                        label: Text('Download Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool canCopy = false,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            if (canCopy) ...[
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transaction ID copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}