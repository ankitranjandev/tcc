import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import 'payment_success_screen.dart';
import 'add_bank_account_screen.dart';
import 'upload_payment_details_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String billType;
  final String provider;
  final double amount;
  final String accountNumber;

  const PaymentMethodScreen({
    super.key,
    required this.billType,
    required this.provider,
    required this.amount,
    required this.accountNumber,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 2);
  String? _selectedMethod;
  bool _isProcessing = false;
  bool _showPriceBreakup = false;

  final List<Map<String, dynamic>> savedBanks = [
    {
      'id': 'bank_1',
      'name': 'HDFC Bank',
      'number': '********2193',
      'logo': 'visa',
    },
    {
      'id': 'bank_2',
      'name': 'HDFC Bank',
      'number': '********2193',
      'logo': 'visa',
    },
  ];

  final List<Map<String, dynamic>> mobileMoney = [
    {
      'id': 'airtel',
      'name': 'Airtel Mobile money',
      'color': Colors.red,
    },
    {
      'id': 'vodafone',
      'name': 'Vodafone pay',
      'color': Colors.red,
    },
  ];

  void _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      String paymentMethodName = '';
      if (_selectedMethod?.startsWith('bank_') == true) {
        paymentMethodName = savedBanks.firstWhere((b) => b['id'] == _selectedMethod)['name'];
      } else if (_selectedMethod == 'airtel' || _selectedMethod == 'vodafone') {
        paymentMethodName = mobileMoney.firstWhere((m) => m['id'] == _selectedMethod)['name'];
      } else if (_selectedMethod == 'add_bank') {
        paymentMethodName = 'New Bank Account';
      } else if (_selectedMethod == 'upload') {
        paymentMethodName = 'Bank Transfer (Upload)';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            billType: widget.billType,
            provider: widget.provider,
            amount: widget.amount,
            accountNumber: widget.accountNumber,
            paymentMethod: paymentMethodName,
            transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
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
          'Select Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Total Amount Section
            Container(
              padding: EdgeInsets.all(24),
              color: Colors.grey[50],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total amount',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        currencyFormat.format(widget.amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPriceBreakup = !_showPriceBreakup;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Show price breakup',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Icon(
                          _showPriceBreakup ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (_showPriceBreakup) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Bill Amount', widget.amount * 0.95),
                          SizedBox(height: 8),
                          _buildPriceRow('Convenience Fee', widget.amount * 0.05),
                          Divider(height: 24),
                          _buildPriceRow('Total', widget.amount, isBold: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Payment Methods List
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  // Pay through Bank Section
                  Text(
                    'Pay through Bank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Saved Banks
                  ...savedBanks.map((bank) => _buildBankOption(bank)),

                  // Add New Account
                  _buildAddNewAccountOption(),

                  SizedBox(height: 32),

                  // Mobile Money Section
                  Text(
                    'Mobile Money',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Mobile Money Options
                  ...mobileMoney.map((mobile) => _buildMobileMoneyOption(mobile)),

                  SizedBox(height: 32),

                  // Pay through Bank - Upload
                  Text(
                    'Pay through Bank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildUploadOption(),
                ],
              ),
            ),

            // Pay Button
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
                  onPressed: _isProcessing ? null : _processPayment,
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
                          'Pay ${currencyFormat.format(widget.amount)}',
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

  Widget _buildPriceRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBankOption(Map<String, dynamic> bank) {
    final isSelected = _selectedMethod == bank['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = bank['id'];
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VISA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    bank['number'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAccountOption() {
    final isSelected = _selectedMethod == 'add_bank';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddBankAccountScreen()),
        );
        if (result != null) {
          setState(() {
            _selectedMethod = 'add_bank';
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.success : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                color: AppColors.success,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add new account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Save and pay via your bank account',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyOption(Map<String, dynamic> mobile) {
    final isSelected = _selectedMethod == mobile['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = mobile['id'];
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (mobile['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                color: mobile['color'],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                mobile['name'],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadPaymentDetailsScreen(
              billType: widget.billType,
              provider: widget.provider,
              amount: widget.amount,
              accountNumber: widget.accountNumber,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.upload_file,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Upload details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}