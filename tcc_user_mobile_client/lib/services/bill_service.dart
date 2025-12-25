import 'api_service.dart';

class BillService {
  final ApiService _apiService = ApiService();

  // Get bill providers by category
  Future<Map<String, dynamic>> getProviders({
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/bills/providers',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Fetch bill details from provider
  Future<Map<String, dynamic>> fetchBillDetails({
    required String providerId,
    required String accountNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '/bills/fetch-details',
        body: {
          'provider_id': providerId,
          'account_number': accountNumber,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request OTP for bill payment
  Future<Map<String, dynamic>> requestPaymentOTP({
    required String providerId,
    required String accountNumber,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post(
        '/bills/request-otp',
        body: {
          'provider_id': providerId,
          'account_number': accountNumber,
          'amount': amount,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Pay bill with OTP
  Future<Map<String, dynamic>> payBill({
    required String providerId,
    required String accountNumber,
    required double amount,
    required String otp,
    String? customerName,
  }) async {
    try {
      final body = <String, dynamic>{
        'provider_id': providerId,
        'account_number': accountNumber,
        'amount': amount,
        'otp': otp,
      };
      if (customerName != null) body['customer_name'] = customerName;

      final response = await _apiService.post(
        '/bills/pay',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get bill payment history
  Future<Map<String, dynamic>> getBillHistory({
    String? providerId,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (providerId != null) queryParams['providerId'] = providerId;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiService.get(
        '/bills/history',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create Stripe payment intent for bill payment
  // Note: Stripe expects amount in cents, so we convert dollars to cents
  Future<Map<String, dynamic>> createBillPaymentIntent({
    required String providerId,
    required String accountNumber,
    required double amount,
    String? customerName,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      final body = <String, dynamic>{
        'provider_id': providerId,
        'account_number': accountNumber,
        'amount': amountInCents,
      };
      if (customerName != null) body['customer_name'] = customerName;

      final response = await _apiService.post(
        '/bills/create-payment-intent',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Confirm bill payment with Stripe (optional - can use webhooks instead)
  Future<Map<String, dynamic>> confirmBillPayment({
    required String paymentIntentId,
    required String providerId,
    required String accountNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '/bills/confirm-stripe-payment',
        body: {
          'payment_intent_id': paymentIntentId,
          'provider_id': providerId,
          'account_number': accountNumber,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
