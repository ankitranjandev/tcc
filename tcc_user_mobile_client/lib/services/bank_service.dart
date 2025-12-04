import 'api_service.dart';

class BankService {
  final ApiService _apiService = ApiService();

  // Add bank account
  Future<Map<String, dynamic>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? branchName,
    String? ifscCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
      };
      if (branchName != null) body['branchName'] = branchName;
      if (ifscCode != null) body['ifscCode'] = ifscCode;

      final response = await _apiService.post(
        '/users/bank-accounts',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user's bank accounts
  Future<Map<String, dynamic>> getBankAccounts() async {
    try {
      final response = await _apiService.get(
        '/users/bank-accounts',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete bank account
  Future<Map<String, dynamic>> deleteBankAccount({
    required String bankAccountId,
  }) async {
    try {
      final response = await _apiService.delete(
        '/users/bank-accounts/$bankAccountId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Set primary bank account
  Future<Map<String, dynamic>> setPrimaryBankAccount({
    required String bankAccountId,
  }) async {
    try {
      final response = await _apiService.patch(
        '/users/bank-accounts/$bankAccountId/set-primary',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
