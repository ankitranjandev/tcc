import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;
  final bool isFromRegistration;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber,
    this.isFromRegistration = true,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOTP() async {
    developer.log('🔐 [OTP_SCREEN] Verify OTP button pressed', name: 'TCC.OTPScreen');

    if (_otpController.text.length != AppConstants.otpLength) {
      developer.log('❌ [OTP_SCREEN] Invalid OTP length: ${_otpController.text.length}', name: 'TCC.OTPScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${AppConstants.otpLength}-digit OTP'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    developer.log('✅ [OTP_SCREEN] OTP length valid, proceeding with verification', name: 'TCC.OTPScreen');
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    developer.log(
      '📞 [OTP_SCREEN] Calling authProvider.verifyOtp():\n'
      '  Mobile: ${widget.mobileNumber}\n'
      '  isFromRegistration: ${widget.isFromRegistration}',
      name: 'TCC.OTPScreen',
    );

    final result = await authProvider.verifyOtp(
      mobileNumber: widget.mobileNumber,
      otp: _otpController.text,
    );

    developer.log('📦 [OTP_SCREEN] OTP verification result: ${result.success}', name: 'TCC.OTPScreen');

    if (!mounted) {
      developer.log('⚠️ [OTP_SCREEN] Widget not mounted, returning', name: 'TCC.OTPScreen');
      return;
    }

    setState(() => _isLoading = false);

    if (result.success) {
      developer.log('✅ [OTP_SCREEN] OTP verification successful', name: 'TCC.OTPScreen');
      if (widget.isFromRegistration) {
        developer.log('🧭 [OTP_SCREEN] Navigating to KYC verification (from registration)', name: 'TCC.OTPScreen');
        // Navigate to KYC verification
        context.go('/kyc-verification');
        developer.log('✅ [OTP_SCREEN] Navigation to KYC complete', name: 'TCC.OTPScreen');
      } else {
        developer.log('ℹ️ [OTP_SCREEN] OTP verified for password reset flow', name: 'TCC.OTPScreen');
        // OTP verified for password reset
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP verified successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // This case is handled in reset password flow
      }
    } else {
      developer.log('❌ [OTP_SCREEN] OTP verification failed: ${result.error}', name: 'TCC.OTPScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'OTP verification failed'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _handleResendOTP() async {
    developer.log('🔄 [OTP_SCREEN] Resend OTP button pressed', name: 'TCC.OTPScreen');

    if (!_canResend) {
      developer.log('⚠️ [OTP_SCREEN] Cannot resend yet, timer not expired', name: 'TCC.OTPScreen');
      return;
    }

    developer.log('✅ [OTP_SCREEN] Resend allowed, proceeding', name: 'TCC.OTPScreen');
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    developer.log('📞 [OTP_SCREEN] Calling authProvider.resendOtp() for ${widget.mobileNumber}', name: 'TCC.OTPScreen');

    final result = await authProvider.resendOtp(
      mobileNumber: widget.mobileNumber,
    );

    developer.log('📦 [OTP_SCREEN] Resend OTP result: ${result.success}', name: 'TCC.OTPScreen');

    if (!mounted) {
      developer.log('⚠️ [OTP_SCREEN] Widget not mounted, returning', name: 'TCC.OTPScreen');
      return;
    }

    setState(() => _isLoading = false);

    if (result.success) {
      developer.log('✅ [OTP_SCREEN] OTP resent successfully', name: 'TCC.OTPScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      _otpController.clear();
      _startResendTimer();
    } else {
      developer.log('❌ [OTP_SCREEN] Resend OTP failed: ${result.error}', name: 'TCC.OTPScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to resend OTP'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _getMaskedMobile() {
    if (widget.mobileNumber.length < 4) return widget.mobileNumber;
    final lastFour = widget.mobileNumber.substring(widget.mobileNumber.length - 4);
    return '*' * (widget.mobileNumber.length - 4) + lastFour;
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
                        Icons.message_outlined,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Header
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter the ${AppConstants.otpLength}-digit code sent to',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _getMaskedMobile(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // OTP Input
                    PinCodeTextField(
                      appContext: context,
                      length: AppConstants.otpLength,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 50,
                        activeFillColor: AppColors.white,
                        inactiveFillColor: AppColors.backgroundLight,
                        selectedFillColor: AppColors.white,
                        activeColor: AppColors.primaryOrange,
                        inactiveColor: AppColors.borderLight,
                        selectedColor: AppColors.primaryOrange,
                      ),
                      cursorColor: AppColors.primaryOrange,
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      onCompleted: (value) {
                        _handleVerifyOTP();
                      },
                      onChanged: (value) {},
                    ),

                    const SizedBox(height: 32),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: _isLoading ? null : _handleResendOTP,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Resend in $_resendTimer s',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOTP,
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
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

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
                              'The OTP is valid for 10 minutes. Please enter it before it expires.',
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
