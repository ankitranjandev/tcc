import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class WithdrawSuccessScreen extends StatelessWidget {
  const WithdrawSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.success,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Illustration
              Icon(
                Icons.check_circle_outline,
                size: 120,
                color: AppColors.white,
              ),

              SizedBox(height: 48),

              // Congratulations Text
              Text(
                'Congratulations',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // Message
              Text(
                'We will update the status in the next 24-48 hours. You can view the status in transaction history.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to dashboard
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
