import 'api_service.dart';

class WalletService {
  final ApiService _apiService = ApiService();

  // Get wallet balance
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _apiService.get(
        '/wallet/balance',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Deposit money to wallet
  Future<Map<String, dynamic>> deposit({
    required double amount,
    required String paymentMethod,
    String? agentId,
    String? referenceNumber,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'paymentMethod': paymentMethod,
      };
      if (agentId != null) body['agentId'] = agentId;
      if (referenceNumber != null) body['referenceNumber'] = referenceNumber;

      final response = await _apiService.post(
        '/wallet/deposit',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request OTP for withdrawal
  Future<Map<String, dynamic>> requestWithdrawalOTP({
    required double amount,
    required String withdrawalMethod,
    String? bankAccountId,
    String? agentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
      };
      if (bankAccountId != null) body['bank_account_id'] = bankAccountId;
      if (agentId != null) body['agent_id'] = agentId;

      final response = await _apiService.post(
        '/wallet/withdraw/request-otp',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Withdraw money from wallet
  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String withdrawalMethod,
    required String otp,
    String? bankAccountId,
    String? agentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
        'otp': otp,
      };
      if (bankAccountId != null) body['bank_account_id'] = bankAccountId;
      if (agentId != null) body['agent_id'] = agentId;

      final response = await _apiService.post(
        '/wallet/withdraw',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify if user exists by phone number
  Future<Map<String, dynamic>> verifyUserExists({
    required String phoneNumber,
    String countryCode = '+232', // Default to Sierra Leone
  }) async {
    try {
      final response = await _apiService.post(
        '/user/verify-phone',
        body: {
          'phone': phoneNumber,
          'country_code': countryCode,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify multiple phone numbers at once (batch verification)
  // Returns a map of phone numbers to their registration status
  Future<Map<String, dynamic>> verifyMultiplePhones({
    required List<String> phoneNumbers,
    String countryCode = '+232', // Default to Sierra Leone
  }) async {
    try {
      final response = await _apiService.post(
        '/user/verify-phones-batch',
        body: {
          'phones': phoneNumbers,
          'country_code': countryCode,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request OTP for transfer
  Future<Map<String, dynamic>> requestTransferOTP({
    required String recipientPhone,
    required double amount,
    String recipientCountryCode = '+232', // Default to Sierra Leone
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/transfer/request-otp',
        body: {
          'recipient_phone': recipientPhone,
          'recipient_country_code': recipientCountryCode,
          'amount': amount,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Transfer money to another user
  Future<Map<String, dynamic>> transfer({
    required String recipientPhone,
    required double amount,
    required String otp,
    String recipientCountryCode = '+232', // Default to Sierra Leone
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{
        'recipient_phone': recipientPhone,
        'recipient_country_code': recipientCountryCode,
        'amount': amount,
        'otp': otp,
      };
      if (note != null) body['note'] = note;

      final response = await _apiService.post(
        '/wallet/transfer',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create Stripe payment intent
  // Note: Stripe expects amount in cents, so we convert dollars to cents
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      final response = await _apiService.post(
        '/wallet/create-payment-intent',
        body: {'amount': amountInCents},
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify Stripe payment with backend
  Future<Map<String, dynamic>> verifyStripePayment({
    required String paymentIntentId,
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/verify-stripe-payment',
        body: {'payment_intent_id': paymentIntentId},
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
