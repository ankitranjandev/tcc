import 'api_service.dart';

class InvestmentService {
  final ApiService _apiService = ApiService();

  // Get investment categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _apiService.get(
        '/investments/categories',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create new investment
  Future<Map<String, dynamic>> createInvestment({
    required String categoryId,
    required double amount,
    required int tenureMonths,
  }) async {
    try {
      final response = await _apiService.post(
        '/investments',
        body: {
          'categoryId': categoryId,
          'amount': amount,
          'tenureMonths': tenureMonths,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user's investment portfolio
  Future<Map<String, dynamic>> getPortfolio({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiService.get(
        '/investments/portfolio',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get investment details by ID
  Future<Map<String, dynamic>> getInvestmentDetails({
    required String investmentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/investments/$investmentId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request tenure change for investment
  Future<Map<String, dynamic>> requestTenureChange({
    required String investmentId,
    required int newTenureMonths,
  }) async {
    try {
      final response = await _apiService.post(
        '/investments/$investmentId/request-tenure-change',
        body: {
          'newTenureMonths': newTenureMonths,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get withdrawal penalty for early withdrawal
  Future<Map<String, dynamic>> getWithdrawalPenalty({
    required String investmentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/investments/$investmentId/withdrawal-penalty',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Withdraw investment
  Future<Map<String, dynamic>> withdrawInvestment({
    required String investmentId,
    bool? acceptPenalty,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (acceptPenalty != null) body['acceptPenalty'] = acceptPenalty;

      final response = await _apiService.post(
        '/investments/$investmentId/withdraw',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Calculate expected returns
  Future<Map<String, dynamic>> calculateReturns({
    required String categoryId,
    required double amount,
    required int tenureMonths,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'categoryId': categoryId,
        'amount': amount.toString(),
        'tenureMonths': tenureMonths.toString(),
      };

      final response = await _apiService.get(
        '/investments/calculate-returns',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
