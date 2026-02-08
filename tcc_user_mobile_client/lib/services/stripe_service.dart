import 'package:flutter/foundation.dart';
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
      debugPrint('[StripeService] initPaymentSheet: returnURL=tccapp://stripe-redirect, urlScheme=${Stripe.urlScheme}');
      // Initialize Stripe payment sheet
      // Billing details (name + address) are required for Indian card regulations
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: merchantName,
          paymentIntentClientSecret: clientSecret,
          returnURL: 'tccapp://stripe-redirect',
          style: ThemeMode.light,
          billingDetailsCollectionConfiguration:
              BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            address: AddressCollectionMode.full,
          ),
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primaryBlue,
            ),
          ),
        ),
      );
      debugPrint('[StripeService] initPaymentSheet completed successfully');

      // Present payment sheet (handles 3DS authentication internally)
      debugPrint('[StripeService] presentPaymentSheet: presenting...');
      await Stripe.instance.presentPaymentSheet();
      debugPrint('[StripeService] presentPaymentSheet: returned successfully (payment confirmed + 3DS passed)');

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('[StripeService] Payment cancelled by user');
        return false;
      } else {
        debugPrint('[StripeService] StripeException: code=${e.error.code}, message=${e.error.message}, '
            'stripeErrorCode=${e.error.stripeErrorCode}, declineCode=${e.error.declineCode}');
        rethrow;
      }
    } catch (e) {
      debugPrint('[StripeService] Unexpected error in processPayment: $e');
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
      debugPrint('[StripeService] ⚠️ BYPASSING verification for test payment $paymentIntentId');

      // Simulate verification success for test payments
      await Future.delayed(Duration(milliseconds: 500));

      return {
        'success': true,
        'verified': true,
        'test_mode': true,
        'message': 'Test payment verified (backend verification skipped)',
      };
    }

    debugPrint('[StripeService] Starting payment verification for $paymentIntentId (max $maxAttempts attempts)');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('Verification attempt $attempt/$maxAttempts');

        final result = await _walletService.verifyStripePayment(
          paymentIntentId: paymentIntentId,
        );

        debugPrint('Verification response: $result');

        if (result['success'] == true) {
          // The response structure is: { success: true, data: { data: { verified, transaction, balance } } }
          final responseData = result['data'];
          final data = responseData is Map ? (responseData['data'] ?? responseData) : responseData;
          final verified = data['verified'] ?? false;

          if (verified) {
            debugPrint('✅ Payment verified successfully');
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
          debugPrint('Payment not verified yet, waiting ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        debugPrint('❌ Verification attempt $attempt failed: $e');

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
    debugPrint('[StripeService] ⚠️ Payment verification timeout after $maxAttempts attempts');

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
