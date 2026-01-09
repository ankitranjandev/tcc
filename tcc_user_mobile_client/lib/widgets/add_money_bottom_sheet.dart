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
    setState(() {
      _amountController.text = amount.toString();
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount < 1) {
      setState(() => _errorMessage = 'Minimum amount is \$1 USD');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create payment intent
      final result = await _walletService.createPaymentIntent(amount: amount);

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Failed to create payment intent');
      }

      final data = result['data']['data'];
      final clientSecret = data['client_secret'];

      // Extract payment intent ID
      _paymentIntentId = _stripeService.extractPaymentIntentId(clientSecret);

      setState(() => _isLoading = false);

      // Step 2: Process Stripe payment
      if (!mounted) return;
      final paymentSuccessful = await _stripeService.processPayment(
        clientSecret: clientSecret,
        merchantName: 'TCC Wallet Top-up',
        context: context,
      );

      if (!paymentSuccessful) {
        // User cancelled payment
        if (mounted) {
          setState(() {
            _errorMessage = 'Payment cancelled';
          });
        }
        return;
      }

      // Step 3: Verify payment with backend
      if (mounted) {
        _stripeService.showVerificationDialog(context);
      }

      final verificationResult = await _stripeService.verifyPaymentWithPolling(
        paymentIntentId: _paymentIntentId!,
        maxAttempts: 5,
        delaySeconds: 2,
      );

      if (mounted) {
        // Close verification dialog
        Navigator.of(context).pop();

        if (verificationResult['verified'] == true) {
          // Payment verified successfully
          // Close the bottom sheet
          Navigator.pop(context);

          // Show success message
          final isTestMode = verificationResult['test_mode'] == true;
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
            widget.onSuccess!();
          }
        } else if (verificationResult['timeout'] == true) {
          // Verification timeout - payment is processing
          // Close the bottom sheet
          Navigator.pop(context);

          // Show processing dialog
          _stripeService.showProcessingDialog(context, _paymentIntentId!);
        } else {
          // Verification failed
          setState(() {
            _errorMessage = verificationResult['error'] ?? 'Payment verification failed';
          });
        }
      }
    } on StripeException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.error.code == FailureCode.Canceled) {
          _errorMessage = 'Payment cancelled';
        } else {
          _errorMessage = e.error.message ?? 'Payment failed';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF2C3E50), width: 2),
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
                    color: isSelected ? Color(0xFF2C3E50) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(0xFF2C3E50) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
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
              backgroundColor: Color(0xFF2C3E50),
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
              Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AddMoneyBottomSheet(onSuccess: onSuccess),
  );
}
