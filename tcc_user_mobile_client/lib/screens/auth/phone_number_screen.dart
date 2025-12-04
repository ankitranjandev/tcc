import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class PhoneNumberScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const PhoneNumberScreen({super.key, this.registrationData});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+232';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+232', 'country': 'SLE'},
    {'code': '+1', 'country': 'USA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+234', 'country': 'NGA'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Combine registration data with phone number
      final fullRegistrationData = {
        'firstName': widget.registrationData?['firstName']?.toString() ?? '',
        'lastName': widget.registrationData?['lastName']?.toString() ?? '',
        'email': widget.registrationData?['email']?.toString() ?? '',
        'password': widget.registrationData?['password']?.toString() ?? '',
        'phone': _phoneController.text,
        'countryCode': _countryCode,
      };

      // Register the user
      final success = await authProvider.register(fullRegistrationData);

      if (success && mounted) {
        // Navigate to OTP verification
        context.go('/otp-verification', extra: {
          'phone': '$_countryCode ${_phoneController.text}',
          'registrationData': fullRegistrationData,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration
                Center(
                  child: SizedBox(
                    height: 200,
                    child: Icon(
                      Icons.phone_android,
                      size: 120,
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Mobile number',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The number should be same as the one provide in Bank',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
                SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Dropdown
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          filled: true,
                          fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _countryCodes.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['code'],
                            child: Text(
                              '${item['country']} ${item['code']}',
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _countryCode = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    // Phone Number Input
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Mobile Number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 6) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 48),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleSendOTP,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
