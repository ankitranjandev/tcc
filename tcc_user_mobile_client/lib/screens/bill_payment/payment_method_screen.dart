import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import 'payment_success_screen.dart';

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
  final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);
  String? _selectedMethod;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'wallet',
      'name': 'TCC Wallet',
      'subtitle': 'Balance: Le 1,500,000',
      'icon': Icons.account_balance_wallet,
      'color': AppColors.primaryBlue,
      'available': true,
    },
    {
      'id': 'upi',
      'name': 'UPI',
      'subtitle': 'Pay using UPI ID',
      'icon': Icons.payments,
      'color': Colors.purple,
      'available': true,
    },
    {
      'id': 'debit',
      'name': 'Debit Card',
      'subtitle': 'Visa, Mastercard, Rupay',
      'icon': Icons.credit_card,
      'color': Colors.orange,
      'available': true,
    },
    {
      'id': 'credit',
      'name': 'Credit Card',
      'subtitle': 'All major cards accepted',
      'icon': Icons.credit_card,
      'color': Colors.green,
      'available': true,
    },
    {
      'id': 'netbanking',
      'name': 'Net Banking',
      'subtitle': 'All major banks',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'available': true,
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            billType: widget.billType,
            provider: widget.provider,
            amount: widget.amount,
            accountNumber: widget.accountNumber,
            paymentMethod: paymentMethods.firstWhere((m) => m['id'] == _selectedMethod)['name'],
            transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Amount Display
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.amount),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.provider} - ${widget.billType}',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  return _buildPaymentMethodCard(method);
                },
              ),
            ),

            // Pay Button
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
                  // Security Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Secured by 256-bit SSL encryption',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method['id'];
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (method['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method['icon'],
                color: method['color'],
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    method['subtitle'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: method['id'],
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}