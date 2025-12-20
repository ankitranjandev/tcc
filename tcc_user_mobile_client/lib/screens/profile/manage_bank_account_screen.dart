import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/bank_account_model.dart';
import '../../providers/bank_account_provider.dart';

class ManageBankAccountScreen extends StatefulWidget {
  final BankAccountModel? account; // null = add mode, non-null = edit mode

  const ManageBankAccountScreen({super.key, this.account});

  @override
  State<ManageBankAccountScreen> createState() => _ManageBankAccountScreenState();
}

class _ManageBankAccountScreenState extends State<ManageBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderController;
  late TextEditingController _branchAddressController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _swiftCodeController;
  late TextEditingController _routingNumberController;

  bool _isProcessing = false;
  String _accountType = 'domestic'; // 'domestic', 'international', 'us'
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    if (widget.account != null) {
      // Edit mode - populate with existing data
      _bankNameController = TextEditingController(text: widget.account!.bankName);
      _accountNumberController = TextEditingController(text: widget.account!.accountNumber);
      _accountHolderController = TextEditingController(text: widget.account!.accountHolderName);
      _branchAddressController = TextEditingController(text: widget.account!.branchAddress);
      _ifscCodeController = TextEditingController(text: widget.account!.ifscCode ?? '');
      _swiftCodeController = TextEditingController(text: widget.account!.swiftCode ?? '');
      _routingNumberController = TextEditingController(text: widget.account!.routingNumber ?? '');
      _isPrimary = widget.account!.isPrimary;

      // Determine account type from existing data
      if (widget.account!.swiftCode != null && widget.account!.swiftCode!.isNotEmpty) {
        _accountType = 'international';
      } else if (widget.account!.routingNumber != null && widget.account!.routingNumber!.isNotEmpty) {
        _accountType = 'us';
      } else {
        _accountType = 'domestic';
      }
    } else {
      // Add mode - empty controllers
      _bankNameController = TextEditingController();
      _accountNumberController = TextEditingController();
      _accountHolderController = TextEditingController();
      _branchAddressController = TextEditingController();
      _ifscCodeController = TextEditingController();
      _swiftCodeController = TextEditingController();
      _routingNumberController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _branchAddressController.dispose();
    _ifscCodeController.dispose();
    _swiftCodeController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    final provider = Provider.of<BankAccountProvider>(context, listen: false);

    // Build account model
    final account = BankAccountModel(
      id: widget.account?.id ?? '',
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolderName: _accountHolderController.text.trim(),
      branchAddress: _branchAddressController.text.trim(),
      ifscCode: _accountType == 'domestic' ? _ifscCodeController.text.trim() : null,
      swiftCode: _accountType == 'international' ? _swiftCodeController.text.trim() : null,
      routingNumber: _accountType == 'us' ? _routingNumberController.text.trim() : null,
      isPrimary: _isPrimary,
    );

    bool success;
    if (widget.account == null) {
      // Add mode
      success = await provider.createAccount(account);
    } else {
      // Edit mode
      success = await provider.updateAccount(widget.account!.id, account);
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Bank account added successfully'
                  : 'Bank account updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save bank account'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.account != null;

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
          isEditMode ? 'Edit Bank Account' : 'Add Bank Account',
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
                      // Info Card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your bank details are securely encrypted and stored',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Account Type Selector
                      Text(
                        'Account Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _accountType,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'domestic',
                              child: Text('Domestic (IFSC Code)'),
                            ),
                            DropdownMenuItem(
                              value: 'international',
                              child: Text('International (SWIFT Code)'),
                            ),
                            DropdownMenuItem(
                              value: 'us',
                              child: Text('US (Routing Number)'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _accountType = value!;
                              // Clear the code fields when switching types
                              _ifscCodeController.clear();
                              _swiftCodeController.clear();
                              _routingNumberController.clear();
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // Bank Name
                      _buildTextField(
                        label: 'Bank Name',
                        controller: _bankNameController,
                        hint: 'Enter bank name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter bank name';
                          }
                          if (value.trim().length < 2) {
                            return 'Bank name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Account Holder Name
                      _buildTextField(
                        label: 'Account Holder Name',
                        controller: _accountHolderController,
                        hint: 'Enter account holder name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account holder name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Account Number
                      _buildTextField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        hint: 'Enter account number',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account number';
                          }
                          if (value.trim().length < 8) {
                            return 'Account number must be at least 8 digits';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                            return 'Account number must contain only digits';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Branch Address
                      _buildTextField(
                        label: 'Branch Address',
                        controller: _branchAddressController,
                        hint: 'Enter branch address',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter branch address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Conditional Code Fields
                      if (_accountType == 'domestic') ...[
                        _buildTextField(
                          label: 'IFSC Code',
                          controller: _ifscCodeController,
                          hint: 'Enter 11-character IFSC code',
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter IFSC code';
                            }
                            if (value.trim().length != 11) {
                              return 'IFSC code must be exactly 11 characters';
                            }
                            if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.trim())) {
                              return 'IFSC code must contain only letters and numbers';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                      ],

                      if (_accountType == 'international') ...[
                        _buildTextField(
                          label: 'SWIFT Code',
                          controller: _swiftCodeController,
                          hint: 'Enter 8-11 character SWIFT code',
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter SWIFT code';
                            }
                            if (value.trim().length < 8 || value.trim().length > 11) {
                              return 'SWIFT code must be 8-11 characters';
                            }
                            if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.trim())) {
                              return 'SWIFT code must contain only letters and numbers';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                      ],

                      if (_accountType == 'us') ...[
                        _buildTextField(
                          label: 'Routing Number',
                          controller: _routingNumberController,
                          hint: 'Enter 9-digit routing number',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter routing number';
                            }
                            if (value.trim().length != 9) {
                              return 'Routing number must be exactly 9 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                              return 'Routing number must contain only digits';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                      ],

                      // Set as Primary Checkbox
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: CheckboxListTile(
                          value: _isPrimary,
                          onChanged: (value) {
                            setState(() {
                              _isPrimary = value ?? false;
                            });
                          },
                          title: Text(
                            'Set as primary account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Primary account is used by default for transactions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          activeColor: AppColors.primaryBlue,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Terms
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'By ${isEditMode ? 'updating' : 'adding'} this account, you agree to our Terms & Conditions and authorize TCC to debit this account for payments.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
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

            // Save Button
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
                  onPressed: _isProcessing ? null : _saveAccount,
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
                          isEditMode ? 'Update Account' : 'Save Account',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
