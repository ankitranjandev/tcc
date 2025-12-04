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
        'withdrawalMethod': withdrawalMethod,
      };
      if (bankAccountId != null) body['bankAccountId'] = bankAccountId;
      if (agentId != null) body['agentId'] = agentId;

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
        'withdrawalMethod': withdrawalMethod,
        'otp': otp,
      };
      if (bankAccountId != null) body['bankAccountId'] = bankAccountId;
      if (agentId != null) body['agentId'] = agentId;

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

  // Request OTP for transfer
  Future<Map<String, dynamic>> requestTransferOTP({
    required String recipientPhoneNumber,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post(
        '/wallet/transfer/request-otp',
        body: {
          'recipientPhoneNumber': recipientPhoneNumber,
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
    required String recipientPhoneNumber,
    required double amount,
    required String otp,
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{
        'recipientPhoneNumber': recipientPhoneNumber,
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
}
