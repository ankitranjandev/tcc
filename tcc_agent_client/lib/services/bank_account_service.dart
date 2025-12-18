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
}
