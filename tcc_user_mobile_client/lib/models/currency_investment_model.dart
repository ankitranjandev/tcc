/// Currency Investment Models for TCC Mobile App
/// Allows users to invest TCC coins in foreign currencies

/// Supported currency codes
enum SupportedCurrency { EUR, GBP, JPY, AUD, CAD, CHF, CNY }

/// Currency metadata with display information
class CurrencyMetadata {
  static const Map<String, Map<String, String>> data = {
    'EUR': {'name': 'Euro', 'symbol': 'EUR', 'flag': 'EU'},
    'GBP': {'name': 'British Pound', 'symbol': 'GBP', 'flag': 'GB'},
    'JPY': {'name': 'Japanese Yen', 'symbol': 'JPY', 'flag': 'JP'},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': 'AU'},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': 'CA'},
    'CHF': {'name': 'Swiss Franc', 'symbol': 'Fr', 'flag': 'CH'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': 'CNY', 'flag': 'CN'},
  };

  static String getName(String code) => data[code]?['name'] ?? code;
  static String getSymbol(String code) => data[code]?['symbol'] ?? code;
  static String getFlag(String code) => data[code]?['flag'] ?? '';
}

/// Available currency for investment
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double rate; // How many of this currency per 1 TCC
  final double inverseRate; // How many TCC per 1 unit of this currency
  final double minInvestment;
  final double maxInvestment;
  final bool isActive;

  CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.rate,
    required this.inverseRate,
    required this.minInvestment,
    required this.maxInvestment,
    required this.isActive,
  });

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      code: json['code'] ?? '',
      name: json['name'] ?? CurrencyMetadata.getName(json['code'] ?? ''),
      symbol: json['symbol'] ?? CurrencyMetadata.getSymbol(json['code'] ?? ''),
      flag: json['flag'] ?? CurrencyMetadata.getFlag(json['code'] ?? ''),
      rate: (json['rate'] ?? 0).toDouble(),
      inverseRate: (json['inverse_rate'] ?? 0).toDouble(),
      minInvestment: (json['min_investment'] ?? 10).toDouble(),
      maxInvestment: (json['max_investment'] ?? 100000).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'rate': rate,
      'inverse_rate': inverseRate,
      'min_investment': minInvestment,
      'max_investment': maxInvestment,
      'is_active': isActive,
    };
  }

  /// Get flag emoji from country code
  String get flagEmoji {
    if (flag.isEmpty) return '';
    if (flag == 'EU') return '\u{1F1EA}\u{1F1FA}';
    final int firstLetter = flag.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = flag.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}

/// Currency investment holding
class CurrencyInvestment {
  final String id;
  final String currencyCode;
  final String? currencyName;
  final String? currencySymbol;
  final String? currencyFlag;
  final double amountInvested; // TCC invested
  final double currencyAmount; // Foreign currency bought
  final double purchaseRate;
  final String status; // ACTIVE, SOLD
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? soldAt;
  final double? soldRate;
  final double? soldAmountTcc;
  final double? profitLoss;
  final String? transactionId;
  final String? sellTransactionId;

  // Live data (calculated)
  final double? currentRate;
  final double? currentValueTcc;
  final double? unrealizedProfitLoss;
  final double? profitLossPercentage;

  CurrencyInvestment({
    required this.id,
    required this.currencyCode,
    this.currencyName,
    this.currencySymbol,
    this.currencyFlag,
    required this.amountInvested,
    required this.currencyAmount,
    required this.purchaseRate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.soldAt,
    this.soldRate,
    this.soldAmountTcc,
    this.profitLoss,
    this.transactionId,
    this.sellTransactionId,
    this.currentRate,
    this.currentValueTcc,
    this.unrealizedProfitLoss,
    this.profitLossPercentage,
  });

  factory CurrencyInvestment.fromJson(Map<String, dynamic> json) {
    return CurrencyInvestment(
      id: json['id'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      currencyName: json['currency_name'] ?? CurrencyMetadata.getName(json['currency_code'] ?? ''),
      currencySymbol: json['currency_symbol'] ?? CurrencyMetadata.getSymbol(json['currency_code'] ?? ''),
      currencyFlag: json['currency_flag'] ?? CurrencyMetadata.getFlag(json['currency_code'] ?? ''),
      amountInvested: (json['amount_invested'] ?? 0).toDouble(),
      currencyAmount: (json['currency_amount'] ?? 0).toDouble(),
      purchaseRate: (json['purchase_rate'] ?? 0).toDouble(),
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'])
          : null,
      soldRate: json['sold_rate'] != null
          ? (json['sold_rate']).toDouble()
          : null,
      soldAmountTcc: json['sold_amount_tcc'] != null
          ? (json['sold_amount_tcc']).toDouble()
          : null,
      profitLoss: json['profit_loss'] != null
          ? (json['profit_loss']).toDouble()
          : null,
      transactionId: json['transaction_id'],
      sellTransactionId: json['sell_transaction_id'],
      currentRate: json['current_rate'] != null
          ? (json['current_rate']).toDouble()
          : null,
      currentValueTcc: json['current_value_tcc'] != null
          ? (json['current_value_tcc']).toDouble()
          : null,
      unrealizedProfitLoss: json['unrealized_profit_loss'] != null
          ? (json['unrealized_profit_loss']).toDouble()
          : null,
      profitLossPercentage: json['profit_loss_percentage'] != null
          ? (json['profit_loss_percentage']).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'currency_symbol': currencySymbol,
      'currency_flag': currencyFlag,
      'amount_invested': amountInvested,
      'currency_amount': currencyAmount,
      'purchase_rate': purchaseRate,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
      'sold_rate': soldRate,
      'sold_amount_tcc': soldAmountTcc,
      'profit_loss': profitLoss,
      'transaction_id': transactionId,
      'sell_transaction_id': sellTransactionId,
      'current_rate': currentRate,
      'current_value_tcc': currentValueTcc,
      'unrealized_profit_loss': unrealizedProfitLoss,
      'profit_loss_percentage': profitLossPercentage,
    };
  }

  bool get isActive => status == 'ACTIVE';
  bool get isSold => status == 'SOLD';

  String get displayName => currencyName ?? CurrencyMetadata.getName(currencyCode);
  String get displaySymbol => currencySymbol ?? CurrencyMetadata.getSymbol(currencyCode);

  /// Get flag emoji from country code
  String get flagEmoji {
    final flag = currencyFlag ?? CurrencyMetadata.getFlag(currencyCode);
    if (flag.isEmpty) return '';
    if (flag == 'EU') return '\u{1F1EA}\u{1F1FA}';
    final int firstLetter = flag.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = flag.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  /// Calculate current value if live rate not available
  double get calculatedCurrentValue {
    if (currentValueTcc != null) return currentValueTcc!;
    if (currentRate != null && currentRate! > 0) {
      return currencyAmount / currentRate!;
    }
    return amountInvested;
  }

  /// Calculate unrealized P/L if not available
  double get calculatedProfitLoss {
    if (unrealizedProfitLoss != null) return unrealizedProfitLoss!;
    return calculatedCurrentValue - amountInvested;
  }

  /// Is this a profitable investment?
  bool get isProfitable => calculatedProfitLoss >= 0;
}

/// Summary of all currency holdings
class CurrencyHoldingsSummary {
  final double totalInvested;
  final double currentValue;
  final double totalProfitLoss;
  final double profitLossPercentage;
  final int activeHoldingsCount;

  CurrencyHoldingsSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.totalProfitLoss,
    required this.profitLossPercentage,
    required this.activeHoldingsCount,
  });

  factory CurrencyHoldingsSummary.fromJson(Map<String, dynamic> json) {
    return CurrencyHoldingsSummary(
      totalInvested: (json['total_invested'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      totalProfitLoss: (json['total_profit_loss'] ?? 0).toDouble(),
      profitLossPercentage: (json['profit_loss_percentage'] ?? 0).toDouble(),
      activeHoldingsCount: json['active_holdings_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_invested': totalInvested,
      'current_value': currentValue,
      'total_profit_loss': totalProfitLoss,
      'profit_loss_percentage': profitLossPercentage,
      'active_holdings_count': activeHoldingsCount,
    };
  }

  bool get isProfitable => totalProfitLoss >= 0;
}

/// Response containing holdings and summary
class CurrencyHoldingsResponse {
  final List<CurrencyInvestment> holdings;
  final CurrencyHoldingsSummary summary;

  CurrencyHoldingsResponse({
    required this.holdings,
    required this.summary,
  });

  factory CurrencyHoldingsResponse.fromJson(Map<String, dynamic> json) {
    return CurrencyHoldingsResponse(
      holdings: (json['holdings'] as List<dynamic>?)
              ?.map((h) => CurrencyInvestment.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      summary: CurrencyHoldingsSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Result of selling currency
class SellCurrencyResult {
  final String transactionId;
  final double currencySold;
  final String currencyCode;
  final double sellRate;
  final double tccReceived;
  final double profitLoss;
  final double profitLossPercentage;

  SellCurrencyResult({
    required this.transactionId,
    required this.currencySold,
    required this.currencyCode,
    required this.sellRate,
    required this.tccReceived,
    required this.profitLoss,
    required this.profitLossPercentage,
  });

  factory SellCurrencyResult.fromJson(Map<String, dynamic> json) {
    return SellCurrencyResult(
      transactionId: json['transaction_id'] ?? '',
      currencySold: (json['currency_sold'] ?? 0).toDouble(),
      currencyCode: json['currency_code'] ?? '',
      sellRate: (json['sell_rate'] ?? 0).toDouble(),
      tccReceived: (json['tcc_received'] ?? 0).toDouble(),
      profitLoss: (json['profit_loss'] ?? 0).toDouble(),
      profitLossPercentage: (json['profit_loss_percentage'] ?? 0).toDouble(),
    );
  }

  bool get isProfitable => profitLoss >= 0;
}

/// Investment limit for a currency
class CurrencyInvestmentLimit {
  final String currencyCode;
  final double minInvestment;
  final double maxInvestment;

  CurrencyInvestmentLimit({
    required this.currencyCode,
    required this.minInvestment,
    required this.maxInvestment,
  });

  factory CurrencyInvestmentLimit.fromJson(Map<String, dynamic> json) {
    return CurrencyInvestmentLimit(
      currencyCode: json['currency_code'] ?? '',
      minInvestment: (json['min_investment'] ?? 10).toDouble(),
      maxInvestment: (json['max_investment'] ?? 100000).toDouble(),
    );
  }
}
