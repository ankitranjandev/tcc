import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/currency_investment_model.dart';
import '../../services/currency_investment_service.dart';

class CurrencyInvestmentScreen extends StatefulWidget {
  const CurrencyInvestmentScreen({super.key});

  @override
  State<CurrencyInvestmentScreen> createState() => _CurrencyInvestmentScreenState();
}

class _CurrencyInvestmentScreenState extends State<CurrencyInvestmentScreen> {
  final CurrencyInvestmentService _service = CurrencyInvestmentService();
  List<CurrencyInfo> _currencies = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.getAvailableCurrencies();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final currencies = data['currencies'] as List<dynamic>?;
        final timestamp = data['timestamp'] as int?;

        if (currencies != null) {
          setState(() {
            _currencies = currencies
                .map((c) => CurrencyInfo.fromJson(c as Map<String, dynamic>))
                .where((c) => c.isActive)
                .toList();
            _lastUpdated = timestamp != null
                ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                : DateTime.now();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['error']?.toString() ?? 'Failed to load currencies';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getTimeSinceUpdate() {
    if (_lastUpdated == null) return '';
    final difference = DateTime.now().difference(_lastUpdated!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    return '${difference.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Currency Investment',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue),
            onPressed: () {
              context.push('/investments/currency/holdings');
            },
            tooltip: 'My Holdings',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodySmall?.color),
            onPressed: _loadCurrencies,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState(context)
              : _currencies.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCurrencyList(context),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          SizedBox(height: 16),
          Text(
            'Fetching live rates...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'Failed to load currencies',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCurrencies,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.currency_exchange, size: 80, color: Theme.of(context).dividerColor),
          SizedBox(height: 16),
          Text(
            'No currencies available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for currency investment options',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCurrencies,
      color: AppColors.warning,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                'Invest in Currencies',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Use TCC coins to buy foreign currencies. Sell when the value increases to make a profit.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.primaryBlue),
                  SizedBox(width: 4),
                  Text(
                    '1 TCC = 1 USD',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  if (_lastUpdated != null)
                    Text(
                      'Updated ${_getTimeSinceUpdate()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24),

              // My Holdings card
              _buildHoldingsCard(context),
              SizedBox(height: 24),

              // Currency list
              Text(
                'Available Currencies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              ..._currencies.map((currency) => _buildCurrencyCard(context, currency)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingsCard(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/investments/currency/holdings');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Currency Holdings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View and manage your currency investments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(BuildContext context, CurrencyInfo currency) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/investments/currency/buy/${currency.code}', extra: currency);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).textTheme.titleLarge?.color ?? AppColors.black)
                    .withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    currency.flagEmoji,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Currency info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.code,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      currency.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Rate info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '1 TCC = ${currency.rate.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Invest',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
