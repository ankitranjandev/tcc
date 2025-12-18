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
      // Clean phone number - remove any spaces or special characters
      final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      debugPrint('📱 PhoneNumberScreen: Preparing to send OTP');
      debugPrint('📱 PhoneNumberScreen: firstName: ${widget.registrationData?['firstName']}');
      debugPrint('📱 PhoneNumberScreen: lastName: ${widget.registrationData?['lastName']}');
      debugPrint('📱 PhoneNumberScreen: phone: $cleanedPhone');

      // Navigate directly to OTP verification screen
      // Registration will be completed after OTP verification
      debugPrint('📱 PhoneNumberScreen: Navigating to OTP screen');
      if (mounted) {
        context.go('/otp-verification', extra: {
          'phone': '$_countryCode $cleanedPhone',
          'countryCode': _countryCode,
          'registrationData': {
            'firstName': widget.registrationData?['firstName']?.toString() ?? '',
            'lastName': widget.registrationData?['lastName']?.toString() ?? '',
            'email': widget.registrationData?['email']?.toString() ?? '',
            'password': widget.registrationData?['password']?.toString() ?? '',
            'phone': cleanedPhone,
            'countryCode': _countryCode,
          },
        });
        debugPrint('📱 PhoneNumberScreen: Navigation to OTP screen complete');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/register'),
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
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                          filled: true,
                          fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        isExpanded: true,
                        items: _countryCodes.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['code'],
                            child: Text(
                              item['code']!,
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (BuildContext context) {
                          return _countryCodes.map((item) {
                            return Text(
                              item['code']!,
                              style: TextStyle(fontSize: 14),
                            );
                          }).toList();
                        },
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
                        maxLength: 10,
                        decoration: InputDecoration(
                          hintText: 'Mobile Number (10 digits)',
                          helperText: 'Enter 10-digit phone number',
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          // Remove any spaces or special characters
                          final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
                          if (cleanedValue.length != 10) {
                            return 'Phone number must be exactly 10 digits';
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
