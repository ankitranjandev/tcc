import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Session Expired Dialog
/// Shown when the user's session has expired (401/403 error)
class SessionExpiredDialog extends StatelessWidget {
  final String message;

  const SessionExpiredDialog({
    super.key,
    this.message = 'Your session has expired. Please login again to continue.',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Title
            Text(
              'Session Expired',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space32),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Close dialog
                  Navigator.of(context).pop();

                  // Logout and clear session
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.logout();

                  // Navigate to login
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space24,
                    vertical: AppTheme.space16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the session expired dialog
  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (context) => SessionExpiredDialog(
        message: message ?? 'Your session has expired. Please login again to continue.',
      ),
    );
  }
}
