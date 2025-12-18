import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../services/bank_account_service.dart';

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
  final _bankAccountService = BankAccountService();

  String _selectedCodeType = 'IFSC code';
  final List<String> _codeTypes = ['IFSC code', 'Routing number', 'Swift code'];
  bool _isSubmitting = false;

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
    // Navigate to KYC status screen instead of dashboard
    context.go('/kyc-status', extra: widget.extraData);
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Determine which code type to submit
      String? swiftCode;
      String? routingNumber;

      if (_selectedCodeType == 'Swift code') {
        swiftCode = _ifscCodeController.text;
      } else if (_selectedCodeType == 'Routing number') {
        routingNumber = _ifscCodeController.text;
      } else {
        // IFSC code - can be stored as routing number for now
        routingNumber = _ifscCodeController.text;
      }

      final result = await _bankAccountService.createBankAccount(
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolderName: _accountHolderController.text,
        branchAddress: _branchAddressController.text,
        swiftCode: swiftCode,
        routingNumber: routingNumber,
        isPrimary: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bank details saved successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to KYC status screen
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/kyc-status', extra: widget.extraData);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to save bank details'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
            onPressed: _isSubmitting ? null : _handleSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: _isSubmitting
                    ? Colors.grey.withValues(alpha: 0.5)
                    : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
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
                SizedBox(height: 8),
                Text(
                  'Optional - You can add this later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
                SizedBox(height: 32),
                // Bank Name
                TextFormField(
                  controller: _bankNameController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Bank Name',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bank name';
                    }
                    if (value.length < 2) {
                      return 'Bank name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Account Number
                TextFormField(
                  controller: _accountNumberController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Account number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account number';
                    }
                    if (value.length < 5) {
                      return 'Account number must be at least 5 characters';
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
                          onTap: _isSubmitting ? null : () {
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
                  enabled: !_isSubmitting,
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
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Account holder name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account holder name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Branch Address
                TextFormField(
                  controller: _branchAddressController,
                  enabled: !_isSubmitting,
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
                  onPressed: _isSubmitting ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save Bank Details',
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
