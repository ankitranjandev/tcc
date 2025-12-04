import 'api_service.dart';

class WalletService {
  final ApiService _apiService = ApiService();

  // Get Wallet Balance
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

  // Deposit Money
  Future<Map<String, dynamic>> deposit({
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? agentId,
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/deposit',
        body: {
          'amount': amount,
          'payment_method': paymentMethod,
          if (paymentDetails != null) 'payment_details': paymentDetails,
          if (agentId != null) 'agent_id': agentId,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request Withdrawal OTP
  Future<Map<String, dynamic>> requestWithdrawalOTP() async {
    try {
      final response = await _apiService.post(
        '/wallet/withdraw/request-otp',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Withdraw Money
  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String bankAccountId,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/withdraw',
        body: {
          'amount': amount,
          'bank_account_id': bankAccountId,
          'otp': otp,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request Transfer OTP
  Future<Map<String, dynamic>> requestTransferOTP() async {
    try {
      final response = await _apiService.post(
        '/wallet/transfer/request-otp',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Transfer Money
  Future<Map<String, dynamic>> transfer({
    required String recipientPhone,
    required String recipientCountryCode,
    required double amount,
    required String otp,
    String? note,
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/transfer',
        body: {
          'recipient_phone': recipientPhone,
          'recipient_country_code': recipientCountryCode,
          'amount': amount,
          'otp': otp,
          if (note != null) 'note': note,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
