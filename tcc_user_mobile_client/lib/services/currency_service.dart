import '../models/currency_rate_model.dart';
import 'api_service.dart';

class CurrencyService {
  final ApiService _apiService = ApiService();

  /// Get live currency exchange rates
  /// Returns rates for common currencies relative to the base currency
  Future<Map<String, dynamic>> getCurrencyRates({
    String baseCurrency = 'TCC',
    List<String>? currencies,
  }) async {
    try {
      String endpoint = '/market/currency-rates?base=$baseCurrency';

      if (currencies != null && currencies.isNotEmpty) {
        endpoint += '&currencies=${currencies.join(',')}';
      }

      final response = await _apiService.get(
        endpoint,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final currencyRates = CurrencyRatesResponse.fromJson(data);

        return {
          'success': true,
          'data': currencyRates,
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch currency rates',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Convert amount from one currency to another
  /// Returns the conversion result with rate and converted amount
  Future<Map<String, dynamic>> convertCurrency({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final response = await _apiService.get(
        '/market/convert?from=$from&to=$to&amount=$amount',
        requiresAuth: false,
      );

      if (response['success'] == true) {
        final data = response['data']['conversion'];
        final conversion = CurrencyConversion.fromJson(data);

        return {
          'success': true,
          'data': conversion,
        };
      }

      return {
        'success': false,
        'error': 'Failed to convert currency',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get multiple currency conversions at once
  /// Useful for displaying a conversion table
  Future<Map<String, dynamic>> convertMultiple({
    required String from,
    required List<String> to,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post(
        '/market/convert-multiple',
        body: {
          'from': from,
          'to': to,
          'amount': amount,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data']['conversions'],
        };
      }

      return {
        'success': false,
        'error': 'Failed to convert currencies',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get exchange rate between two currencies
  /// Returns just the rate value for quick calculations
  Future<double?> getExchangeRate({
    required String from,
    required String to,
  }) async {
    try {
      final result = await convertCurrency(
        from: from,
        to: to,
        amount: 1.0,
      );

      if (result['success'] == true) {
        final conversion = result['data'] as CurrencyConversion;
        return conversion.rate;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get formatted currency rates for display
  /// Returns a map of currency codes to rates
  Future<Map<String, double>> getFormattedRates({
    String baseCurrency = 'TCC',
    List<String>? currencies,
  }) async {
    try {
      final result = await getCurrencyRates(
        baseCurrency: baseCurrency,
        currencies: currencies,
      );

      if (result['success'] != true) {
        return {};
      }

      final currencyRates = result['data'] as CurrencyRatesResponse;
      final formattedRates = <String, double>{};

      currencyRates.rates.forEach((code, rate) {
        formattedRates[code] = rate.rate;
      });

      return formattedRates;
    } catch (e) {
      return {};
    }
  }

  /// Get the inverse rate (how much base currency for 1 unit of target currency)
  /// Useful for displaying "1 USD = X TCC" format
  Future<double?> getInverseRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    try {
      final result = await getCurrencyRates(
        baseCurrency: baseCurrency,
        currencies: [targetCurrency],
      );

      if (result['success'] != true) {
        return null;
      }

      final currencyRates = result['data'] as CurrencyRatesResponse;
      final rate = currencyRates.getRate(targetCurrency);

      return rate?.inverseRate;
    } catch (e) {
      return null;
    }
  }
}
