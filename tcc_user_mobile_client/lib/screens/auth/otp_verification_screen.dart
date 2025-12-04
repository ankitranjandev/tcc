import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const OTPVerificationScreen({super.key, this.extraData});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  String _currentOTP = '';
  int _resendTimer = 22;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_currentOTP.length == 6) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyOTP(_currentOTP);

      if (success && mounted) {
        // Navigate to KYC verification screen
        context.go('/kyc-verification', extra: widget.extraData);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleResendOTP() {
    if (_resendTimer == 0) {
      setState(() {
        _resendTimer = 22;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = widget.extraData?['phone'] ?? '+232 88769 783';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration
              Center(
                child: SizedBox(
                  height: 200,
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 120,
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                ),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                  children: [
                    TextSpan(text: 'Please enter the 6- digit code that has\nbeen sent to '),
                    TextSpan(
                      text: phoneNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Change phone number',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  selectedFillColor: AppColors.white,
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: Theme.of(context).dividerColor,
                  selectedColor: AppColors.primaryBlue,
                ),
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() {
                    _currentOTP = value;
                  });
                },
                onCompleted: (value) {
                  _handleVerify();
                },
              ),
              SizedBox(height: 24),
              Column(
                children: [
                  Text(
                    'Resend OTP in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        '00:${_resendTimer.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _resendTimer == 0 ? AppColors.primaryBlue : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (_resendTimer == 0) ...[
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _handleResendOTP,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return ElevatedButton(
                    onPressed: auth.isLoading || _currentOTP.length < 6
                        ? null
                        : _handleVerify,
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
                            'Verify',
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
    );
  }
}
