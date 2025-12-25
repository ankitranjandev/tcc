import 'api_service.dart';
import '../models/currency_investment_model.dart';

class CurrencyInvestmentService {
  final ApiService _apiService = ApiService();

  /// Get available currencies with live rates and investment limits
  Future<Map<String, dynamic>> getAvailableCurrencies() async {
    try {
      final response = await _apiService.get(
        '/currency-investments/available',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get available currencies parsed as CurrencyInfo list
  Future<List<CurrencyInfo>> getAvailableCurrenciesTyped() async {
    try {
      final response = await getAvailableCurrencies();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final currencies = data['currencies'] as List<dynamic>?;
        if (currencies != null) {
          return currencies
              .map((c) => CurrencyInfo.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get investment limits for all currencies
  Future<Map<String, dynamic>> getLimits() async {
    try {
      final response = await _apiService.get(
        '/currency-investments/limits',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Buy currency with TCC
  Future<Map<String, dynamic>> buyCurrency({
    required String currencyCode,
    required double tccAmount,
  }) async {
    try {
      final response = await _apiService.post(
        '/currency-investments/buy',
        body: {
          'currency_code': currencyCode,
          'tcc_amount': tccAmount,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user's currency holdings with current values
  Future<Map<String, dynamic>> getHoldings() async {
    try {
      final response = await _apiService.get(
        '/currency-investments/holdings',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get holdings parsed as CurrencyHoldingsResponse
  Future<CurrencyHoldingsResponse?> getHoldingsTyped() async {
    try {
      final response = await getHoldings();
      if (response['success'] == true && response['data'] != null) {
        return CurrencyHoldingsResponse.fromJson(
            response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get single holding details
  Future<Map<String, dynamic>> getHoldingDetails({
    required String investmentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/currency-investments/holdings/$investmentId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get holding details parsed as CurrencyInvestment
  Future<CurrencyInvestment?> getHoldingDetailsTyped({
    required String investmentId,
  }) async {
    try {
      final response = await getHoldingDetails(investmentId: investmentId);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final holding = data['holding'] as Map<String, dynamic>?;
        if (holding != null) {
          return CurrencyInvestment.fromJson(holding);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sell currency holding back to TCC
  Future<Map<String, dynamic>> sellCurrency({
    required String investmentId,
  }) async {
    try {
      final response = await _apiService.post(
        '/currency-investments/sell/$investmentId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sell currency and get parsed result
  Future<SellCurrencyResult?> sellCurrencyTyped({
    required String investmentId,
  }) async {
    try {
      final response = await sellCurrency(investmentId: investmentId);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final sale = data['sale'] as Map<String, dynamic>?;
        if (sale != null) {
          return SellCurrencyResult.fromJson(sale);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get currency investment history
  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiService.get(
        '/currency-investments/history',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Calculate currency amount for given TCC investment
  double calculateCurrencyAmount(double tccAmount, double rate) {
    return tccAmount * rate;
  }

  /// Calculate TCC value from currency amount
  double calculateTccValue(double currencyAmount, double rate) {
    if (rate == 0) return 0;
    return currencyAmount / rate;
  }

  /// Calculate profit/loss
  double calculateProfitLoss(double amountInvested, double currentValueTcc) {
    return currentValueTcc - amountInvested;
  }

  /// Calculate profit/loss percentage
  double calculateProfitLossPercentage(
      double amountInvested, double currentValueTcc) {
    if (amountInvested == 0) return 0;
    return ((currentValueTcc - amountInvested) / amountInvested) * 100;
  }
}
