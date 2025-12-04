import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_management_service.dart';

/// Dialog for editing an existing user
class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserManagementService();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      final response = await _userService.updateUser(
        userId: widget.user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      );

      if (response.success && response.data != null) {
        widget.onUserUpdated(response.data!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to update user';
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
                      'Edit User',
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
                    fillColor: AppColors.bgTertiary,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'First name is required' : null,
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
                    fillColor: AppColors.bgTertiary,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Last name is required' : null,
                ),
                const SizedBox(height: AppTheme.space16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.bgTertiary,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppTheme.space16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.bgTertiary,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: AppTheme.space16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.bgTertiary,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.space24),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
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
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
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
                                color: Colors.white,
                              ),
                            )
                          : Text('Update User'),
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
