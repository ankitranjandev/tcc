import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/investment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/investment_service.dart';
import '../../widgets/kyc_guard.dart';

/// Screen for displaying investment opportunity details and allowing investment
class InvestmentOpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;

  const InvestmentOpportunityDetailScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  State<InvestmentOpportunityDetailScreen> createState() =>
      _InvestmentOpportunityDetailScreenState();
}

class _InvestmentOpportunityDetailScreenState
    extends State<InvestmentOpportunityDetailScreen> with RequiresKyc {
  final InvestmentService _investmentService = InvestmentService();

  bool _isLoading = true;
  String? _errorMessage;
  InvestmentOpportunity? _opportunity;

  double _investmentAmount = 0;
  bool _includeInsurance = false;
  bool _agreeToTerms = false;

  final NumberFormat _tccFormat =
      NumberFormat.currency(symbol: 'TCC ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOpportunityDetails();
  }

  Future<void> _loadOpportunityDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _investmentService.getOpportunityDetails(
        opportunityId: widget.opportunityId,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _opportunity = InvestmentOpportunity.fromJson(data);
          _investmentAmount = _opportunity!.minInvestment;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load opportunity';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load opportunity: $e';
        _isLoading = false;
      });
    }
  }

  Color get _categoryColor {
    if (_opportunity == null) return AppColors.primaryBlue;

    switch (_opportunity!.categoryName.toUpperCase()) {
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

  IconData get _categoryIcon {
    if (_opportunity == null) return Icons.inventory;

    switch (_opportunity!.categoryName.toUpperCase()) {
      case 'AGRICULTURE':
        return Icons.agriculture;
      case 'MINERALS':
        return Icons.diamond;
      case 'EDUCATION':
        return Icons.school;
      case 'CURRENCY':
        return Icons.currency_exchange;
      default:
        return Icons.inventory;
    }
  }

  double get _expectedReturn {
    if (_opportunity == null) return 0;
    final periodInYears = _opportunity!.tenureMonths / 12;
    final returnAmount =
        _investmentAmount * (_opportunity!.returnRate / 100) * periodInYears;
    return _investmentAmount + returnAmount;
  }

  double get _profit => _expectedReturn - _investmentAmount;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null || _opportunity == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'Opportunity not found',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOpportunityDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _opportunity!.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _opportunity!.categoryDisplayName,
              style: TextStyle(
                color: _categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opportunity icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _categoryIcon,
                  color: _categoryColor,
                  size: 40,
                ),
              ),
              SizedBox(height: 24),

              // Title
              Text(
                _opportunity!.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 8),

              // Min investment
              Text(
                'Min: ${_tccFormat.format(_opportunity!.minInvestment)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _categoryColor,
                ),
              ),
              SizedBox(height: 24),

              // Description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _opportunity!.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),

              // Key metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      '${_opportunity!.returnRate.toStringAsFixed(1)}%',
                      'Return Rate',
                      AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      '${_opportunity!.tenureMonths} mo',
                      'Tenure',
                      AppColors.secondaryYellow,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      '${_opportunity!.availableUnits}',
                      'Available',
                      AppColors.secondaryGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Progress bar for units sold
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Units Sold',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          '${_opportunity!.soldUnits}/${_opportunity!.totalUnits}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _categoryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _opportunity!.soldPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_categoryColor),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Investment Calculator
              Text(
                'Investment Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 24),

              // Amount Slider
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tccFormat.format(_investmentAmount),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.secondaryYellow,
                        inactiveTrackColor: Theme.of(context).dividerColor,
                        thumbColor: AppColors.secondaryYellow,
                        overlayColor:
                            AppColors.secondaryYellow.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _investmentAmount,
                        min: _opportunity!.minInvestment,
                        max: _opportunity!.maxInvestment,
                        divisions:
                            ((_opportunity!.maxInvestment -
                                        _opportunity!.minInvestment) /
                                    1000)
                                .toInt()
                                .clamp(1, 100),
                        onChanged: (value) {
                          setState(() {
                            _investmentAmount = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tccFormat.format(_opportunity!.minInvestment),
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        Text(
                          _tccFormat.format(_opportunity!.maxInvestment),
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Investment Summary
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment of ${_tccFormat.format(_investmentAmount)} for ${_opportunity!.tenureMonths} months',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Expected return: ',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          _tccFormat.format(_expectedReturn),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '+${_profit.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_upward,
                          color: AppColors.success,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${_opportunity!.returnRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Invest Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _opportunity!.hasUnitsAvailable
                      ? () {
                          checkKycAndProceed(() {
                            _showInvestmentConfirmation(context);
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _opportunity!.hasUnitsAvailable ? 'Invest Now' : 'Sold Out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInvestmentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to invest in:'),
                SizedBox(height: 16),
                _buildConfirmationRow('Opportunity', _opportunity!.title),
                _buildConfirmationRow('Category',
                    _opportunity!.categoryDisplayName),
                _buildConfirmationRow(
                    'Amount', _tccFormat.format(_investmentAmount)),
                _buildConfirmationRow(
                    'Tenure', '${_opportunity!.tenureMonths} months'),
                _buildConfirmationRow(
                  'Expected Return',
                  _tccFormat.format(_expectedReturn),
                  isHighlight: true,
                ),
                SizedBox(height: 20),

                // Insurance Option
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: AppColors.success, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure your investment',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'with insurance (2%)',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _includeInsurance,
                        onChanged: (value) {
                          setState(() {
                            _includeInsurance = value;
                          });
                        },
                        activeThumbColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _includeInsurance = false;
                  _agreeToTerms = false;
                });
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _agreeToTerms
                  ? () {
                      Navigator.pop(context);
                      _processInvestment(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? AppColors.success
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processInvestment(BuildContext context) async {
    final double insuranceAmount =
        _includeInsurance ? (_investmentAmount * 0.02) : 0;
    final double totalAmount = _investmentAmount + insuranceAmount;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletBalance = authProvider.user?.walletBalance ?? 0;

    if (walletBalance < totalAmount) {
      _showInsufficientBalanceDialog(context, totalAmount, walletBalance);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing investment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await _investmentService.createInvestment(
        categoryId: _opportunity!.categoryId,
        amount: totalAmount,
        tenureMonths: _opportunity!.tenureMonths,
      );

      if (context.mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (context.mounted) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.loadUserProfile();
        }

        if (context.mounted) {
          _showSuccessDialog(context, totalAmount);
        }
      } else {
        if (context.mounted) {
          _showErrorDialog(context, result['error'] ?? 'Failed to create investment');
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  void _showInsufficientBalanceDialog(
    BuildContext context,
    double required,
    double available,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You don\'t have enough TCC coins for this investment.'),
            SizedBox(height: 16),
            Text('Required: ${_tccFormat.format(required)}'),
            Text('Available: ${_tccFormat.format(available)}'),
            Text(
              'Shortfall: ${_tccFormat.format(required - available)}',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('Add Funds', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Investment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Your investment of ${_tccFormat.format(amount)} has been created successfully.'),
            SizedBox(height: 16),
            Text(
              'You can view your investment in the Portfolio section.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('View Portfolio', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Investment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
