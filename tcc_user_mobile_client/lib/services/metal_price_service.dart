import '../models/metal_price_model.dart';
import 'api_service.dart';

class MetalPriceService {
  final ApiService _apiService = ApiService();

  /// Get live metal prices (Gold, Silver, Platinum)
  /// Returns formatted prices in the specified base currency
  Future<Map<String, dynamic>> getMetalPrices({
    String baseCurrency = 'SLL',
  }) async {
    try {
      final response = await _apiService.get(
        '/market/metal-prices?base=$baseCurrency',
        requiresAuth: false,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final metalPricesResponse = MetalPricesResponse.fromJson(data);

        return {
          'success': true,
          'data': metalPricesResponse,
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch metal prices',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get specific metal price
  /// [metal] - Metal symbol (XAU, XAG, XPT)
  /// [baseCurrency] - Base currency code (default: SLL)
  /// [unit] - Unit for price (gram, ounce, kilogram)
  Future<Map<String, dynamic>> getMetalPrice({
    required String metal,
    String baseCurrency = 'SLL',
    String unit = 'gram',
  }) async {
    try {
      final response = await _apiService.get(
        '/market/metal-price/$metal?base=$baseCurrency&unit=$unit',
        requiresAuth: false,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final metalPrice = MetalPrice(
          metal: data['metal'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          pricePerGram: unit == 'gram' ? (data['price'] ?? 0).toDouble() : 0,
          currency: data['currency'] ?? baseCurrency,
          timestamp: data['timestamp'] ?? 0,
        );

        return {
          'success': true,
          'data': metalPrice,
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch metal price',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Format metal prices for display on home screen
  /// Returns a list of formatted metal data ready for UI
  Future<List<Map<String, dynamic>>> getFormattedMetalPricesForDisplay({
    String baseCurrency = 'SLL',
  }) async {
    try {
      final result = await getMetalPrices(baseCurrency: baseCurrency);

      if (result['success'] != true) {
        return [];
      }

      final metalPricesResponse = result['data'] as MetalPricesResponse;
      final metals = metalPricesResponse.metals;

      return [
        {
          'name': 'Gold',
          'code': 'XAU',
          'price': metals.gold.pricePerGram,
          'pricePerOunce': metals.gold.price,
          'currency': baseCurrency,
        },
        {
          'name': 'Silver',
          'code': 'XAG',
          'price': metals.silver.pricePerGram,
          'pricePerOunce': metals.silver.price,
          'currency': baseCurrency,
        },
        {
          'name': 'Platinum',
          'code': 'XPT',
          'price': metals.platinum.pricePerGram,
          'pricePerOunce': metals.platinum.price,
          'currency': baseCurrency,
        },
      ];
    } catch (e) {
      return [];
    }
  }
}
