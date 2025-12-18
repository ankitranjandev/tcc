import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/investment_model.dart';
import '../bill_payment/payment_method_screen.dart';

class InvestmentProductDetailScreen extends StatefulWidget {
  final InvestmentProduct product;

  const InvestmentProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<InvestmentProductDetailScreen> createState() => _InvestmentProductDetailScreenState();
}

class _InvestmentProductDetailScreenState extends State<InvestmentProductDetailScreen> {
  double _quantity = 1;
  double _period = 12; // in months
  bool _includeInsurance = false;
  bool _agreeToTerms = false;

  final double _minQuantity = 1;
  final double _maxQuantity = 12;
  final double _minPeriod = 6; // 6 months
  final double _maxPeriod = 24; // 2 years

  Color get _categoryColor {
    switch (widget.product.category.toUpperCase()) {
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

  double get _totalInvestment {
    return widget.product.price * _quantity;
  }

  double get _expectedReturn {
    final periodInYears = _period / 12;
    final returnAmount = _totalInvestment * (widget.product.roi / 100) * periodInYears;
    return _totalInvestment + returnAmount;
  }

  double get _profit {
    return _expectedReturn - _totalInvestment;
  }

  double get _profitPercentage {
    return (_profit / _totalInvestment) * 100;
  }

  @override
  void initState() {
    super.initState();
    _period = widget.product.minPeriod.toDouble().clamp(_minPeriod, _maxPeriod);
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
          widget.product.name,
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
              widget.product.category,
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
              // Product icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getProductIcon(),
                  color: _categoryColor,
                  size: 40,
                ),
              ),
              SizedBox(height: 24),

              // Price
              Text(
                'Le ${widget.product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                'per ${widget.product.unit.toLowerCase()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                widget.product.description,
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
                      '${widget.product.roi.toStringAsFixed(1)}%',
                      'ROI',
                      AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      '1 ${widget.product.unit}',
                      'Min ${widget.product.unit}',
                      AppColors.secondaryYellow,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      '${widget.product.minPeriod} months',
                      'Min Period',
                      AppColors.secondaryGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),

              // Return Calculator
              Text(
                'Return Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 24),

              // Quantity Slider
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
                      '${widget.product.unit} Quantity',
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_quantity.toInt()} ${widget.product.unit}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Le ${_totalInvestment.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.secondaryYellow,
                        inactiveTrackColor: Theme.of(context).dividerColor,
                        thumbColor: AppColors.secondaryYellow,
                        overlayColor: AppColors.secondaryYellow.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _quantity,
                        min: _minQuantity,
                        max: _maxQuantity,
                        divisions: (_maxQuantity - _minQuantity).toInt(),
                        onChanged: (value) {
                          setState(() {
                            _quantity = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_minQuantity.toInt()} ${widget.product.unit.toLowerCase()}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        Text(
                          '${_maxQuantity.toInt()} ${widget.product.unit.toLowerCase()}s',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Period Slider
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
                      'Period',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${(_period / 12).toStringAsFixed(1)} year${_period >= 24 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.secondaryYellow,
                        inactiveTrackColor: Theme.of(context).dividerColor,
                        thumbColor: AppColors.secondaryYellow,
                        overlayColor: AppColors.secondaryYellow.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _period,
                        min: _minPeriod,
                        max: _maxPeriod,
                        divisions: ((_maxPeriod - _minPeriod) / 6).toInt(),
                        onChanged: (value) {
                          setState(() {
                            _period = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_minPeriod / 12).toStringAsFixed(0)} months',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        Text(
                          '${(_maxPeriod / 12).toStringAsFixed(0)} years',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
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
                      'Total Investment of Le ${_totalInvestment.toStringAsFixed(0)} after ${(_period / 12).toStringAsFixed(1)} year${_period >= 24 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'You will get a return of ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          'Le ${_expectedReturn.toStringAsFixed(0)}',
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
                          '${_profitPercentage.toStringAsFixed(1)}%',
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
                  onPressed: () {
                    _showInvestmentConfirmation(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Invest',
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

  IconData _getProductIcon() {
    final name = widget.product.name.toLowerCase();
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

  void _showInvestmentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to invest:'),
                SizedBox(height: 16),
                _buildConfirmationRow('Product', widget.product.name),
                _buildConfirmationRow('Quantity', '${_quantity.toInt()} ${widget.product.unit}'),
                _buildConfirmationRow('Period', '${(_period / 12).toStringAsFixed(1)} year${_period >= 24 ? 's' : ''}'),
                _buildConfirmationRow('Investment', 'Le ${_totalInvestment.toStringAsFixed(0)}'),
                if (_includeInsurance)
                  _buildConfirmationRow('Insurance', 'Le ${(_totalInvestment * 0.02).toStringAsFixed(0)}'),
                _buildConfirmationRow(
                  'Expected Return',
                  'Le ${_expectedReturn.toStringAsFixed(0)}',
                  isHighlight: true
                ),

                SizedBox(height: 20),

                // Insurance Option
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
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
                              'with a small insurance fee (2%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
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

                // Terms and Conditions Agreement
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
                              color: Theme.of(context).textTheme.bodySmall?.color,
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
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Investment Policy',
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
                // Reset state when canceling
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

  Widget _buildConfirmationRow(String label, String value, {bool isHighlight = false}) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppColors.success : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _processInvestment(BuildContext context) {
    // Calculate total amount including insurance if selected
    final double insuranceAmount = _includeInsurance ? (_totalInvestment * 0.02) : 0;
    final double totalAmount = _totalInvestment + insuranceAmount;

    // Navigate to payment method screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          billType: 'Investment',
          provider: widget.product.name,
          amount: totalAmount,
          accountNumber: 'INV-${widget.product.id}',
        ),
      ),
    );
  }
}
