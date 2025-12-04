import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';

class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);

  String _giftType = 'Money';
  String _sendVia = 'TCC ID';
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

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
              // Gift Type Selection
              Text(
                'What would you like to gift?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _buildGiftTypeCard(
                    'Money',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  SizedBox(width: 12),
                  _buildGiftTypeCard(
                    'Airtime',
                    Icons.phone_android,
                    Colors.blue,
                  ),
                  SizedBox(width: 12),
                  _buildGiftTypeCard(
                    'Voucher',
                    Icons.card_giftcard,
                    Colors.purple,
                  ),
                ],
              ),

              SizedBox(height: 32),

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
                _giftType == 'Money' ? 'Gift Amount' :
                _giftType == 'Airtime' ? 'Airtime Amount' : 'Voucher Value',
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
                    _buildSummaryRow('Type', _giftType),
                    SizedBox(height: 8),
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
                  onPressed: _isLoading ? null : _sendGift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Row(
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

  Widget _buildGiftTypeCard(String type, IconData icon, Color color) {
    final isSelected = _giftType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _giftType = type;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Theme.of(context).iconTheme.color,
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : null,
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

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Gift Sent!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your $_giftType gift of Le ${_amountController.text} has been sent successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/dashboard');
              },
              child: Text('Done'),
            ),
          ],
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