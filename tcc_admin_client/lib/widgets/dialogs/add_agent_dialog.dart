import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/agent_model.dart';
import '../../services/agent_management_service.dart';

/// Dialog for adding a new agent
class AddAgentDialog extends StatefulWidget {
  final Function(AgentModel) onAgentAdded;

  const AddAgentDialog({
    super.key,
    required this.onAgentAdded,
  });

  @override
  State<AddAgentDialog> createState() => _AddAgentDialogState();
}

class _AddAgentDialogState extends State<AddAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _agentService = AgentManagementService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _commissionRateController = TextEditingController(text: '2.5');

  AgentStatus _agentStatus = AgentStatus.active;
  bool _isAvailable = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _commissionRateController.dispose();
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
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
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

  String? _validateCommissionRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Commission rate is required';
    }
    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Enter a valid number';
    }
    if (rate < 0 || rate > 100) {
      return 'Rate must be between 0 and 100';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      final response = await _agentService.createAgent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        countryCode: '+232', // Default country code for Sierra Leone
        businessName: _businessNameController.text.trim(),
        businessRegistrationNumber: _registrationNumberController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        commissionRate: double.parse(_commissionRateController.text),
      );

      if (response.success && response.data != null) {
        widget.onAgentAdded(response.data!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agent created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to create agent';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
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
                      'Add New Agent',
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

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                Row(
                  children: [
                    // First Name
                    Expanded(
                      child: TextFormField(
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
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),

                    // Last Name
                    Expanded(
                      child: TextFormField(
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
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),

                Row(
                  children: [
                    // Email
                    Expanded(
                      child: TextFormField(
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
                    ),
                    const SizedBox(width: AppTheme.space16),

                    // Phone
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone *',
                          hintText: '+232XXXXXXXXX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        validator: _validatePhone,
                      ),
                    ),
                  ],
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
                const SizedBox(height: AppTheme.space24),

                // Business Information Section
                Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Business Name
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Business name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                // Registration Number
                TextFormField(
                  controller: _registrationNumberController,
                  decoration: InputDecoration(
                    labelText: 'Business Registration Number *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Registration number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),

                Row(
                  children: [
                    // Location
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),

                    // Commission Rate
                    Expanded(
                      child: TextFormField(
                        controller: _commissionRateController,
                        decoration: InputDecoration(
                          labelText: 'Commission Rate (%) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: _validateCommissionRate,
                      ),
                    ),
                  ],
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
                const SizedBox(height: AppTheme.space24),

                // Status Section
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                Row(
                  children: [
                    // Agent Status
                    Expanded(
                      child: DropdownButtonFormField<AgentStatus>(
                        initialValue: _agentStatus,
                        decoration: InputDecoration(
                          labelText: 'Account Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.gray50,
                        ),
                        items: AgentStatus.values
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _agentStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),

                    // Availability
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppColors.gray300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available for Transactions',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                              activeThumbColor: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                        backgroundColor: Colors.orange,
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
                          : const Text('Add Agent'),
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
