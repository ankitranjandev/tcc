import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import 'bill_review_screen.dart';

class BillDetailsScreen extends StatefulWidget {
  final String billType;
  final String provider;

  const BillDetailsScreen({
    super.key,
    required this.billType,
    required this.provider,
  });

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _autoPayEnabled = false;
  bool _isLoading = false;
  String? _accountError;

  Map<String, String> get inputLabels {
    switch (widget.billType) {
      case 'Electricity':
        return {
          'account': 'Meter Number',
          'placeholder': 'Enter your meter number',
          'example': 'e.g., MTR-123456',
        };
      case 'Mobile':
        return {
          'account': 'Mobile Number',
          'placeholder': 'Enter mobile number',
          'example': 'e.g., 076123456',
        };
      case 'Water':
        return {
          'account': 'Account Number',
          'placeholder': 'Enter your account number',
          'example': 'e.g., WAT-789012',
        };
      case 'DTH':
        return {
          'account': 'Smart Card Number',
          'placeholder': 'Enter your smart card number',
          'example': 'e.g., 4012345678',
        };
      default:
        return {
          'account': 'Account Number',
          'placeholder': 'Enter account number',
          'example': '',
        };
    }
  }

  void _fetchBillDetails() async {
    if (_accountController.text.isEmpty) {
      setState(() {
        _accountError = 'Please enter ${inputLabels['account']}';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _accountError = null;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillReviewScreen(
            billType: widget.billType,
            provider: widget.provider,
            accountNumber: _accountController.text,
            customerName: 'John Doe',
            billAmount: 245000.00,
            dueDate: DateTime.now().add(Duration(days: 7)),
            autoPay: _autoPayEnabled,
            mobile: _mobileController.text,
            email: _emailController.text,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = inputLabels;

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
          'Enter Details',
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
              // Provider Info Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getIconForBillType(),
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.provider,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.billType,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Account Number Input
              Text(
                labels['account']!,
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
                  border: Border.all(
                    color: _accountError != null
                        ? Colors.red
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: TextField(
                  controller: _accountController,
                  keyboardType: widget.billType == 'Mobile'
                      ? TextInputType.phone
                      : TextInputType.text,
                  inputFormatters: widget.billType == 'Mobile'
                      ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
                      : null,
                  decoration: InputDecoration(
                    hintText: labels['placeholder'],
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) {
                    if (_accountError != null) {
                      setState(() {
                        _accountError = null;
                      });
                    }
                  },
                ),
              ),
              if (_accountError != null) ...[
                SizedBox(height: 4),
                Text(
                  _accountError!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
              if (labels['example']!.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  labels['example']!,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],

              SizedBox(height: 20),

              // Mobile Number (for notifications)
              if (widget.billType != 'Mobile') ...[
                Text(
                  'Mobile Number (for notifications)',
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
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter mobile number',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Email (optional)
              Text(
                'Email (optional)',
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Auto-pay Option
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_repeat,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Enable Auto-pay',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Automatically pay bills on due date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoPayEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoPayEnabled = value;
                        });
                      },
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Fetch Bill Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchBillDetails,
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
                      : Text(
                          'Fetch Bill',
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
      ),
    );
  }

  IconData _getIconForBillType() {
    switch (widget.billType) {
      case 'Electricity':
        return Icons.flash_on;
      case 'Mobile':
        return Icons.phone_android;
      case 'Water':
        return Icons.water_drop;
      case 'DTH':
        return Icons.satellite_alt;
      default:
        return Icons.receipt;
    }
  }
}