import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/stripe_service.dart';
import '../../services/investment_service.dart';
import '../../services/metal_price_service.dart';
import '../../services/currency_service.dart';
import '../../services/election_service.dart';
import '../../models/currency_rate_model.dart';
import '../../models/investment_model.dart';
import '../currency/live_currency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService();
  final InvestmentService _investmentService = InvestmentService();
  final MetalPriceService _metalPriceService = MetalPriceService();
  final CurrencyService _currencyService = CurrencyService();
  final ElectionService _electionService = ElectionService();

  bool _isLoading = true;
  String? _errorMessage;

  // Data
  double _walletBalance = 0.0;
  double _totalInvested = 0.0;
  double _expectedReturns = 0.0;

  // Market data
  List<Map<String, dynamic>> _metalPrices = [];
  CurrencyRatesResponse? _currencyRates;
  bool _isLoadingMarketData = false;

  // Voting data
  int _activeElectionsCount = 0;

  // Agriculture opportunities
  List<InvestmentOpportunity> _agroOpportunities = [];

  // Education opportunities
  List<InvestmentOpportunity> _educationOpportunities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch wallet balance
      final walletResponse = await _walletService.getBalance();
      if (walletResponse['success'] == true) {
        final walletData = walletResponse['data'];
        _walletBalance = (walletData['balance'] ?? 0).toDouble();
      }

      // Fetch investment portfolio
      final portfolioResponse = await _investmentService.getPortfolio();
      if (portfolioResponse['success'] == true) {
        final portfolioData = portfolioResponse['data'];
        _totalInvested = (portfolioData['total_invested'] ?? 0).toDouble();
        _expectedReturns = (portfolioData['expected_returns'] ?? 0).toDouble();
      }

      setState(() {
        _isLoading = false;
      });

      // Load market data (don't block main loading)
      _loadMarketData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoadingMarketData = true;
    });

    try {
      // Fetch metal prices
      final metalPricesResult = await _metalPriceService.getFormattedMetalPricesForDisplay();

      // Fetch currency rates
      final currencyRatesResult = await _currencyService.getCurrencyRates(
        baseCurrency: 'SLL',
        currencies: ['USD', 'EUR', 'GBP'],
      );

      // Fetch active elections count
      try {
        final elections = await _electionService.getActiveElections();
        _activeElectionsCount = elections.length;
      } catch (e) {
        debugPrint('Failed to load elections: $e');
        _activeElectionsCount = 0;
      }

      // Fetch agriculture opportunities
      try {
        final agroResponse = await _investmentService.getOpportunities(
          category: 'AGRICULTURE',
          perPage: 2, // Only fetch top 2 for home screen
        );

        if (agroResponse['success'] == true && agroResponse['data'] != null) {
          final data = agroResponse['data'];
          final opportunities = data['opportunities'] as List<dynamic>?;

          if (opportunities != null) {
            _agroOpportunities = opportunities
                .map((json) => InvestmentOpportunity.fromJson(json as Map<String, dynamic>))
                .where((opp) => opp.isActive && opp.hasUnitsAvailable)
                .take(2)
                .toList();
          }
        }
      } catch (e) {
        debugPrint('Failed to load agriculture opportunities: $e');
        _agroOpportunities = [];
      }

      // Fetch education opportunities
      try {
        final educationResponse = await _investmentService.getOpportunities(
          category: 'EDUCATION',
          perPage: 2, // Only fetch top 2 for home screen
        );

        if (educationResponse['success'] == true && educationResponse['data'] != null) {
          final data = educationResponse['data'];
          final opportunities = data['opportunities'] as List<dynamic>?;

          if (opportunities != null) {
            _educationOpportunities = opportunities
                .map((json) => InvestmentOpportunity.fromJson(json as Map<String, dynamic>))
                .where((opp) => opp.isActive && opp.hasUnitsAvailable)
                .take(2)
                .toList();
          }
        }
      } catch (e) {
        debugPrint('Failed to load education opportunities: $e');
        _educationOpportunities = [];
      }

      setState(() {
        _metalPrices = metalPricesResult;
        if (currencyRatesResult['success'] == true) {
          _currencyRates = currencyRatesResult['data'] as CurrencyRatesResponse;
        }
        _isLoadingMarketData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMarketData = false;
      });
      // Don't show error for market data, just use fallback
      debugPrint('Failed to load market data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final currencyFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 0);
    final tccFormat = NumberFormat.currency(symbol: 'TCC ', decimalDigits: 0);

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: AppColors.error)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(user),

              SizedBox(height: 20),

              // TCC Coin Balance Card
              _buildBalanceCard(currencyFormat, tccFormat),

              SizedBox(height: 16),

              // Stats Cards Row
              _buildStatsRow(currencyFormat, tccFormat),

              SizedBox(height: 20),

              // Agent Locator Button
              _buildAgentLocatorButton(),

              SizedBox(height: 24),

              // Community Voting Card
              _buildVotingCard(),

              SizedBox(height: 24),

              // Currency Investment Card
              _buildCurrencyCard(),

              SizedBox(height: 24),

              // Minerals Section
              _buildMineralsSection(),

              SizedBox(height: 24),

              // Fixed Returns Banner
              _buildFixedReturnsBanner(),

              SizedBox(height: 24),

              // Agro Business Section
              _buildAgroSection(),

              SizedBox(height: 24),

              // Education Section
              _buildEducationSection(),

              SizedBox(height: 24),

              // Grow your Wealth Footer
              _buildFooterSection(),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(user) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.firstName ?? 'Guest'}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Explore and grow your wealth',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat currencyFormat, NumberFormat tccFormat) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5B86E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TCC Coin',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                tccFormat.format(_walletBalance),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '\$1 = 1 Coin',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showAddMoneyDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF5B86E5),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Add Money',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(NumberFormat currencyFormat, NumberFormat tccFormat) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDC830), Color(0xFFF37335)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Invested',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tccFormat.format(_totalInvested),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected Return',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tccFormat.format(_expectedReturns),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentLocatorButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/agent-search'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Nearby Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Locate TCC agents near you',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/elections'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF667EEA).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.how_to_vote,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Voting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _activeElectionsCount > 0
                          ? '$_activeElectionsCount active ${_activeElectionsCount == 1 ? 'poll' : 'polls'} • Cast your vote'
                          : 'Vote on community decisions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeElectionsCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_activeElectionsCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    // Get USD rate, fallback to mock data if not available
    final usdRate = _currencyRates?.getRate('USD');
    final displayRate = usdRate != null
        ? NumberFormat('#,##0.0000').format(usdRate.rate)
        : '0.0004';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invest in Foreign Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_isLoadingMarketData && _currencyRates == null)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveCurrencyScreen(),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1 Leone',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$$displayRate USD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Placeholder for chart
                  Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.show_chart, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMineralsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minerals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Invest in rare minerals (e.g. Gold, Silver, Platinum)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: _isLoadingMarketData && _metalPrices.isEmpty
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: _metalPrices.isEmpty
                      ? [
                          // Fallback to mock data if API fails
                          _buildMineralCard('Gold', 'TCC234', 'Live', null),
                          SizedBox(width: 12),
                          _buildMineralCard('Silver', 'TCC150', 'Live', null),
                          SizedBox(width: 12),
                          _buildMineralCard('Platinum', 'TCC350', 'Live', null),
                        ]
                      : _metalPrices
                          .map((metal) => Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: _buildMineralCard(
                                  metal['name'],
                                  'TCC${NumberFormat('#,##0.00').format(metal['price'])}',
                                  'Live',
                                  metal,
                                ),
                              ))
                          .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMineralCard(String name, String value, String percentage, Map<String, dynamic>? metalData) {
    return GestureDetector(
      onTap: () => context.push('/investments/minerals'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(Icons.diamond, size: 40, color: Colors.amber[700]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        percentage,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      // Mini chart placeholder
                      SizedBox(
                        width: 30,
                        height: 15,
                        child: CustomPaint(
                          painter: MiniChartPainter(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedReturnsBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Invest in Fixed Returns',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgroSection() {
    final tccFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agro Business',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Invest in farming activity and all of the produce',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _agroOpportunities.isEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: _buildAgroCard('Land Lease', 'TCC2,217', '+5% +5.6', null),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildAgroCard('Processing', 'TCC2,217', '+5% +6.1', null),
                      ),
                    ],
                  )
                : Row(
                    children: _agroOpportunities.length == 1
                        ? [
                            Expanded(
                              child: _buildAgroCard(
                                _agroOpportunities[0].title,
                                tccFormat.format(_agroOpportunities[0].minInvestment),
                                '${_agroOpportunities[0].returnRate}% ROI',
                                _agroOpportunities[0],
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: _buildAgroCard(
                                _agroOpportunities[0].title,
                                tccFormat.format(_agroOpportunities[0].minInvestment),
                                '${_agroOpportunities[0].returnRate}% ROI',
                                _agroOpportunities[0],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAgroCard(
                                _agroOpportunities[1].title,
                                tccFormat.format(_agroOpportunities[1].minInvestment),
                                '${_agroOpportunities[1].returnRate}% ROI',
                                _agroOpportunities[1],
                              ),
                            ),
                          ],
                  ),
          ),
        ],
    );
  }

  Widget _buildAgroCard(String name, String value, String percentage, InvestmentOpportunity? opportunity) {
    return GestureDetector(
      onTap: () {
        if (opportunity != null && opportunity.id.isNotEmpty) {
          // Navigate to specific opportunity details
          context.push('/investments/opportunities/${opportunity.id}');
        } else {
          // Navigate to agriculture category page
          context.push('/investments/agriculture');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(Icons.agriculture, size: 50, color: Colors.green[700]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection() {
    final tccFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Education',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Invest in people\'s education and get huge profit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _educationOpportunities.isEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: _buildEducationCard('Institutions', 'TCC2,217', '+5% +5.6', null),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildEducationCard('Dormitory', 'TCC2,217', '+5% +6.1', null),
                      ),
                    ],
                  )
                : Row(
                    children: _educationOpportunities.length == 1
                        ? [
                            Expanded(
                              child: _buildEducationCard(
                                _educationOpportunities[0].title,
                                tccFormat.format(_educationOpportunities[0].minInvestment),
                                '${_educationOpportunities[0].returnRate}% ROI',
                                _educationOpportunities[0],
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: _buildEducationCard(
                                _educationOpportunities[0].title,
                                tccFormat.format(_educationOpportunities[0].minInvestment),
                                '${_educationOpportunities[0].returnRate}% ROI',
                                _educationOpportunities[0],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildEducationCard(
                                _educationOpportunities[1].title,
                                tccFormat.format(_educationOpportunities[1].minInvestment),
                                '${_educationOpportunities[1].returnRate}% ROI',
                                _educationOpportunities[1],
                              ),
                            ),
                          ],
                  ),
          ),
        ],
    );
  }

  Widget _buildEducationCard(String name, String value, String percentage, InvestmentOpportunity? opportunity) {
    return GestureDetector(
      onTap: () {
        if (opportunity != null && opportunity.id.isNotEmpty) {
          // Navigate to specific opportunity details
          context.push('/investments/opportunities/${opportunity.id}');
        } else {
          // Navigate to education category page
          context.push('/investments/education');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(Icons.school, size: 50, color: Colors.blue[700]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Grow your Wealth\nwith TCC',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primaryBlue, size: 28),
              SizedBox(width: 8),
              Icon(Icons.account_balance, color: AppColors.secondaryYellow, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddMoneyBottomSheet(
        onSuccess: () {
          // Refresh the HomeScreen data to show updated balance
          _loadData();
        },
      ),
    );
  }
}

// Mini chart painter for trend lines
class MiniChartPainter extends CustomPainter {
  final Color color;

  MiniChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add Money Bottom Sheet with Stripe integration
class _AddMoneyBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _AddMoneyBottomSheet({this.onSuccess});

  @override
  _AddMoneyBottomSheetState createState() => _AddMoneyBottomSheetState();
}

class _AddMoneyBottomSheetState extends State<_AddMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final StripeService _stripeService = StripeService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _paymentIntentId;

  final List<int> _quickAmounts = [1000, 5000, 10000, 25000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount < 1000) {
      setState(() => _errorMessage = 'Minimum amount is Le 1,000');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create payment intent
      final result = await _walletService.createPaymentIntent(amount: amount);

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Failed to create payment intent');
      }

      final data = result['data']['data'];
      final clientSecret = data['client_secret'];

      // Extract payment intent ID
      _paymentIntentId = _stripeService.extractPaymentIntentId(clientSecret);

      setState(() => _isLoading = false);

      // Step 2: Process Stripe payment
      if (!mounted) return;
      final paymentSuccessful = await _stripeService.processPayment(
        clientSecret: clientSecret,
        merchantName: 'TCC Wallet Top-up',
        context: context,
      );

      if (!paymentSuccessful) {
        // User cancelled payment
        if (mounted) {
          setState(() {
            _errorMessage = 'Payment cancelled';
          });
        }
        return;
      }

      // Step 3: Verify payment with backend
      if (mounted) {
        _stripeService.showVerificationDialog(context);
      }

      final verificationResult = await _stripeService.verifyPaymentWithPolling(
        paymentIntentId: _paymentIntentId!,
        maxAttempts: 5,
        delaySeconds: 2,
      );

      if (mounted) {
        // Close verification dialog
        Navigator.of(context).pop();

        if (verificationResult['verified'] == true) {
          // Payment verified successfully
          // Close the bottom sheet
          Navigator.pop(context);

          // Show success message
          final isTestMode = verificationResult['test_mode'] == true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTestMode
                    ? 'Payment successful! (Test mode - backend verification skipped)'
                    : 'Payment successful! Your wallet has been credited.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Refresh parent screen balance
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        } else if (verificationResult['timeout'] == true) {
          // Verification timeout - payment is processing
          // Close the bottom sheet
          Navigator.pop(context);

          // Show processing dialog
          _stripeService.showProcessingDialog(context, _paymentIntentId!);
        } else {
          // Verification failed
          setState(() {
            _errorMessage = verificationResult['error'] ?? 'Payment verification failed';
          });
        }
      }
    } on StripeException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.error.code == FailureCode.Canceled) {
          _errorMessage = 'Payment cancelled';
        } else {
          _errorMessage = e.error.message ?? 'Payment failed';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Amount (Le)',
              hintText: 'Enter amount',
              prefixText: 'TCC',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF2C3E50), width: 2),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              final isSelected = _amountController.text == amount.toString();
              return InkWell(
                onTap: () => _selectQuickAmount(amount),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF2C3E50) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(0xFF2C3E50) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    'TCC${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24),

          // Pay button
          ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2C3E50),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          SizedBox(height: 12),

          // Info text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
