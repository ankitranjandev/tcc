import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/investment_model.dart';
import '../../services/investment_service.dart';

class InvestmentCategoryScreen extends StatefulWidget {
  final String category;

  const InvestmentCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<InvestmentCategoryScreen> createState() => _InvestmentCategoryScreenState();
}

class _InvestmentCategoryScreenState extends State<InvestmentCategoryScreen> {
  final InvestmentService _investmentService = InvestmentService();
  List<InvestmentOpportunity> _opportunities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  Future<void> _loadOpportunities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _investmentService.getOpportunities(
        category: widget.category.toUpperCase(),
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final opportunities = data['opportunities'] as List<dynamic>?;

        if (opportunities != null) {
          setState(() {
            _opportunities = opportunities
                .map((json) => InvestmentOpportunity.fromJson(json as Map<String, dynamic>))
                .where((opp) => opp.isActive && opp.hasUnitsAvailable)
                .toList();
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
          _errorMessage = response['error']?.toString() ?? 'Failed to load opportunities';
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

  String get _categoryTitle {
    switch (widget.category.toUpperCase()) {
      case 'AGRICULTURE':
        return 'Agriculture';
      case 'MINERALS':
        return 'Minerals';
      case 'EDUCATION':
        return 'Education';
      default:
        return category;
    }
  }

  String get _categoryDescription {
    switch (widget.category.toUpperCase()) {
      case 'AGRICULTURE':
        return 'Invest in agricultural projects with fixed returns. Support local farming and earn stable income.';
      case 'MINERALS':
        return 'Invest in precious metals like silver, gold, and platinum. High-value investments in mineral resources.';
      case 'EDUCATION':
        return 'Invest in education and create social impact. Support students and educational infrastructure.';
      case 'CURRENCY':
        return 'Invest in foreign exchange and digital currencies. Trade forex pairs and crypto indices.';
      default:
        return 'Explore investment opportunities in this category.';
    }
  }

  Color get _categoryColor {
    switch (widget.category.toUpperCase()) {
      case 'AGRICULTURE':
        return AppColors.secondaryGreen;
      case 'MINERALS':
        return AppColors.secondaryYellow;
      case 'EDUCATION':
        return AppColors.primaryBlue;
      case 'CURRENCY':
        return AppColors.warning;
      default:
        return AppColors.primaryBlue;
    }
  }

  String get _categoryBadgeText {
    switch (widget.category.toUpperCase()) {
      case 'AGRICULTURE':
        return 'Risk free investment';
      case 'MINERALS':
        return 'Precious metals';
      case 'EDUCATION':
        return 'Social impact';
      case 'CURRENCY':
        return 'Forex & Crypto';
      default:
        return '';
    }
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
        actions: [
          if (_categoryBadgeText.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _categoryBadgeText,
                style: TextStyle(
                  color: _categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState(context)
              : _opportunities.isEmpty
                  ? _buildEmptyState(context)
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _categoryTitle,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _categoryDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 32),
                            ..._opportunities.map((opportunity) => _buildOpportunityCard(context, opportunity)),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_categoryColor),
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
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOpportunities,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _categoryColor,
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
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context).dividerColor,
          ),
          SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for new investment opportunities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context, InvestmentOpportunity opportunity) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/investments/${widget.category.toLowerCase()}/${opportunity.id}', extra: opportunity);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).textTheme.titleLarge?.color ?? AppColors.black).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Opportunity icon/image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getOpportunityIcon(opportunity.title),
                  color: _categoryColor,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              // Opportunity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tenure: ${opportunity.tenureMonths} months',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${opportunity.availableUnits}/${opportunity.totalUnits} units available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Investment range and ROI
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TCC ${opportunity.minInvestment.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    '- ${opportunity.maxInvestment.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${opportunity.returnRate.toStringAsFixed(1)}% ROI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
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

  IconData _getOpportunityIcon(String title) {
    final name = title.toLowerCase();
    if (name.contains('land') || name.contains('lease')) {
      return Icons.landscape;
    } else if (name.contains('processing')) {
      return Icons.factory;
    } else if (name.contains('lot')) {
      return Icons.grid_view;
    } else if (name.contains('plot')) {
      return Icons.crop;
    } else if (name.contains('farm')) {
      return Icons.agriculture;
    } else if (name.contains('silver')) {
      return Icons.circle_outlined;
    } else if (name.contains('gold')) {
      return Icons.circle;
    } else if (name.contains('platinum')) {
      return Icons.toll;
    } else if (name.contains('student') || name.contains('loan')) {
      return Icons.school;
    } else if (name.contains('infrastructure')) {
      return Icons.business;
    } else if (name.contains('scholarship')) {
      return Icons.card_giftcard;
    } else if (name.contains('vocational') || name.contains('training')) {
      return Icons.work;
    } else if (name.contains('usd') || name.contains('eur') || name.contains('gbp')) {
      return Icons.currency_exchange;
    } else if (name.contains('crypto')) {
      return Icons.currency_bitcoin;
    }
    return Icons.inventory;
  }
}
