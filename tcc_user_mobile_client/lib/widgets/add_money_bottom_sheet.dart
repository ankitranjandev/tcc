import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/wallet_service.dart';
import '../services/stripe_service.dart';

/// Shared Add Money Bottom Sheet widget with Stripe integration.
/// Can be shown from any screen using [showAddMoneyBottomSheet].
class AddMoneyBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddMoneyBottomSheet({super.key, this.onSuccess});

  @override
  AddMoneyBottomSheetState createState() => AddMoneyBottomSheetState();
}

class AddMoneyBottomSheetState extends State<AddMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final StripeService _stripeService = StripeService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _paymentIntentId;

  final List<int> _quickAmounts = [1, 5, 10, 25];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    debugPrint('Quick amount selected: \$$amount');
    setState(() {
      _amountController.text = amount.toString();
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    debugPrint('=== Add Money: _processPayment started ===');

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final amountText = _amountController.text.trim();
    debugPrint('Amount entered: "$amountText"');

    if (amountText.isEmpty) {
      debugPrint('Validation failed: empty amount');
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      debugPrint('Validation failed: invalid amount ($amountText)');
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount < 1) {
      debugPrint('Validation failed: amount below minimum (\$$amount < \$1)');
      setState(() => _errorMessage = 'Minimum amount is \$1 USD');
      return;
    }

    debugPrint('Validation passed. Amount: \$$amount');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create payment intent
      debugPrint('Step 1: Creating payment intent for \$$amount...');
      final result = await _walletService.createPaymentIntent(amount: amount);
      debugPrint('Payment intent result: success=${result['success']}');

      if (!result['success']) {
        debugPrint('Payment intent creation failed: ${result['error']}');
        throw Exception(result['error'] ?? 'Failed to create payment intent');
      }

      final data = result['data']['data'];
      final clientSecret = data['client_secret'];
      debugPrint('Payment intent created. Client secret received (length: ${clientSecret?.toString().length})');

      // Extract payment intent ID
      _paymentIntentId = _stripeService.extractPaymentIntentId(clientSecret);
      debugPrint('Extracted payment intent ID: $_paymentIntentId');

      setState(() => _isLoading = false);

      // Step 2: Process Stripe payment
      if (!mounted) return;
      debugPrint('Step 2: Presenting Stripe payment sheet...');
      final paymentSuccessful = await _stripeService.processPayment(
        clientSecret: clientSecret,
        merchantName: 'TCC Wallet Top-up',
        context: context,
      );
      debugPrint('Stripe payment sheet result: successful=$paymentSuccessful');

      if (!paymentSuccessful) {
        // User cancelled payment
        debugPrint('User cancelled payment');
        if (mounted) {
          setState(() {
            _errorMessage = 'Payment cancelled';
          });
        }
        return;
      }

      // Step 3: Verify payment with backend
      debugPrint('Step 3: Verifying payment with backend (paymentIntentId: $_paymentIntentId)...');
      if (mounted) {
        _stripeService.showVerificationDialog(context);
      }

      final verificationResult = await _stripeService.verifyPaymentWithPolling(
        paymentIntentId: _paymentIntentId!,
        maxAttempts: 5,
        delaySeconds: 2,
      );
      debugPrint('Verification result: $verificationResult');

      if (mounted) {
        // Close verification dialog
        Navigator.of(context).pop();

        if (verificationResult['verified'] == true) {
          // Payment verified successfully
          debugPrint('Payment verified successfully. Closing bottom sheet.');
          // Close the bottom sheet
          Navigator.pop(context);

          // Show success message
          final isTestMode = verificationResult['test_mode'] == true;
          debugPrint('Test mode: $isTestMode');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTestMode
                    ? 'Payment successful! (Test mode - backend verification skipped)'
                    : 'Payment successful! Your wallet has been credited.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Refresh parent screen balance
          if (widget.onSuccess != null) {
            debugPrint('Calling onSuccess callback to refresh balance');
            widget.onSuccess!();
          }
        } else if (verificationResult['timeout'] == true) {
          // Verification timeout - payment is processing
          debugPrint('Verification timed out. Payment is still processing.');
          // Close the bottom sheet
          Navigator.pop(context);

          // Show processing dialog
          _stripeService.showProcessingDialog(context, _paymentIntentId!);
        } else {
          // Verification failed
          debugPrint('Verification failed: ${verificationResult['error']}');
          setState(() {
            _errorMessage = verificationResult['error'] ?? 'Payment verification failed';
          });
        }
      }
    } on StripeException catch (e) {
      debugPrint('[AddMoney] StripeException caught:');
      debugPrint('[AddMoney]   code: ${e.error.code}');
      debugPrint('[AddMoney]   message: ${e.error.message}');
      debugPrint('[AddMoney]   localizedMessage: ${e.error.localizedMessage}');
      debugPrint('[AddMoney]   stripeErrorCode: ${e.error.stripeErrorCode}');
      debugPrint('[AddMoney]   declineCode: ${e.error.declineCode}');
      debugPrint('[AddMoney]   type: ${e.error.type}');
      setState(() {
        _isLoading = false;
        if (e.error.code == FailureCode.Canceled) {
          _errorMessage = 'Payment cancelled';
        } else {
          _errorMessage = e.error.message ?? 'Payment failed';
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[AddMoney] Unexpected error in _processPayment: $e');
      debugPrint('[AddMoney] Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
    debugPrint('=== Add Money: _processPayment ended ===');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Coin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Amount (USD)',
              hintText: 'Enter amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.surfaceContainerHighest),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              final isSelected = _amountController.text == amount.toString();
              return InkWell(
                onTap: () => _selectQuickAmount(amount),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24),

          // Pay button
          ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          SizedBox(height: 12),

          // Info text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the Add Money bottom sheet from any screen.
void showAddMoneyBottomSheet(BuildContext context, {VoidCallback? onSuccess}) {
  debugPrint('showAddMoneyBottomSheet called');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AddMoneyBottomSheet(onSuccess: onSuccess),
  );
}
