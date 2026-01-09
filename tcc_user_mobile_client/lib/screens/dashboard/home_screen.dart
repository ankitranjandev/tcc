import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/bank_account_service.dart';
import '../../services/investment_service.dart';
import '../../services/metal_price_service.dart';
import '../../services/currency_service.dart';
import '../../services/election_service.dart';
import '../../models/currency_rate_model.dart';
import '../../models/investment_model.dart';
import '../../models/bank_account_model.dart';
import '../../widgets/add_money_bottom_sheet.dart';
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
        final responseData = walletResponse['data'];
        final wallet = responseData['data']?['wallet'];
        _walletBalance = (wallet?['balance'] ?? 0).toDouble();
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

              SizedBox(height: 20),

              // Agent Locator & Community Voting Cards (Side by Side)
              _buildAgentAndVotingRow(),

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
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
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
      child: Column(
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
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAddMoneyDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5B86E5),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Add Money',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showWithdrawDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: Text(
                    'Withdraw',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentAndVotingRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use responsive sizing based on available width
          final isCompact = constraints.maxWidth < 360;
          final cardSpacing = 12.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAgentLocatorCard(isCompact: isCompact),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildVotingCard(isCompact: isCompact),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAgentLocatorCard({bool isCompact = false}) {
    return InkWell(
      onTap: () => context.push('/agent-search'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 40 : 48,
              height: isCompact ? 40 : 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: isCompact ? 20 : 24,
              ),
            ),
            SizedBox(height: isCompact ? 10 : 12),
            Text(
              'Find Nearby\nAgent',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Locate TCC agents',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: isCompact ? 11 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isCompact ? 14 : 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingCard({bool isCompact = false}) {
    return InkWell(
      onTap: () => context.push('/elections'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isCompact ? 40 : 48,
                  height: isCompact ? 40 : 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    color: Colors.white,
                    size: isCompact ? 20 : 24,
                  ),
                ),
                if (_activeElectionsCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: isCompact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_activeElectionsCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 12),
            Text(
              'Community\nVoting',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _activeElectionsCount > 0
                  ? 'Cast your vote'
                  : 'Vote on decisions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: isCompact ? 11 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isCompact ? 14 : 16,
                ),
              ],
            ),
          ],
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
                        '1 TCC = 1 USD',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
    showAddMoneyBottomSheet(
      context,
      onSuccess: () {
        // Refresh the HomeScreen data to show updated balance
        _loadData();
      },
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WithdrawBottomSheet(
        walletBalance: _walletBalance,
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

// Withdraw Bottom Sheet with OTP verification
class _WithdrawBottomSheet extends StatefulWidget {
  final double walletBalance;
  final VoidCallback? onSuccess;

  const _WithdrawBottomSheet({
    required this.walletBalance,
    this.onSuccess,
  });

  @override
  _WithdrawBottomSheetState createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final BankAccountService _bankAccountService = BankAccountService();

  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  String? _errorMessage;
  List<BankAccountModel> _bankAccounts = [];
  BankAccountModel? _selectedAccount;

  // Add account form
  bool _showAddAccountForm = false;
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _branchAddressController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();

  // OTP verification
  bool _showOtpInput = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _branchAddressController.dispose();
    _swiftCodeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    setState(() => _isLoadingAccounts = true);

    try {
      final result = await _bankAccountService.getBankAccounts();
      if (result['success'] == true && result['data'] != null) {
        final dynamic data = result['data'];
        List<dynamic> accountsJson;

        if (data is List) {
          accountsJson = data;
        } else if (data is Map && data['accounts'] != null) {
          accountsJson = data['accounts'];
        } else if (data is Map && data['data'] != null) {
          final innerData = data['data'];
          if (innerData is List) {
            accountsJson = innerData;
          } else if (innerData is Map && innerData['accounts'] != null) {
            accountsJson = innerData['accounts'];
          } else {
            accountsJson = [];
          }
        } else {
          accountsJson = [];
        }

        _bankAccounts = accountsJson
            .map((json) => BankAccountModel.fromJson(json))
            .toList();

        // Select primary account by default
        if (_bankAccounts.isNotEmpty) {
          _selectedAccount = _bankAccounts.firstWhere(
            (acc) => acc.isPrimary,
            orElse: () => _bankAccounts.first,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load bank accounts: $e');
    }

    setState(() => _isLoadingAccounts = false);
  }

  double _calculateFee(double amount) {
    // Using non-KYC fee structure (2%, min 100, max 1000) as default
    // TODO: Check user's KYC status for proper fee calculation
    final fee = amount * 0.02;
    if (fee < 100) return 100;
    if (fee > 1000) return 1000;
    return fee;
  }

  Future<void> _requestOtp() async {
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

    if (amount < 1) {
      setState(() => _errorMessage = 'Please enter an amount greater than 0');
      return;
    }

    final fee = _calculateFee(amount);
    final totalDeduction = amount + fee;

    if (totalDeduction > widget.walletBalance) {
      setState(() => _errorMessage = 'Insufficient balance. You need TCC ${totalDeduction.toStringAsFixed(0)} (including fee)');
      return;
    }

    if (_selectedAccount == null) {
      setState(() => _errorMessage = 'Please select a bank account');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _walletService.requestWithdrawalOTP(
        amount: amount,
        withdrawalMethod: 'BANK_TRANSFER',
        bankAccountId: _selectedAccount!.id,
      );

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
          _showOtpInput = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to request OTP';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _processWithdrawal() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    final amount = double.parse(_amountController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _walletService.withdraw(
        amount: amount,
        withdrawalMethod: 'BANK_TRANSFER',
        otp: otp,
        bankAccountId: _selectedAccount!.id,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Withdrawal request submitted! We will process it within 24-48 hours.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Withdrawal failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _addBankAccount() async {
    if (_bankNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter bank name');
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter account number');
      return;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter account holder name');
      return;
    }
    if (_branchAddressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter branch address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _bankAccountService.createBankAccount(
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        branchAddress: _branchAddressController.text.trim(),
        swiftCode: _swiftCodeController.text.trim().isNotEmpty
            ? _swiftCodeController.text.trim()
            : null,
        isPrimary: _bankAccounts.isEmpty,
      );

      if (result['success'] == true) {
        // Reload accounts and select the new one
        await _loadBankAccounts();
        setState(() {
          _showAddAccountForm = false;
          _isLoading = false;
          // Clear form
          _bankNameController.clear();
          _accountNumberController.clear();
          _accountHolderController.clear();
          _branchAddressController.clear();
          _swiftCodeController.clear();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to add bank account';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tccFormat = NumberFormat.currency(symbol: 'TCC ', decimalDigits: 0);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = _calculateFee(amount);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showOtpInput ? 'Verify OTP' : (_showAddAccountForm ? 'Add Bank Account' : 'Withdraw'),
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
            SizedBox(height: 8),

            // Balance display
            if (!_showAddAccountForm && !_showOtpInput)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Available: ${tccFormat.format(widget.walletBalance)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),

            // OTP Input Section
            if (_showOtpInput) ...[
              Text(
                'Enter the 6-digit OTP sent to your phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    _processWithdrawal();
                  }
                },
              ),
              SizedBox(height: 16),

              // Withdrawal summary
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Amount', tccFormat.format(amount)),
                    SizedBox(height: 8),
                    _buildSummaryRow('Fee (2%)', tccFormat.format(fee)),
                    Divider(height: 16),
                    _buildSummaryRow('Total Deduction', tccFormat.format(amount + fee), isBold: true),
                    SizedBox(height: 8),
                    _buildSummaryRow('To Account', '${_selectedAccount?.bankName} - ${_selectedAccount?.displayAccountNumber}'),
                  ],
                ),
              ),
            ]

            // Add Account Form
            else if (_showAddAccountForm) ...[
              TextField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _accountHolderController,
                decoration: InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _branchAddressController,
                decoration: InputDecoration(
                  labelText: 'Branch Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _swiftCodeController,
                decoration: InputDecoration(
                  labelText: 'SWIFT Code (Optional)',
                  hintText: 'For international transfers',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _showAddAccountForm = false;
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addBankAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2C3E50),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : Text('Add Account', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ]

            // Main Withdrawal Form
            else ...[
              // Amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 18),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Amount (TCC)',
                  hintText: 'Enter amount to withdraw',
                  prefixText: 'TCC ',
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

              // Fee display
              if (amount >= 1) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Amount', tccFormat.format(amount)),
                      SizedBox(height: 4),
                      _buildSummaryRow('Fee (2%)', tccFormat.format(fee)),
                      Divider(height: 12),
                      _buildSummaryRow('Total Deduction', tccFormat.format(amount + fee), isBold: true),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Bank account selector
              Text(
                'Select Bank Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),

              if (_isLoadingAccounts)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_bankAccounts.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance, size: 32, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'No bank account found',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add a bank account to withdraw funds',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showAddAccountForm = true),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Bank Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ..._bankAccounts.map((account) => _buildAccountTile(account)),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showAddAccountForm = true),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add New Account'),
                    ),
                  ],
                ),
            ],

            // Error message
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

            // Action button
            if (!_showAddAccountForm)
              ElevatedButton(
                onPressed: _isLoading || (_bankAccounts.isEmpty && !_showOtpInput)
                    ? null
                    : (_showOtpInput ? _processWithdrawal : _requestOtp),
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
                        _showOtpInput ? 'Confirm Withdrawal' : 'Request OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

            if (!_showAddAccountForm && !_showOtpInput) ...[
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Processing time: 24-48 hours',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(BankAccountModel account) {
    final isSelected = _selectedAccount?.id == account.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedAccount = account),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2C3E50).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2C3E50) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance, color: Colors.blue, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${account.displayAccountNumber} - ${account.accountHolderName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            if (account.isPrimary)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Primary',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ),
            if (isSelected)
              Icon(Icons.check_circle, color: Color(0xFF2C3E50)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
