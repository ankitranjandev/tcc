import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';

class KycGuard extends StatelessWidget {
  final Widget child;
  final String? customMessage;

  const KycGuard({
    super.key,
    required this.child,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // If user is null or KYC is approved, show the child widget
    if (user == null || user.canMakeTransactions) {
      return child;
    }

    // Otherwise show KYC required screen
    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.isKycRejected
              ? 'KYC Verification Failed'
              : user.isKycPending
                  ? 'KYC Verification Pending'
                  : 'KYC Verification Required',
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (user.isKycRejected
                          ? AppColors.error
                          : user.isKycPending
                              ? AppColors.primaryBlue
                              : AppColors.warning)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isKycRejected
                      ? Icons.cancel_outlined
                      : user.isKycPending
                          ? Icons.pending_outlined
                          : Icons.verified_user_outlined,
                  size: 60,
                  color: user.isKycRejected
                      ? AppColors.error
                      : user.isKycPending
                          ? AppColors.primaryBlue
                          : AppColors.warning,
                ),
              ),
              SizedBox(height: 32),
              
              // Title
              Text(
                user.isKycRejected
                  ? 'KYC Verification Failed'
                  : user.isKycPending
                    ? 'KYC Verification Pending'
                    : 'KYC Verification Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Message
              Text(
                customMessage ?? _getDefaultMessage(user.kycStatus),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              // Action Button
              ElevatedButton(
                onPressed: () {
                  if (user.isKycRejected) {
                    // Navigate to KYC resubmission
                    context.push('/kyc-verification');
                  } else if (user.isKycPending) {
                    // Navigate to KYC status screen
                    context.push('/kyc-status');
                  } else {
                    // Navigate to KYC verification
                    context.push('/kyc-verification');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  user.isKycRejected
                    ? 'Resubmit Documents'
                    : user.isKycPending
                      ? 'View Status'
                      : 'Complete KYC',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              if (user.isKycPending) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Verification in progress...',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getDefaultMessage(String kycStatus) {
    switch (kycStatus.toUpperCase()) {
      case 'PENDING':
        return 'Your KYC verification is currently being processed. This usually takes 1-2 business days. You\'ll be notified once it\'s complete.';
      case 'REJECTED':
        return 'Your KYC documents were not approved. Please review the requirements and submit clear, valid documents.';
      default:
        return 'To access this feature, you need to complete your KYC verification. This helps us keep your account secure.';
    }
  }
}

// Mixin for screens that require KYC
mixin RequiresKyc<T extends StatefulWidget> on State<T> {
  bool get canProceed {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.canMakeTransactions ?? false;
  }

  void checkKycAndProceed(VoidCallback onProceed) {
    if (!canProceed) {
      _showKycRequiredDialog();
    } else {
      onProceed();
    }
  }

  void _showKycRequiredDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          user?.isKycRejected == true 
            ? 'KYC Verification Failed'
            : 'KYC Required'
        ),
        content: Text(
          user?.isKycRejected == true
            ? 'Your KYC documents were rejected. Please resubmit valid documents to continue.'
            : user?.isKycPending == true
              ? 'Your KYC verification is in progress. Please wait for approval to access this feature.'
              : 'Please complete your KYC verification to access this feature.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          if (user?.isKycRejected == true || 
              (user?.kycStatus.toUpperCase() != 'PENDING' && 
               user?.kycStatus.toUpperCase() != 'APPROVED'))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/kyc-verification');
              },
              child: Text(
                user?.isKycRejected == true 
                  ? 'Resubmit' 
                  : 'Complete KYC'
              ),
            ),
        ],
      ),
    );
  }
}