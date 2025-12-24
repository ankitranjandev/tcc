import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_rate_model.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class CurrencyService {
  final ApiService _apiService = ApiService();

  // Check if currency is TCC (custom currency not available in CurrencyBeacon)
  bool _isTccCurrency(String currency) {
    return currency.toUpperCase() == 'TCC';
  }

  // Determine if we should use backend API (when TCC is involved)
  bool _shouldUseBackendApi(String? from, String? to) {
    if (from != null && _isTccCurrency(from)) return true;
    if (to != null && _isTccCurrency(to)) return true;
    return false;
  }

  /// Get live currency exchange rates
  /// Returns rates for common currencies relative to the base currency
  Future<Map<String, dynamic>> getCurrencyRates({
    String baseCurrency = 'TCC',
    List<String>? currencies,
  }) async {
    try {
      // Use backend API if TCC is involved
      if (_shouldUseBackendApi(baseCurrency, null)) {
        return _getCurrencyRatesFromBackend(
          baseCurrency: baseCurrency,
          currencies: currencies,
        );
      }

      // Use CurrencyBeacon for standard currencies
      return _getCurrencyRatesFromCurrencyBeacon(
        baseCurrency: baseCurrency,
        currencies: currencies,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get currency rates from backend API (for TCC conversions)
  Future<Map<String, dynamic>> _getCurrencyRatesFromBackend({
    required String baseCurrency,
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

  /// Get currency rates from CurrencyBeacon API
  Future<Map<String, dynamic>> _getCurrencyRatesFromCurrencyBeacon({
    required String baseCurrency,
    List<String>? currencies,
  }) async {
    try {
      // Build URL with query parameters
      String url = '${AppConstants.currencyBeaconBaseUrl}/latest?api_key=${AppConstants.currencyBeaconApiKey}&base=${baseCurrency.toUpperCase()}';

      if (currencies != null && currencies.isNotEmpty) {
        url += '&symbols=${currencies.map((c) => c.toUpperCase()).join(',')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // CurrencyBeacon response format:
        // {
        //   "meta": { "code": 200, "disclaimer": "..." },
        //   "response": {
        //     "date": "2025-12-24",
        //     "base": "USD",
        //     "rates": { "EUR": 0.92, "GBP": 0.79, ... }
        //   }
        // }

        if (data['response'] != null && data['response']['rates'] != null) {
          final ratesData = data['response']['rates'] as Map<String, dynamic>;
          final ratesMap = <String, CurrencyRate>{};

          // Convert CurrencyBeacon format to our format
          ratesData.forEach((code, rate) {
            final rateValue = (rate is num) ? rate.toDouble() : 0.0;
            ratesMap[code] = CurrencyRate(
              code: code,
              rate: rateValue,
              inverseRate: rateValue > 0 ? 1.0 / rateValue : 0.0,
            );
          });

          final currencyRates = CurrencyRatesResponse(
            base: baseCurrency.toUpperCase(),
            rates: ratesMap,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );

          return {
            'success': true,
            'data': currencyRates,
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to fetch currency rates from CurrencyBeacon',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'CurrencyBeacon API error: ${e.toString()}',
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
      // Use backend API if TCC is involved
      if (_shouldUseBackendApi(from, to)) {
        return _convertCurrencyFromBackend(
          from: from,
          to: to,
          amount: amount,
        );
      }

      // Use CurrencyBeacon for standard currencies
      return _convertCurrencyFromCurrencyBeacon(
        from: from,
        to: to,
        amount: amount,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Convert currency using backend API (for TCC conversions)
  Future<Map<String, dynamic>> _convertCurrencyFromBackend({
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

  /// Convert currency using CurrencyBeacon API
  Future<Map<String, dynamic>> _convertCurrencyFromCurrencyBeacon({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      String url = '${AppConstants.currencyBeaconBaseUrl}/convert?api_key=${AppConstants.currencyBeaconApiKey}&from=${from.toUpperCase()}&to=${to.toUpperCase()}&amount=$amount';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // CurrencyBeacon convert response format:
        // {
        //   "meta": { "code": 200 },
        //   "response": {
        //     "date": "2025-12-24",
        //     "from": "USD",
        //     "to": "EUR",
        //     "amount": 100,
        //     "value": 92.5
        //   }
        // }

        if (data['response'] != null) {
          final responseData = data['response'];
          final rate = responseData['value'] / amount;

          final conversion = CurrencyConversion(
            from: from.toUpperCase(),
            to: to.toUpperCase(),
            amount: amount,
            convertedAmount: (responseData['value'] as num).toDouble(),
            rate: rate,
          );

          return {
            'success': true,
            'data': conversion,
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to convert currency from CurrencyBeacon',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'CurrencyBeacon conversion error: ${e.toString()}',
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
      // Check if any target currency is TCC
      final hasTcc = to.any((currency) => _isTccCurrency(currency));

      // Use backend API if TCC is involved
      if (_shouldUseBackendApi(from, null) || hasTcc) {
        return _convertMultipleFromBackend(
          from: from,
          to: to,
          amount: amount,
        );
      }

      // Use CurrencyBeacon for standard currencies
      return _convertMultipleFromCurrencyBeacon(
        from: from,
        to: to,
        amount: amount,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Convert multiple currencies using backend API
  Future<Map<String, dynamic>> _convertMultipleFromBackend({
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

  /// Convert multiple currencies using CurrencyBeacon API
  Future<Map<String, dynamic>> _convertMultipleFromCurrencyBeacon({
    required String from,
    required List<String> to,
    required double amount,
  }) async {
    try {
      // CurrencyBeacon doesn't have a direct multi-convert endpoint
      // We'll make individual conversion calls
      final conversions = <Map<String, dynamic>>[];

      for (final targetCurrency in to) {
        final result = await _convertCurrencyFromCurrencyBeacon(
          from: from,
          to: targetCurrency,
          amount: amount,
        );

        if (result['success'] == true) {
          conversions.add((result['data'] as CurrencyConversion).toJson());
        }
      }

      if (conversions.isNotEmpty) {
        return {
          'success': true,
          'data': conversions,
        };
      }

      return {
        'success': false,
        'error': 'Failed to convert currencies',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'CurrencyBeacon multiple conversion error: ${e.toString()}',
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
