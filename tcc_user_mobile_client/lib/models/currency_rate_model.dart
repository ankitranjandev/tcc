class CurrencyRate {
  final String code;
  final double rate;
  final double inverseRate;

  CurrencyRate({
    required this.code,
    required this.rate,
    required this.inverseRate,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      code: json['code'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      inverseRate: (json['inverseRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'rate': rate,
      'inverseRate': inverseRate,
    };
  }

  String get displayName {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'NGN':
        return 'Nigerian Naira';
      case 'GHS':
        return 'Ghanaian Cedi';
      case 'TCC':
        return 'TCC Coin';
      default:
        return code;
    }
  }

  String get symbol {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'NGN':
        return '₦';
      case 'GHS':
        return '₵';
      case 'TCC':
        return 'TCC';
      default:
        return code;
    }
  }
}

class CurrencyRatesResponse {
  final String base;
  final Map<String, CurrencyRate> rates;
  final int timestamp;

  CurrencyRatesResponse({
    required this.base,
    required this.rates,
    required this.timestamp,
  });

  factory CurrencyRatesResponse.fromJson(Map<String, dynamic> json) {
    final ratesMap = <String, CurrencyRate>{};
    final ratesData = json['rates'] as Map<String, dynamic>? ?? {};

    ratesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        ratesMap[key] = CurrencyRate.fromJson(value);
      }
    });

    return CurrencyRatesResponse(
      base: json['base'] ?? 'TCC',
      rates: ratesMap,
      timestamp: json['timestamp'] ?? 0,
    );
  }

  DateTime get lastUpdated => DateTime.fromMillisecondsSinceEpoch(timestamp);

  CurrencyRate? getRate(String currencyCode) {
    return rates[currencyCode.toUpperCase()];
  }

  double? getRateValue(String currencyCode) {
    return rates[currencyCode.toUpperCase()]?.rate;
  }
}

class CurrencyConversion {
  final String from;
  final String to;
  final double amount;
  final double convertedAmount;
  final double rate;

  CurrencyConversion({
    required this.from,
    required this.to,
    required this.amount,
    required this.convertedAmount,
    required this.rate,
  });

  factory CurrencyConversion.fromJson(Map<String, dynamic> json) {
    return CurrencyConversion(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      convertedAmount: (json['convertedAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'convertedAmount': convertedAmount,
      'rate': rate,
    };
  }
}
