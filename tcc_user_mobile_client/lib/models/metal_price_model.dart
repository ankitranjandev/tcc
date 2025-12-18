class MetalPrice {
  final String metal;
  final double price;
  final double pricePerGram;
  final String currency;
  final int timestamp;

  MetalPrice({
    required this.metal,
    required this.price,
    required this.pricePerGram,
    required this.currency,
    required this.timestamp,
  });

  factory MetalPrice.fromJson(Map<String, dynamic> json) {
    return MetalPrice(
      metal: json['metal'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      pricePerGram: (json['pricePerGram'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'SLL',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metal': metal,
      'price': price,
      'pricePerGram': pricePerGram,
      'currency': currency,
      'timestamp': timestamp,
    };
  }

  DateTime get lastUpdated => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  String get displayName {
    switch (metal.toUpperCase()) {
      case 'XAU':
        return 'Gold';
      case 'XAG':
        return 'Silver';
      case 'XPT':
        return 'Platinum';
      default:
        return metal;
    }
  }
}

class MetalPricesResponse {
  final String base;
  final MetalPrices metals;
  final int timestamp;

  MetalPricesResponse({
    required this.base,
    required this.metals,
    required this.timestamp,
  });

  factory MetalPricesResponse.fromJson(Map<String, dynamic> json) {
    return MetalPricesResponse(
      base: json['base'] ?? 'SLL',
      metals: MetalPrices.fromJson(json['metals'] ?? {}),
      timestamp: json['timestamp'] ?? 0,
    );
  }

  DateTime get lastUpdated => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

class MetalPrices {
  final MetalPriceDetail gold;
  final MetalPriceDetail silver;
  final MetalPriceDetail platinum;

  MetalPrices({
    required this.gold,
    required this.silver,
    required this.platinum,
  });

  factory MetalPrices.fromJson(Map<String, dynamic> json) {
    return MetalPrices(
      gold: MetalPriceDetail.fromJson(json['gold'] ?? {}),
      silver: MetalPriceDetail.fromJson(json['silver'] ?? {}),
      platinum: MetalPriceDetail.fromJson(json['platinum'] ?? {}),
    );
  }

  List<MetalPriceDetail> get all => [gold, silver, platinum];
}

class MetalPriceDetail {
  final double price;
  final double pricePerGram;

  MetalPriceDetail({
    required this.price,
    required this.pricePerGram,
  });

  factory MetalPriceDetail.fromJson(Map<String, dynamic> json) {
    return MetalPriceDetail(
      price: (json['price'] ?? 0).toDouble(),
      pricePerGram: (json['pricePerGram'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'pricePerGram': pricePerGram,
    };
  }
}
