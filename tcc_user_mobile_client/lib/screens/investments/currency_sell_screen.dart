import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/currency_investment_model.dart';
import '../../services/currency_investment_service.dart';
import '../../providers/auth_provider.dart';

class CurrencySellScreen extends StatefulWidget {
  final String holdingId;
  final CurrencyInvestment? holding;

  const CurrencySellScreen({
    super.key,
    required this.holdingId,
    this.holding,
  });

  @override
  State<CurrencySellScreen> createState() => _CurrencySellScreenState();
}

class _CurrencySellScreenState extends State<CurrencySellScreen> {
  final CurrencyInvestmentService _service = CurrencyInvestmentService();
  CurrencyInvestment? _holding;
  bool _isLoading = true;
  bool _isSelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.holding != null) {
      _holding = widget.holding;
      _isLoading = false;
      _loadHolding(); // Refresh for latest rates
    } else {
      _loadHolding();
    }
  }

  Future<void> _loadHolding() async {
    try {
      final holding = await _service.getHoldingDetailsTyped(
        investmentId: widget.holdingId,
      );
      if (mounted) {
        setState(() {
          if (holding != null) {
            _holding = holding;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load holding details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sellCurrency() async {
    if (_holding == null) return;

    setState(() {
      _isSelling = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.sellCurrency(investmentId: widget.holdingId);

      if (response['success'] == true) {
        // Refresh user profile to update wallet balance
        if (mounted) {
          context.read<AuthProvider>().loadUserProfile();
        }

        // Show success and navigate
        if (mounted) {
          _showSuccessDialog(response['data']);
        }
      } else {
        setState(() {
          _errorMessage = response['error']?.toString() ?? 'Sale failed';
          _isSelling = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSelling = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic>? data) {
    final sale = data?['sale'] as Map<String, dynamic>?;
    final result = sale != null ? SellCurrencyResult.fromJson(sale) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              'Sale Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (result != null) ...[
              _buildResultRow('Currency Sold', '${result.currencySold.toStringAsFixed(2)} ${result.currencyCode}'),
              _buildResultRow('TCC Received', 'TCC ${result.tccReceived.toStringAsFixed(2)}'),
              Divider(height: 24),
              _buildResultRow(
                result.isProfitable ? 'Profit' : 'Loss',
                '${result.isProfitable ? '+' : ''}${result.profitLoss.toStringAsFixed(2)} TCC (${result.isProfitable ? '+' : ''}${result.profitLossPercentage.toStringAsFixed(2)}%)',
                valueColor: result.isProfitable ? AppColors.success : AppColors.error,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to holdings
              context.go('/investments/currency/holdings');
            },
            child: Text('View Holdings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    if (_holding == null) return;
    final isProfitable = _holding!.isProfitable;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to sell your ${_holding!.currencyCode} holding?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isProfitable ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isProfitable ? 'Estimated Profit' : 'Estimated Loss'),
                  Text(
                    '${isProfitable ? '+' : ''}${_holding!.calculatedProfitLoss.toStringAsFixed(2)} TCC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isProfitable ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sellCurrency();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isProfitable ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm Sale'),
          ),
        ],
      ),
    );
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
          'Sell Currency',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading && _holding == null
          ? Center(child: CircularProgressIndicator(color: AppColors.warning))
          : _holding == null
              ? _buildErrorState(context)
              : _buildContent(context),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(_errorMessage ?? 'Holding not found'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final holding = _holding!;
    final isProfitable = holding.isProfitable;
    final profitLossColor = isProfitable ? AppColors.success : AppColors.error;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning/info banner
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isProfitable ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isProfitable ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isProfitable ? Icons.trending_up : Icons.info_outline,
                  color: isProfitable ? AppColors.success : AppColors.warning,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isProfitable
                        ? 'You\'re in profit! Selling now will lock in your gains.'
                        : 'You\'re currently at a loss. Consider waiting for better rates.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isProfitable ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Currency card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(holding.flagEmoji, style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          Text(
                            holding.currencyCode,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 12),
                _buildInfoRow('You have', '${holding.currencyAmount.toStringAsFixed(4)} ${holding.currencyCode}'),
                SizedBox(height: 8),
                _buildInfoRow('Originally invested', 'TCC ${holding.amountInvested.toStringAsFixed(2)}'),
                SizedBox(height: 8),
                if (holding.currentRate != null)
                  _buildInfoRow('Current rate', '1 TCC = ${holding.currentRate!.toStringAsFixed(4)} ${holding.currencyCode}'),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Sale preview
          Text(
            'Sale Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: profitLossColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: profitLossColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'You will receive',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'TCC ${holding.calculatedCurrentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: profitLossColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isProfitable ? Icons.trending_up : Icons.trending_down,
                        color: profitLossColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${isProfitable ? '+' : ''}${holding.calculatedProfitLoss.toStringAsFixed(2)} TCC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: profitLossColor,
                        ),
                      ),
                      if (holding.profitLossPercentage != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '(${isProfitable ? '+' : ''}${holding.profitLossPercentage!.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 14,
                            color: profitLossColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Sell button
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSelling ? null : _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: profitLossColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSelling
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sell),
                        SizedBox(width: 8),
                        Text(
                          'Sell ${holding.currencyCode}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
