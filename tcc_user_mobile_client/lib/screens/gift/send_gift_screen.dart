import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../bill_payment/payment_method_screen.dart';

class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);

  String _sendVia = 'TCC ID';
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Send Gift',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Send Via Selection
              Text(
                'Send via',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSendViaOption('TCC ID', Icons.badge),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: _buildSendViaOption('Mobile', Icons.phone),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Recipient Input
              Text(
                _sendVia == 'TCC ID' ? 'Recipient TCC ID' : 'Recipient Mobile Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _recipientController,
                  decoration: InputDecoration(
                    hintText: _sendVia == 'TCC ID'
                        ? 'e.g., john.doe@tcc'
                        : 'e.g., 076123456',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      _sendVia == 'TCC ID' ? Icons.person : Icons.phone,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Amount Section
              Text(
                'Gift Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixText: 'Le ',
                    prefixStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Quick Amount Selection
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountChip('50,000'),
                  _buildQuickAmountChip('100,000'),
                  _buildQuickAmountChip('200,000'),
                  _buildQuickAmountChip('500,000'),
                ],
              ),

              SizedBox(height: 24),

              // Personal Message
              Text(
                'Personal Message (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a personal message to your gift...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Summary Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                      AppColors.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gift Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildSummaryRow('Send via', _sendVia),
                    if (_amountController.text.isNotEmpty) ...[
                      SizedBox(height: 8),
                      _buildSummaryRow(
                        'Amount',
                        'Le ${_amountController.text}',
                        highlight: true,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sendGift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        'Send Gift',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendViaOption(String text, IconData icon) {
    final isSelected = _sendVia == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sendVia = text;
          _recipientController.clear();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryBlue : null,
            ),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String amount) {
    final isSelected = _amountController.text == amount.replaceAll(',', '');

    return GestureDetector(
      onTap: () {
        setState(() {
          _amountController.text = amount.replaceAll(',', '');
        });
      },
      child: Chip(
        label: Text(
          'Le $amount',
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primaryBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isSelected
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        side: BorderSide(
          color: AppColors.primaryBlue,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
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
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            color: highlight ? AppColors.primaryBlue : null,
          ),
        ),
      ],
    );
  }

  void _sendGift() async {
    // Validation
    if (_recipientController.text.isEmpty) {
      _showError('Please enter recipient details');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showError('Please enter gift amount');
      return;
    }

    // Parse the amount
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    // Navigate to payment method screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(
            billType: 'Gift',
            provider: _recipientController.text,
            amount: amount,
            accountNumber: _recipientController.text,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}