import 'package:flutter/material.dart';
import 'dart:io';
import '../../config/app_colors.dart';
import 'payment_success_screen.dart';

class UploadPaymentDetailsScreen extends StatefulWidget {
  final String billType;
  final String provider;
  final double amount;
  final String accountNumber;

  const UploadPaymentDetailsScreen({
    super.key,
    required this.billType,
    required this.provider,
    required this.amount,
    required this.accountNumber,
  });

  @override
  State<UploadPaymentDetailsScreen> createState() => _UploadPaymentDetailsScreenState();
}

class _UploadPaymentDetailsScreenState extends State<UploadPaymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  File? _uploadedReceipt;
  bool _isProcessing = false;

  @override
  void dispose() {
    _transactionIdController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // In a real app, you would use image_picker package
    // For now, we'll simulate the selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image picker would open here'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );

    // Simulate file selection
    setState(() {
      // _uploadedReceipt = File('path/to/receipt.jpg');
    });
  }

  Future<void> _submitDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              billType: widget.billType,
              provider: widget.provider,
              amount: widget.amount,
              accountNumber: widget.accountNumber,
              paymentMethod: 'Bank Transfer (Upload)',
              transactionId: _transactionIdController.text.isNotEmpty
                  ? _transactionIdController.text
                  : 'TXN${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Payment Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions Card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Instructions',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '1. Make the payment to our bank account\n'
                              '2. Enter the transaction details below\n'
                              '3. Upload a screenshot of the payment receipt\n'
                              '4. We will verify and confirm your payment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Bank Details Card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Our Bank Details',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildBankDetailRow('Bank Name', 'TCC Bank Ltd'),
                            _buildBankDetailRow('Account Name', 'The Community Coin'),
                            _buildBankDetailRow('Account Number', '1234567890'),
                            _buildBankDetailRow('IFSC Code', 'TCC0001234'),
                            SizedBox(height: 8),
                            Divider(),
                            SizedBox(height: 8),
                            _buildBankDetailRow('Amount to Pay', '\$ ${widget.amount.toStringAsFixed(2)}', isBold: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Transaction ID
                      Text(
                        'Transaction ID / UTR Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _transactionIdController,
                        decoration: InputDecoration(
                          hintText: 'Enter transaction ID',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter transaction ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Reference Number
                      Text(
                        'Reference Number (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _referenceNumberController,
                        decoration: InputDecoration(
                          hintText: 'Enter reference number',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Upload Receipt
                      Text(
                        'Upload Payment Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _uploadedReceipt != null ? Icons.check : Icons.cloud_upload_outlined,
                                  color: AppColors.primaryBlue,
                                  size: 30,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                _uploadedReceipt != null
                                    ? 'Receipt uploaded'
                                    : 'Tap to upload receipt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'PNG, JPG or PDF (Max 5MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Note
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange[200]!,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your payment will be verified within 24 hours. You will receive a confirmation once verified.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[900],
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
            ),

            // Submit Button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          'Submit Details',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primaryBlue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
