import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.forgotPassword(
      emailOrPhone: _emailOrPhoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // Navigate to reset password screen
      context.push('/reset-password', extra: {
        'email_or_phone': _emailOrPhoneController.text.trim(),
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to send OTP'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Header
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter your email or mobile number to receive a password reset code',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email/Phone Field
                    TextFormField(
                      controller: _emailOrPhoneController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSendOTP(),
                      decoration: InputDecoration(
                        labelText: 'Email or Mobile Number',
                        hintText: 'Enter your email or mobile',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryOrange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or mobile number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Send OTP Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Remember your password? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.infoBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.infoBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will receive a 6-digit code to reset your password',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
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
        ),
      ),
    );
  }
}
