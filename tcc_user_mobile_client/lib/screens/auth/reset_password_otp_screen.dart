import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive_text.dart';
import '../../widgets/responsive_builder.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to ${widget.email}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      // Navigate to reset password screen
      context.push('/forgot-password/reset', extra: {
        'email': widget.email,
        'otp': otp,
      });
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
        title: Text('Verify Code'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: isTabletOrDesktop ? 500 : double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: ResponsiveHelper.getResponsiveValue<double>(
                        context,
                        mobile: 100,
                        tablet: 120,
                        desktop: 140,
                      ),
                      height: ResponsiveHelper.getResponsiveValue<double>(
                        context,
                        mobile: 100,
                        tablet: 120,
                        desktop: 140,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        size: ResponsiveHelper.getResponsiveValue<double>(
                          context,
                          mobile: 50,
                          tablet: 60,
                          desktop: 70,
                        ),
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4)),

                  // Title
                  ResponsiveText.headline(
                    'Verify Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2)),

                  // Description
                  ResponsiveText.body(
                    'We\'ve sent a 6-digit verification code to\n${widget.email}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4)),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: ResponsiveHelper.getResponsiveValue<double>(
                          context,
                          mobile: 45,
                          tablet: 55,
                          desktop: 65,
                        ),
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveValue<double>(
                              context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }

                            // Auto-verify when all digits are entered
                            if (index == 5 && value.isNotEmpty) {
                              _handleVerifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4)),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
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
                            'Verify Code',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),

                  // Resend Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ResponsiveText.body(
                        'Didn\'t receive code? ',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      if (_resendTimer > 0)
                        ResponsiveText.body(
                          'Resend in ${_resendTimer}s',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isLoading ? null : _handleResendCode,
                          child: ResponsiveText.body(
                            'Resend Code',
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
    );
  }
}
