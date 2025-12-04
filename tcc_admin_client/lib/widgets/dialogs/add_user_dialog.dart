import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_management_service.dart';

/// Dialog for adding a new user
class AddUserDialog extends StatefulWidget {
  final Function(UserModel) onUserAdded;

  const AddUserDialog({
    super.key,
    required this.onUserAdded,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserManagementService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  KycStatus _kycStatus = KycStatus.pending;
  UserStatus _userStatus = UserStatus.active;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Enter a valid phone number';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    // Check for at least one digit
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      final response = await _userService.createUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        countryCode: '+232', // Default country code for Sierra Leone
        dateOfBirth: _selectedDateOfBirth,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        role: 'USER',
      );

      if (response.success && response.data != null) {
        widget.onUserAdded(response.data!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to create user';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppTheme.space16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Min 8 chars, 1 uppercase, 1 number, 1 special',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppTheme.space16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: '+232XXXXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: AppTheme.space16),

                // Date of Birth
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDateOfBirth = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: AppColors.gray50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDateOfBirth == null
                              ? 'Select date'
                              : '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}',
                          style: TextStyle(
                            color: _selectedDateOfBirth == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // KYC Status
                DropdownButtonFormField<KycStatus>(
                  initialValue: _kycStatus,
                  decoration: InputDecoration(
                    labelText: 'KYC Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  items: KycStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _kycStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                // User Status
                DropdownButtonFormField<UserStatus>(
                  initialValue: _userStatus,
                  decoration: InputDecoration(
                    labelText: 'Account Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  items: UserStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _userStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage.isNotEmpty) const SizedBox(height: AppTheme.space16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24,
                          vertical: AppTheme.space16,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24,
                          vertical: AppTheme.space16,
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Text('Add User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
