import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../widgets/payment_bottom_sheet.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../services/transaction_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  late TransactionModel _currentTransaction;
  bool _isRefreshing = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  Future<void> _refreshPaymentStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Fetch updated transaction details
      final result = await _transactionService.getTransactionDetails(
        transactionId: _currentTransaction.transactionId,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _currentTransaction = TransactionModel.fromJson(result['data']);
          _isRefreshing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment status updated: ${_currentTransaction.statusText}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Failed to fetch transaction');
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh payment status'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _statusColor(BuildContext context) {
    switch (_currentTransaction.status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  Color get _typeColor {
    if (_currentTransaction.isCredit) {
      return AppColors.success;
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_currentTransaction.status == 'PENDING')
            IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    )
                  : Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
              onPressed: _isRefreshing ? null : _refreshPaymentStatus,
              tooltip: 'Refresh payment status',
            ),
          IconButton(
            icon: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
            onPressed: () => _shareTransactionReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _statusColor(context).withValues(alpha: 0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTransactionIcon(_currentTransaction.type),
                      color: _typeColor,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_currentTransaction.isCredit ? '+' : ''}${currencyFormat.format(_currentTransaction.amount)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentTransaction.statusText,
                      style: TextStyle(
                        color: _statusColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(context, 'Type', _getTransactionTypeName(_currentTransaction.type)),
                        SizedBox(height: 10),
                        _buildDetailRow(context, 'Description', _currentTransaction.description ?? 'N/A'),
                        // Show other party details for transfers
                        if (_currentTransaction.otherParty != null) ...[
                          SizedBox(height: 10),
                          _buildDetailRow(
                            context,
                            _currentTransaction.isCredit ? 'From' : 'To',
                            _currentTransaction.otherParty!.name ?? 'Unknown',
                          ),
                          if (_currentTransaction.otherParty!.phone != null) ...[
                            SizedBox(height: 10),
                            _buildDetailRow(
                              context,
                              _currentTransaction.isCredit ? 'Sender Phone' : 'Recipient Phone',
                              _currentTransaction.otherParty!.phone!,
                            ),
                          ],
                        ],
                        if (_currentTransaction.recipient != null) ...[
                          SizedBox(height: 10),
                          _buildDetailRow(context, 'Recipient', _currentTransaction.recipient!),
                        ],
                        if (_currentTransaction.accountInfo != null) ...[
                          SizedBox(height: 10),
                          _buildDetailRow(context, 'Account', _currentTransaction.accountInfo!),
                        ],
                        SizedBox(height: 10),
                        _buildDetailRow(context, 'Date', date_utils.DateUtils.formatDetailDate(_currentTransaction.date)),
                        SizedBox(height: 10),
                        _buildDetailRow(context, 'Time', date_utils.DateUtils.formatDetailTime(_currentTransaction.date)),
                        SizedBox(height: 10),
                        _buildDetailRow(context, 'Transaction ID', _currentTransaction.id),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Amount Breakdown
                  Text(
                    'Amount Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildAmountRow(context, 'Amount', currencyFormat.format(_currentTransaction.amount.abs())),
                        SizedBox(height: 8),
                        _buildAmountRow(context, 'Fee', currencyFormat.format(_currentTransaction.fee)),
                        SizedBox(height: 8),
                        Divider(height: 1),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            Text(
                              currencyFormat.format(_currentTransaction.amount.abs() + _currentTransaction.fee),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _typeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Action Buttons
                  if (_currentTransaction.status == 'COMPLETED') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : () => _downloadReceipt(context),
                        icon: _isDownloading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.download, size: 20),
                        label: Text(_isDownloading ? 'Downloading...' : 'Download Receipt', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : () => _shareReceiptPdf(context),
                        icon: _isSharing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : Icon(Icons.share, size: 20),
                        label: Text(_isSharing ? 'Preparing...' : 'Share Receipt', style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showSupportDialog(context);
                        },
                        icon: Icon(Icons.help_outline, size: 20),
                        label: Text('Get Support', style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_currentTransaction.status == 'PENDING') ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This transaction is being processed. It may take a few minutes to complete.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_currentTransaction.status == 'FAILED') ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This transaction failed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () => _retryTransaction(context),
                              icon: Icon(Icons.refresh, size: 18),
                              label: Text('Retry Transaction', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(BuildContext context, String label, String value) {
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
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'DEPOSIT':
        return Icons.add_circle;
      case 'WITHDRAWAL':
        return Icons.remove_circle;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'BILL_PAYMENT':
        return Icons.receipt;
      case 'INVESTMENT':
        return Icons.trending_up;
      default:
        return Icons.payment;
    }
  }

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TRANSFER':
        return 'Transfer';
      case 'BILL_PAYMENT':
        return 'Bill Payment';
      case 'INVESTMENT':
        return 'Investment';
      default:
        return type;
    }
  }

  Future<void> _shareTransactionReceipt(BuildContext context) async {
    final currencyFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 2);

    // Generate receipt text
    final StringBuffer receipt = StringBuffer();
    receipt.writeln('==== TRANSACTION RECEIPT ====');
    receipt.writeln('');
    receipt.writeln('Transaction ID: ${_currentTransaction.id}');
    receipt.writeln('Status: ${_currentTransaction.statusText}');
    receipt.writeln('Type: ${_getTransactionTypeName(_currentTransaction.type)}');
    receipt.writeln('');
    receipt.writeln('Amount: ${_currentTransaction.isCredit ? '+' : ''}${currencyFormat.format(_currentTransaction.amount)}');
    if (_currentTransaction.fee > 0) {
      receipt.writeln('Fee: ${currencyFormat.format(_currentTransaction.fee)}');
      receipt.writeln('Total: ${currencyFormat.format(_currentTransaction.amount.abs() + _currentTransaction.fee)}');
    }

    if (_currentTransaction.description != null) {
      receipt.writeln('Description: ${_currentTransaction.description}');
    }

    // Include other party details
    if (_currentTransaction.otherParty != null) {
      final partyLabel = _currentTransaction.isCredit ? 'From' : 'To';
      receipt.writeln('$partyLabel: ${_currentTransaction.otherParty!.name ?? 'Unknown'}');
      if (_currentTransaction.otherParty!.phone != null) {
        receipt.writeln('Phone: ${_currentTransaction.otherParty!.phone}');
      }
    }

    if (_currentTransaction.recipient != null) {
      receipt.writeln('Recipient: ${_currentTransaction.recipient}');
    }

    if (_currentTransaction.accountInfo != null) {
      receipt.writeln('Account: ${_currentTransaction.accountInfo}');
    }

    receipt.writeln('');
    receipt.writeln('Date: ${date_utils.DateUtils.formatDetailDate(_currentTransaction.date)}');
    receipt.writeln('Time: ${date_utils.DateUtils.formatDetailTime(_currentTransaction.date)}');
    receipt.writeln('');
    receipt.writeln('-----------------------------');
    receipt.writeln('Thank you for using TCC Mobile');
    receipt.writeln('For support: support@tcc.com');

    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        receipt.toString(),
        subject: 'Transaction Receipt - ${_currentTransaction.id}',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Downloads the receipt PDF from the backend and opens a share dialog
  /// which allows the user to save it to their desired location
  Future<void> _downloadReceipt(BuildContext context) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Download PDF from backend
      final result = await _transactionService.downloadReceiptPdf(
        transactionId: _currentTransaction.transactionId,
      );

      if (result['success'] == true && result['data'] != null) {
        final bytes = result['data'] as List<int>;

        // Save to temporary directory
        final directory = await getTemporaryDirectory();
        final fileName = 'TCC_Receipt_${_currentTransaction.transactionId}.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Open share dialog - allows user to save or share the file
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'TCC Transaction Receipt',
          subject: 'Transaction Receipt - ${_currentTransaction.transactionId}',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt ready to save'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to download receipt');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Shares the receipt as a PDF file
  Future<void> _shareReceiptPdf(BuildContext context) async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Download PDF from backend
      final result = await _transactionService.downloadReceiptPdf(
        transactionId: _currentTransaction.transactionId,
      );

      if (result['success'] == true && result['data'] != null) {
        final bytes = result['data'] as List<int>;

        // Save to temporary directory
        final directory = await getTemporaryDirectory();
        final fileName = 'TCC_Receipt_${_currentTransaction.transactionId}.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Open share dialog
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'TCC Transaction Receipt - ${_currentTransaction.transactionId}',
          subject: 'Transaction Receipt',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to generate receipt');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${_currentTransaction.id}'),
            SizedBox(height: 16),
            Text(
              'Our support team is available to help you with this transaction.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email, color: AppColors.primaryBlue),
              title: Text('Email Support'),
              subtitle: Text('support@tcc.com'),
              dense: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone, color: AppColors.primaryBlue),
              title: Text('Phone Support'),
              subtitle: Text('+232 XX XXX XXXX'),
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Support request submitted!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _retryTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentBottomSheet(
        amount: _currentTransaction.amount.abs(),
        title: 'Retry ${_getTransactionTypeName(_currentTransaction.type)}',
        description: 'Retry failed transaction for Le ${_currentTransaction.amount.abs().toStringAsFixed(0)}',
        metadata: {
          'type': 'retry_transaction',
          'original_transaction_id': _currentTransaction.id,
          'transaction_type': _currentTransaction.type,
          'description': _currentTransaction.description,
          'recipient': _currentTransaction.recipient,
        },
        onSuccess: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction completed successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back to transactions after delay
          Future.delayed(Duration(seconds: 2), () {
            if (context.mounted) {
              context.pop();
            }
          });
        },
        onFailure: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction failed again. Please contact support.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
