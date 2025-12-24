import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/metal_price_model.dart';
import '../config/app_constants.dart';

class MetalPriceService {
  // Conversion constants
  static const double gramsPerTroyOunce = 31.1035;

  /// Get live metal prices (Gold, Silver, Platinum) from CurrencyBeacon
  /// Returns formatted prices in the specified base currency
  Future<Map<String, dynamic>> getMetalPrices({
    String baseCurrency = 'USD',
  }) async {
    try {
      // Fetch metal prices from CurrencyBeacon
      // Metals: XAU (Gold), XAG (Silver), XPT (Platinum)
      String url = '${AppConstants.currencyBeaconBaseUrl}/latest?api_key=${AppConstants.currencyBeaconApiKey}&base=$baseCurrency&symbols=XAU,XAG,XPT';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['response'] != null && data['response']['rates'] != null) {
          final rates = data['response']['rates'] as Map<String, dynamic>;

          // CurrencyBeacon returns rates as "1 USD = X troy oz"
          // We need to invert to get "price per troy oz in USD"
          final xauRate = (rates['XAU'] as num?)?.toDouble() ?? 0.0;
          final xagRate = (rates['XAG'] as num?)?.toDouble() ?? 0.0;
          final xptRate = (rates['XPT'] as num?)?.toDouble() ?? 0.0;

          // Calculate prices per troy ounce
          final goldPricePerOz = xauRate > 0 ? 1 / xauRate : 0.0;
          final silverPricePerOz = xagRate > 0 ? 1 / xagRate : 0.0;
          final platinumPricePerOz = xptRate > 0 ? 1 / xptRate : 0.0;

          // Calculate prices per gram (1 troy oz = 31.1035 grams)
          final goldPricePerGram = goldPricePerOz / gramsPerTroyOunce;
          final silverPricePerGram = silverPricePerOz / gramsPerTroyOunce;
          final platinumPricePerGram = platinumPricePerOz / gramsPerTroyOunce;

          final metalPricesResponse = MetalPricesResponse(
            base: baseCurrency.toUpperCase(),
            metals: MetalPrices(
              gold: MetalPriceDetail(
                price: goldPricePerOz,
                pricePerGram: goldPricePerGram,
              ),
              silver: MetalPriceDetail(
                price: silverPricePerOz,
                pricePerGram: silverPricePerGram,
              ),
              platinum: MetalPriceDetail(
                price: platinumPricePerOz,
                pricePerGram: platinumPricePerGram,
              ),
            ),
            timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          return {
            'success': true,
            'data': metalPricesResponse,
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to fetch metal prices from CurrencyBeacon',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Metal prices error: ${e.toString()}',
      };
    }
  }

  /// Get specific metal price from CurrencyBeacon
  /// [metal] - Metal symbol (XAU, XAG, XPT)
  /// [baseCurrency] - Base currency code (default: USD)
  /// [unit] - Unit for price (gram, ounce, kilogram)
  Future<Map<String, dynamic>> getMetalPrice({
    required String metal,
    String baseCurrency = 'USD',
    String unit = 'ounce',
  }) async {
    try {
      String url = '${AppConstants.currencyBeaconBaseUrl}/latest?api_key=${AppConstants.currencyBeaconApiKey}&base=$baseCurrency&symbols=${metal.toUpperCase()}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['response'] != null && data['response']['rates'] != null) {
          final rates = data['response']['rates'] as Map<String, dynamic>;
          final metalRate = (rates[metal.toUpperCase()] as num?)?.toDouble() ?? 0.0;

          // Calculate price per troy ounce
          final pricePerOz = metalRate > 0 ? 1 / metalRate : 0.0;
          final pricePerGram = pricePerOz / gramsPerTroyOunce;

          // Calculate price based on unit
          double price = pricePerOz;
          if (unit == 'gram') {
            price = pricePerGram;
          } else if (unit == 'kilogram') {
            price = pricePerGram * 1000;
          }

          final metalPrice = MetalPrice(
            metal: metal.toUpperCase(),
            price: price,
            pricePerGram: pricePerGram,
            currency: baseCurrency.toUpperCase(),
            timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          return {
            'success': true,
            'data': metalPrice,
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to fetch metal price from CurrencyBeacon',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Metal price error: ${e.toString()}',
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
