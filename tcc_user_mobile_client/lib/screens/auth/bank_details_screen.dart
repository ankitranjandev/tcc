import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class BankDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const BankDetailsScreen({super.key, this.extraData});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _branchAddressController = TextEditingController();

  String _selectedCodeType = 'IFSC code';
  final List<String> _codeTypes = ['IFSC code', 'Routing number', 'Swift code'];

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderController.dispose();
    _branchAddressController.dispose();
    super.dispose();
  }

  void _handleSkip() {
    context.go('/dashboard');
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank details saved successfully (Mock)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to dashboard
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bank details',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                  ),
                ),
                SizedBox(height: 32),
                // Bank Name
                TextFormField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    hintText: 'Bank Name',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bank name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Account Number
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Account number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                // Code Type Selector
                Row(
                  children: _codeTypes.map((type) {
                    final isSelected = _selectedCodeType == type;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: type != _codeTypes.last ? 8 : 0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCodeType = type;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.white : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                // IFSC Code / Routing / Swift Code
                TextFormField(
                  controller: _ifscCodeController,
                  decoration: InputDecoration(
                    hintText: _selectedCodeType,
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $_selectedCodeType';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Account Holder Name
                TextFormField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    hintText: 'Account holder name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account holder name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Branch Address
                TextFormField(
                  controller: _branchAddressController,
                  decoration: InputDecoration(
                    hintText: 'Branch address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter branch address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue',
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
      ),
    );
  }
}
