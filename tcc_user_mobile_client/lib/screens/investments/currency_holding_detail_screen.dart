import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/currency_investment_model.dart';
import '../../services/currency_investment_service.dart';

class CurrencyHoldingDetailScreen extends StatefulWidget {
  final String holdingId;
  final CurrencyInvestment? holding;

  const CurrencyHoldingDetailScreen({
    super.key,
    required this.holdingId,
    this.holding,
  });

  @override
  State<CurrencyHoldingDetailScreen> createState() => _CurrencyHoldingDetailScreenState();
}

class _CurrencyHoldingDetailScreenState extends State<CurrencyHoldingDetailScreen> {
  final CurrencyInvestmentService _service = CurrencyInvestmentService();
  CurrencyInvestment? _holding;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.holding != null) {
      _holding = widget.holding;
      _isLoading = false;
      // Refresh to get latest data
      _loadHolding();
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
          'Holding Details',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodySmall?.color),
            onPressed: _loadHolding,
          ),
        ],
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
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: _loadHolding,
      color: AppColors.warning,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency header card
            _buildHeaderCard(context, holding, isProfitable, profitLossColor),
            SizedBox(height: 24),

            // Purchase details
            Text(
              'Purchase Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailCard(context, [
              _buildDetailRow('Date', dateFormat.format(holding.createdAt)),
              _buildDetailRow('Amount Invested', 'TCC ${holding.amountInvested.toStringAsFixed(2)}'),
              _buildDetailRow('Currency Bought', '${holding.currencyAmount.toStringAsFixed(4)} ${holding.currencyCode}'),
              _buildDetailRow('Purchase Rate', '1 TCC = ${holding.purchaseRate.toStringAsFixed(4)} ${holding.currencyCode}'),
            ]),
            SizedBox(height: 24),

            // Current value
            Text(
              'Current Value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailCard(context, [
              if (holding.currentRate != null)
                _buildDetailRow('Current Rate', '1 TCC = ${holding.currentRate!.toStringAsFixed(4)} ${holding.currencyCode}'),
              _buildDetailRow('Current Value', 'TCC ${holding.calculatedCurrentValue.toStringAsFixed(2)}'),
              _buildDetailRow(
                'Profit/Loss',
                '${isProfitable ? '+' : ''}${holding.calculatedProfitLoss.toStringAsFixed(2)} TCC',
                valueColor: profitLossColor,
              ),
              if (holding.profitLossPercentage != null)
                _buildDetailRow(
                  'Change',
                  '${isProfitable ? '+' : ''}${holding.profitLossPercentage!.toStringAsFixed(2)}%',
                  valueColor: profitLossColor,
                ),
            ]),
            SizedBox(height: 32),

            // Sell button
            if (holding.isActive) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/investments/currency/sell/${holding.id}', extra: holding);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProfitable ? AppColors.success : AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
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
                child: Text(
                  isProfitable
                      ? 'Sell now to lock in your profit'
                      : 'Consider waiting for better rates',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],

            // Sold status
            if (holding.isSold) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sold',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          if (holding.soldAt != null)
                            Text(
                              'on ${dateFormat.format(holding.soldAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (holding.profitLoss != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (holding.profitLoss! >= 0 ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${holding.profitLoss! >= 0 ? '+' : ''}${holding.profitLoss!.toStringAsFixed(2)} TCC',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: holding.profitLoss! >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    CurrencyInvestment holding,
    bool isProfitable,
    Color profitLossColor,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(holding.flagEmoji, style: TextStyle(fontSize: 32)),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      holding.currencyCode,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: holding.isActive
                      ? AppColors.success.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  holding.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Holdings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${holding.currencyAmount.toStringAsFixed(2)} ${holding.currencyCode}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Value',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'TCC ${holding.calculatedCurrentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> rows) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
