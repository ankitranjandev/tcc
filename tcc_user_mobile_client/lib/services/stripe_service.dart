import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../config/app_colors.dart';
import 'wallet_service.dart';

/// Centralized Stripe payment service for handling payment flows
/// across wallet deposits and bill payments
class StripeService {
  final WalletService _walletService = WalletService();

  /// Process Stripe payment by initializing and presenting the payment sheet
  ///
  /// Returns true if payment was successful, false if cancelled
  /// Throws exception if payment failed
  Future<bool> processPayment({
    required String clientSecret,
    required String merchantName,
    required BuildContext context,
  }) async {
    try {
      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: merchantName,
          paymentIntentClientSecret: clientSecret,
          returnURL: 'tccapp://stripe-redirect',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primaryBlue,
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      developer.log('✅ Stripe payment sheet completed successfully', name: 'StripeService');
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        developer.log('ℹ️ User cancelled Stripe payment', name: 'StripeService');
        return false;
      } else {
        developer.log('❌ Stripe payment failed: ${e.error.message}', name: 'StripeService');
        rethrow;
      }
    } catch (e) {
      developer.log('❌ Unexpected error in Stripe payment: $e', name: 'StripeService');
      rethrow;
    }
  }

  /// Verify Stripe payment with backend using polling mechanism
  ///
  /// Polls up to [maxAttempts] times with [delaySeconds] between attempts
  /// Returns verification result with transaction details and updated balance
  ///
  /// For local testing: Set skipVerification=true to bypass backend verification
  Future<Map<String, dynamic>> verifyPaymentWithPolling({
    required String paymentIntentId,
    int maxAttempts = 5,
    int delaySeconds = 2,
    bool skipVerification = false,
  }) async {
    // Skip verification for local testing (when backend is not ready)
    if (skipVerification || _isTestPayment(paymentIntentId)) {
      developer.log(
        '⚠️ BYPASSING verification for test payment $paymentIntentId',
        name: 'StripeService',
      );

      // Simulate verification success for test payments
      await Future.delayed(Duration(milliseconds: 500));

      return {
        'success': true,
        'verified': true,
        'test_mode': true,
        'message': 'Test payment verified (backend verification skipped)',
      };
    }

    developer.log(
      'Starting payment verification for $paymentIntentId (max $maxAttempts attempts)',
      name: 'StripeService',
    );

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        developer.log('Verification attempt $attempt/$maxAttempts', name: 'StripeService');

        final result = await _walletService.verifyStripePayment(
          paymentIntentId: paymentIntentId,
        );

        developer.log('Verification response: $result', name: 'StripeService');

        if (result['success'] == true) {
          // The response structure is: { success: true, data: { data: { verified, transaction, balance } } }
          final responseData = result['data'];
          final data = responseData is Map ? (responseData['data'] ?? responseData) : responseData;
          final verified = data['verified'] ?? false;

          if (verified) {
            developer.log('✅ Payment verified successfully', name: 'StripeService');
            return {
              'success': true,
              'verified': true,
              'transaction': data['transaction'],
              'balance': data['balance'],
            };
          }
        }

        // If not verified yet and we have more attempts, wait before retrying
        if (attempt < maxAttempts) {
          developer.log('Payment not verified yet, waiting ${delaySeconds}s...', name: 'StripeService');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        developer.log('❌ Verification attempt $attempt failed: $e', name: 'StripeService');

        // If this was the last attempt, return error
        if (attempt == maxAttempts) {
          return {
            'success': false,
            'verified': false,
            'error': 'Backend verification endpoint not available. Please implement /wallet/verify-stripe-payment',
          };
        }

        // Otherwise, wait before retrying
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // Timeout - payment not verified within max attempts
    developer.log(
      '⚠️ Payment verification timeout after $maxAttempts attempts',
      name: 'StripeService',
    );

    return {
      'success': false,
      'verified': false,
      'timeout': true,
      'error': 'Payment verification timeout. Your payment is processing and will be credited shortly.',
    };
  }

  /// Check if payment is a test payment (Stripe test mode)
  bool _isTestPayment(String paymentIntentId) {
    // Backend endpoints are now implemented!
    // ✅ POST /wallet/verify-stripe-payment
    // ✅ POST /bills/create-payment-intent
    // ✅ Stripe webhook handler

    // Production mode: Backend verification enabled
    // Production: Only skip for actual Stripe test payments
    return paymentIntentId.startsWith('pi_test_');
  }

  /// Show loading dialog during payment verification
  void showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Verifying payment...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show payment processing info dialog (when verification times out)
  void showProcessingDialog(BuildContext context, String paymentIntentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Payment Processing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your payment was successful and is being processed. Your wallet will be credited shortly.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Transaction ID:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            SelectableText(
              paymentIntentId,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            SizedBox(height: 16),
            Text(
              'If you have any questions, please contact support with the transaction ID above.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog for payment failures
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Extract payment intent ID from Stripe client secret
  /// Format: pi_xxxxx_secret_yyyyy -> pi_xxxxx
  String extractPaymentIntentId(String clientSecret) {
    final parts = clientSecret.split('_secret_');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return clientSecret;
  }
}
