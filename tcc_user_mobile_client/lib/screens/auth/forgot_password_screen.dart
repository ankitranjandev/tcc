import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive_text.dart';
import '../../widgets/responsive_builder.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Navigate to OTP verification screen
        context.push('/forgot-password/verify-otp', extra: {
          'email': _emailController.text,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isTabletOrDesktop = screenWidth > ResponsiveHelper.mobileBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: isTabletOrDesktop ? 500 : double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration
                    Center(
                      child: Container(
                        width: ResponsiveHelper.getResponsiveValue<double>(
                          context,
                          mobile: 120,
                          tablet: 140,
                          desktop: 160,
                        ),
                        height: ResponsiveHelper.getResponsiveValue<double>(
                          context,
                          mobile: 120,
                          tablet: 140,
                          desktop: 160,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: ResponsiveHelper.getResponsiveValue<double>(
                            context,
                            mobile: 60,
                            tablet: 70,
                            desktop: 80,
                          ),
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4)),

                    // Title
                    ResponsiveText.headline(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2)),

                    // Description
                    ResponsiveText.body(
                      'Enter your email address and we\'ll send you a verification code to reset your password.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4)),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : ResponsiveText.body(
                              'Send Code',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2)),

                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ResponsiveText.body(
                          'Remember your password? ',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: ResponsiveText.body(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
