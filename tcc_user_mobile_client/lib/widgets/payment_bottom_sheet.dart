import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../services/payment_gateway_service.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_text.dart';

class PaymentBottomSheet extends StatefulWidget {
  final double amount;
  final String title;
  final String? description;
  final Function(PaymentResult) onSuccess;
  final Function(PaymentResult)? onFailure;
  final Map<String, dynamic>? metadata;

  const PaymentBottomSheet({
    super.key,
    required this.amount,
    required this.title,
    this.description,
    required this.onSuccess,
    this.onFailure,
    this.metadata,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final PaymentGatewayService _paymentService = PaymentGatewayService();
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isTabletOrDesktop = screenWidth > ResponsiveHelper.mobileBreakpoint;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTabletOrDesktop ? 600 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ResponsiveText.headline(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

                  // Description
                  if (widget.description != null)
                    ResponsiveText.body(
                      widget.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),

                  SizedBox(height: 24),

                  // Amount display
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Amount to Pay',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            currencyFormat.format(widget.amount),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Payment method selection
                  Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Payment method options
                  _buildPaymentMethodCard(
                    PaymentMethod.bankTransfer,
                    Icons.account_balance,
                    AppColors.primaryBlue,
                  ),
                  SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    PaymentMethod.debitCard,
                    Icons.credit_card,
                    AppColors.secondaryYellow,
                  ),
                  SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    PaymentMethod.mobileMoney,
                    Icons.phone_android,
                    AppColors.secondaryGreen,
                  ),
                  SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    PaymentMethod.ussd,
                    Icons.dialpad,
                    AppColors.warning,
                  ),

                  SizedBox(height: 24),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMethod == null || _isProcessing
                          ? null
                          : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Pay ${currencyFormat.format(widget.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: _isProcessing
          ? null
          : () {
              setState(() {
                _selectedMethod = method;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentService.getPaymentMethodName(method),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _paymentService.getPaymentMethodDescription(method),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    // If Bank Transfer is selected, show bank selection first
    if (_selectedMethod == PaymentMethod.bankTransfer) {
      final selectedBank = await _showBankSelectionDialog();

      if (selectedBank == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }
    }

    // Show payment instructions dialog
    final shouldProceed = await _showPaymentInstructions();

    if (!shouldProceed) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Process payment
    final result = await _paymentService.processPayment(
      amount: widget.amount,
      method: _selectedMethod!,
      description: widget.description,
      metadata: widget.metadata,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    // Close the payment bottom sheet
    Navigator.pop(context);

    // Show result dialog
    await _showPaymentResultDialog(result);

    // Call callbacks
    if (result.status == PaymentStatus.success) {
      widget.onSuccess(result);
    } else {
      widget.onFailure?.call(result);
    }
  }

  Future<String?> _showBankSelectionDialog() async {
    final banks = [
      {'name': 'Ecobank', 'icon': Icons.account_balance},
      {'name': 'Standard Bank', 'icon': Icons.account_balance},
      {'name': 'First Bank of Nigeria', 'icon': Icons.account_balance},
      {'name': 'Zenith Bank', 'icon': Icons.account_balance},
      {'name': 'Access Bank', 'icon': Icons.account_balance},
      {'name': 'GTBank', 'icon': Icons.account_balance},
      {'name': 'United Bank for Africa', 'icon': Icons.account_balance},
      {'name': 'Stanbic Bank', 'icon': Icons.account_balance},
    ];

    String? selectedBank;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Your Bank',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: banks.length,
              itemBuilder: (context, index) {
                final bank = banks[index];
                final isSelected = selectedBank == bank['name'];

                return InkWell(
                  onTap: () {
                    setDialogState(() {
                      selectedBank = bank['name'] as String;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            bank['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bank['name'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBank != null
                  ? () => Navigator.pop(context, selectedBank)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  Future<bool> _showPaymentInstructions() async {
    if (_selectedMethod == null) return false;

    final instructions = _paymentService.getPaymentInstructions(_selectedMethod!);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Expanded(child: Text(instructions['title']!)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionItem(instructions['instruction1']!),
            SizedBox(height: 8),
            _buildInstructionItem(instructions['instruction2']!),
            SizedBox(height: 8),
            _buildInstructionItem(instructions['instruction3']!),
            SizedBox(height: 8),
            _buildInstructionItem(instructions['instruction4']!),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processing may take a few seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text('Proceed'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPaymentResultDialog(PaymentResult result) async {
    bool shouldNavigateToHome = false;

    await showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing with back button
      builder: (dialogContext) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, popResult) {
          // Handle back button press
          if (!didPop) return;
          if (result.status == PaymentStatus.success) {
            shouldNavigateToHome = true;
          }
        },
        child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: result.status == PaymentStatus.success
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.status == PaymentStatus.success
                    ? Icons.check_circle
                    : Icons.error,
                color: result.status == PaymentStatus.success
                    ? AppColors.success
                    : AppColors.error,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              result.status == PaymentStatus.success
                  ? 'Payment Successful!'
                  : 'Payment Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          result.transactionId,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(result.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (result.status == PaymentStatus.failed)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Could retry payment here
              },
              child: Text('Try Again'),
            ),
          ElevatedButton(
            onPressed: () {
              // Back to Home button pressed
              // Payment status: ${result.status}

              if (result.status == PaymentStatus.success) {
                shouldNavigateToHome = true;
              }

              // Close the dialog
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: result.status == PaymentStatus.success
                  ? AppColors.success
                  : AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(result.status == PaymentStatus.success
                ? 'Back to Home'
                : 'Done'),
          ),
        ],
      ),
      ),
    );

    // After dialog is closed, check if we should navigate to home
    if (shouldNavigateToHome && mounted) {
      // Dialog closed, navigating to dashboard...
      context.go('/dashboard');
    }
  }
}
