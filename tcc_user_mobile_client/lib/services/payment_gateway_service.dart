import 'dart:math';

enum PaymentMethod {
  bankTransfer,
  debitCard,
  mobileMoney,
  ussd,
}

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
}

class PaymentResult {
  final PaymentStatus status;
  final String transactionId;
  final String message;
  final DateTime timestamp;

  PaymentResult({
    required this.status,
    required this.transactionId,
    required this.message,
    required this.timestamp,
  });
}

class PaymentGatewayService {
  static final PaymentGatewayService _instance = PaymentGatewayService._internal();
  factory PaymentGatewayService() => _instance;
  PaymentGatewayService._internal();

  // Simulate payment processing with random success/failure
  Future<PaymentResult> processPayment({
    required double amount,
    required PaymentMethod method,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Generate transaction ID
    final transactionId = _generateTransactionId();

    // Simulate 90% success rate
    final random = Random();
    final isSuccess = random.nextInt(100) < 90;

    if (isSuccess) {
      return PaymentResult(
        status: PaymentStatus.success,
        transactionId: transactionId,
        message: 'Payment successful! Your transaction has been completed.',
        timestamp: DateTime.now(),
      );
    } else {
      return PaymentResult(
        status: PaymentStatus.failed,
        transactionId: transactionId,
        message: 'Payment failed. Please try again or use a different payment method.',
        timestamp: DateTime.now(),
      );
    }
  }

  // Verify payment status (for checking pending payments)
  Future<PaymentResult> verifyPayment(String transactionId) async {
    await Future.delayed(Duration(seconds: 1));

    final random = Random();
    final isSuccess = random.nextInt(100) < 80;

    if (isSuccess) {
      return PaymentResult(
        status: PaymentStatus.success,
        transactionId: transactionId,
        message: 'Payment verified successfully.',
        timestamp: DateTime.now(),
      );
    } else {
      return PaymentResult(
        status: PaymentStatus.pending,
        transactionId: transactionId,
        message: 'Payment is still being processed.',
        timestamp: DateTime.now(),
      );
    }
  }

  // Get payment method name
  String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.debitCard:
        return 'Debit/Credit Card';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.ussd:
        return 'USSD';
    }
  }

  // Get payment method description
  String getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'Transfer from your bank account';
      case PaymentMethod.debitCard:
        return 'Pay with your card';
      case PaymentMethod.mobileMoney:
        return 'Pay with Airtel Money or Orange Money';
      case PaymentMethod.ussd:
        return 'Dial USSD code to complete payment';
    }
  }

  // Generate random transaction ID
  String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999);
    return 'TXN$timestamp${randomNum.toString().padLeft(4, '0')}';
  }

  // Simulate getting payment instructions for different methods
  Map<String, String> getPaymentInstructions(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return {
          'title': 'Bank Transfer Instructions',
          'instruction1': 'Account Name: TCC Investment Ltd',
          'instruction2': 'Account Number: 0123456789',
          'instruction3': 'Bank: Bank of Sierra Leone',
          'instruction4': 'Reference: Use your phone number',
        };
      case PaymentMethod.debitCard:
        return {
          'title': 'Card Payment',
          'instruction1': 'Enter your card details',
          'instruction2': 'Supported: Visa, Mastercard, Verve',
          'instruction3': 'Payment is secured with 3D Secure',
          'instruction4': 'Card details are not stored',
        };
      case PaymentMethod.mobileMoney:
        return {
          'title': 'Mobile Money Instructions',
          'instruction1': 'Airtel Money: Dial *151#',
          'instruction2': 'Orange Money: Dial *144#',
          'instruction3': 'Select Pay Bills > TCC Investment',
          'instruction4': 'Enter amount and confirm',
        };
      case PaymentMethod.ussd:
        return {
          'title': 'USSD Payment',
          'instruction1': 'Dial *456*1# on your phone',
          'instruction2': 'Select TCC Investment',
          'instruction3': 'Enter amount to pay',
          'instruction4': 'Enter PIN to confirm',
        };
    }
  }
}
