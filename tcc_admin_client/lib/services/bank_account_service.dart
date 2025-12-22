import '../models/api_response_model.dart';
import '../models/bank_account_model.dart';
import 'api_service.dart';

/// Bank Account Service
/// Handles bank account-related API calls for admin
class BankAccountService {
  final ApiService _apiService = ApiService();

  /// Get user's bank accounts (admin view)
  Future<ApiResponse<List<BankAccountModel>>> getUserBankAccounts(
      String userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/bank-accounts/admin/$userId',
    );

    // Transform the response
    if (response.success && response.data != null) {
      try {
        final responseData = response.data!;
        final accounts = (responseData['accounts'] as List<dynamic>)
            .map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: accounts,
          message: response.message,
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse bank accounts: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load bank accounts',
    );
  }
}
