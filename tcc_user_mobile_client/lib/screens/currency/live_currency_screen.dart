import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../services/currency_service.dart';
import '../../models/currency_rate_model.dart';
import '../../models/currency_investment_model.dart';

class LiveCurrencyScreen extends StatefulWidget {
  const LiveCurrencyScreen({super.key});

  @override
  State<LiveCurrencyScreen> createState() => _LiveCurrencyScreenState();
}

class _LiveCurrencyScreenState extends State<LiveCurrencyScreen> {
  final CurrencyService _currencyService = CurrencyService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, CurrencyRate> _rates = {};
  DateTime? _lastUpdated;

  // Popular currencies to display
  final List<Map<String, String>> _popularCurrencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'Fr', 'flag': '🇨🇭'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦', 'flag': '🇳🇬'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': '₵', 'flag': '🇬🇭'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrencyRates();
  }

  Future<void> _loadCurrencyRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currencyCodes = _popularCurrencies.map((c) => c['code']!).toList();

      final result = await _currencyService.getCurrencyRates(
        baseCurrency: 'USD', // Use USD as base for popular currencies
        currencies: currencyCodes,
      );

      if (result['success'] == true) {
        final currencyRates = result['data'] as CurrencyRatesResponse;
        setState(() {
          _rates = currencyRates.rates;
          _lastUpdated = currencyRates.lastUpdated;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load currency rates';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatLastUpdated() {
    if (_lastUpdated == null) return '';
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(_lastUpdated!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Currency Rates',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _isLoading ? null : _loadCurrencyRates,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildCurrencyList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCurrencyRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyList() {
    return Column(
      children: [
        // Header with last updated time
        if (_lastUpdated != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Updated ${_formatLastUpdated()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Currency list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _popularCurrencies.length,
            itemBuilder: (context, index) {
              final currency = _popularCurrencies[index];
              final code = currency['code']!;
              final rate = _rates[code];

              return _buildCurrencyCard(
                flag: currency['flag']!,
                code: code,
                name: currency['name']!,
                symbol: currency['symbol']!,
                rate: rate?.rate ?? 0.0,
              );
            },
          ),
        ),
      ],
    );
  }

  // Currencies that can be invested in (USD excluded since TCC = USD)
  static const List<String> _investableCurrencies = ['EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY'];

  bool _canInvest(String code) => _investableCurrencies.contains(code);

  void _navigateToInvest(String code, String name, String flag, double rate) {
    // Create CurrencyInfo to pass to the purchase screen
    // Get the country code from flag emoji or use metadata
    final countryCode = CurrencyMetadata.getFlag(code);
    final currencyInfo = CurrencyInfo(
      code: code,
      name: name,
      symbol: CurrencyMetadata.getSymbol(code),
      flag: countryCode,
      rate: rate,
      inverseRate: rate > 0 ? 1 / rate : 0,
      minInvestment: 10,
      maxInvestment: 100000,
      isActive: true,
    );
    context.push('/investments/currency/buy/$code', extra: currencyInfo);
  }

  Widget _buildCurrencyCard({
    required String flag,
    required String code,
    required String name,
    required String symbol,
    required double rate,
  }) {
    final formatter = NumberFormat('#,##0.0000');
    final canInvest = _canInvest(code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canInvest ? () => _navigateToInvest(code, name, flag, rate) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: canInvest ? Border.all(color: AppColors.warning.withValues(alpha: 0.3)) : null,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag and currency info
              Expanded(
                child: Row(
                  children: [
                    // Flag
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        flag,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Currency details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                code,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (canInvest) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Invest',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Exchange rate and action
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$symbol${formatter.format(rate)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1 TCC = ${formatter.format(rate)} $code',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  if (canInvest) ...[
                    SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
