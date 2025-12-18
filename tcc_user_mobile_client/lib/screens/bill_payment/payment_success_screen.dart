import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../config/app_colors.dart';

class PaymentSuccessScreen extends StatefulWidget {
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
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadReceipt() async {
    setState(() {
      _isDownloading = true;
    });

    try {

      // Create PDF document
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'TCC',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2196F3'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'The Community Coin',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          'Payment Receipt',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#4CAF50').flatten(),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 24),

                  // Amount
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Amount Paid',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          currencyFormat.format(widget.amount),
                          style: pw.TextStyle(
                            fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2196F3'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 24),

                  // Transaction Details
                  _buildPdfDetailRow('Transaction ID', widget.transactionId),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow(
                    'Date & Time',
                    DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                  ),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Provider', widget.provider),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Bill Type', widget.billType),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Account Number', widget.accountNumber),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Payment Method', widget.paymentMethod),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Status', 'Success'),

                  pw.SizedBox(height: 32),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 24),

                  // Footer
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for your payment',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'This is a computer-generated receipt and does not require a signature.',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'TCC_Receipt_${widget.transactionId}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'TCC Payment Receipt - Transaction ID: ${widget.transactionId}',
        subject: 'Payment Receipt',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt ready to save or share'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

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
                        currencyFormat.format(widget.amount),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      SizedBox(height: 32),

                      // Transaction Details Card (wrapped in RepaintBoundary for screenshot)
                      RepaintBoundary(
                        key: _receiptKey,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: EdgeInsets.all(20),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Receipt Header
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'TCC',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Payment Receipt',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: AppColors.success,
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'PAID',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Divider(),
                                SizedBox(height: 16),

                                // Amount
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Amount Paid',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        currencyFormat.format(widget.amount),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Divider(),
                                SizedBox(height: 16),

                                // Transaction Details
                                _buildDetailRow(
                                  context,
                                  'Transaction ID',
                                  widget.transactionId,
                                  canCopy: false,
                                ),
                                SizedBox(height: 12),
                                _buildDetailRow(
                                  context,
                                  'Date & Time',
                                  DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                                ),
                                SizedBox(height: 12),
                                _buildDetailRow(context, 'Provider', widget.provider),
                                SizedBox(height: 12),
                                _buildDetailRow(context, 'Bill Type', widget.billType),
                                SizedBox(height: 12),
                                _buildDetailRow(context, 'Account Number', widget.accountNumber),
                                SizedBox(height: 12),
                                _buildDetailRow(context, 'Payment Method', widget.paymentMethod),
                                SizedBox(height: 12),
                                _buildDetailRow(
                                  context,
                                  'Status',
                                  'Success',
                                  statusColor: AppColors.success,
                                ),

                                SizedBox(height: 24),
                                Divider(),
                                SizedBox(height: 16),

                                // Footer
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Thank you for your payment',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'The Community Coin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        onPressed: _isDownloading ? null : _downloadReceipt,
                        icon: _isDownloading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              )
                            : Icon(Icons.download),
                        label: Text(_isDownloading ? 'Downloading...' : 'Download Receipt'),
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
                          // Navigate to dashboard and clear navigation stack
                          while (context.canPop()) {
                            context.pop();
                          }
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