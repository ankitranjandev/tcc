import 'api_service.dart';

class BankAccountService {
  final ApiService _apiService = ApiService();

  // Create bank account
  Future<Map<String, dynamic>> createBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required String branchAddress,
    String? swiftCode,
    String? routingNumber,
    bool isPrimary = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
        'branch_address': branchAddress,
        'is_primary': isPrimary,
      };

      if (swiftCode != null && swiftCode.isNotEmpty) {
        body['swift_code'] = swiftCode;
      }
      if (routingNumber != null && routingNumber.isNotEmpty) {
        body['routing_number'] = routingNumber;
      }

      final response = await _apiService.post(
        '/bank-accounts',
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
        '/bank-accounts',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get specific bank account
  Future<Map<String, dynamic>> getBankAccountById(String accountId) async {
    try {
      final response = await _apiService.get(
        '/bank-accounts/$accountId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update bank account
  Future<Map<String, dynamic>> updateBankAccount({
    required String accountId,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    String? branchAddress,
    String? swiftCode,
    String? routingNumber,
    bool? isPrimary,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (bankName != null) body['bank_name'] = bankName;
      if (accountNumber != null) body['account_number'] = accountNumber;
      if (accountHolderName != null) body['account_holder_name'] = accountHolderName;
      if (branchAddress != null) body['branch_address'] = branchAddress;
      if (swiftCode != null) body['swift_code'] = swiftCode;
      if (routingNumber != null) body['routing_number'] = routingNumber;
      if (isPrimary != null) body['is_primary'] = isPrimary;

      final response = await _apiService.put(
        '/bank-accounts/$accountId',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete bank account
  Future<Map<String, dynamic>> deleteBankAccount(String accountId) async {
    try {
      final response = await _apiService.delete(
        '/bank-accounts/$accountId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Set primary bank account
  Future<Map<String, dynamic>> setPrimaryAccount(String accountId) async {
    try {
      final response = await _apiService.put(
        '/bank-accounts/$accountId/primary',
        body: {},
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
