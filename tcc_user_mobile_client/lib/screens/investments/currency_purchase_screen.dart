import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/currency_investment_model.dart';
import '../../services/currency_investment_service.dart';
import '../../providers/auth_provider.dart';

class CurrencyPurchaseScreen extends StatefulWidget {
  final String currencyCode;
  final CurrencyInfo? currencyInfo;

  const CurrencyPurchaseScreen({
    super.key,
    required this.currencyCode,
    this.currencyInfo,
  });

  @override
  State<CurrencyPurchaseScreen> createState() => _CurrencyPurchaseScreenState();
}

class _CurrencyPurchaseScreenState extends State<CurrencyPurchaseScreen> {
  final CurrencyInvestmentService _service = CurrencyInvestmentService();
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CurrencyInfo? _currency;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  double _tccAmount = 0;
  double _currencyAmount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.currencyInfo != null) {
      _currency = widget.currencyInfo;
      _isLoading = false;
    } else {
      _loadCurrencyInfo();
    }
    _amountController.addListener(_updateConversion);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyInfo() async {
    try {
      final currencies = await _service.getAvailableCurrenciesTyped();
      final currency = currencies.firstWhere(
        (c) => c.code == widget.currencyCode,
        orElse: () => throw Exception('Currency not found'),
      );
      setState(() {
        _currency = currency;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load currency info';
        _isLoading = false;
      });
    }
  }

  void _updateConversion() {
    if (_currency == null) return;
    final text = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(text) ?? 0;
    setState(() {
      _tccAmount = amount;
      _currencyAmount = _service.calculateCurrencyAmount(amount, _currency!.rate);
    });
  }

  Future<void> _purchaseCurrency() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currency == null) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.buyCurrency(
        currencyCode: widget.currencyCode,
        tccAmount: _tccAmount,
      );

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
          _errorMessage = _parseError(response['error']?.toString() ?? 'Purchase failed');
          _isPurchasing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isPurchasing = false;
      });
    }
  }

  String _parseError(String error) {
    if (error.contains('INSUFFICIENT_BALANCE')) {
      return 'Insufficient wallet balance. Please add funds.';
    }
    if (error.contains('MINIMUM_INVESTMENT')) {
      return 'Amount is below minimum investment limit.';
    }
    if (error.contains('MAXIMUM_INVESTMENT')) {
      return 'Amount exceeds maximum investment limit.';
    }
    return error;
  }

  void _showSuccessDialog(Map<String, dynamic>? data) {
    final investment = data?['investment'] as Map<String, dynamic>?;
    final currencyAmount = investment?['currency_amount']?.toDouble() ?? _currencyAmount;

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
              'Purchase Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You bought ${currencyAmount.toStringAsFixed(2)} ${widget.currencyCode}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'for ${_tccAmount.toStringAsFixed(2)} TCC',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/investments/currency/holdings');
            },
            child: Text('View Holdings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = context.watch<AuthProvider>().user?.walletBalance ?? 0;

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
          'Buy ${widget.currencyCode}',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.warning))
          : _currency == null
              ? _buildErrorState(context)
              : _buildPurchaseForm(context, walletBalance),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(_errorMessage ?? 'Currency not found'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseForm(BuildContext context, double walletBalance) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency info card
            _buildCurrencyInfoCard(context),
            SizedBox(height: 24),

            // Wallet balance
            _buildWalletBalanceCard(context, walletBalance),
            SizedBox(height: 24),

            // Amount input
            Text(
              'Investment Amount (TCC)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: 'TCC ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warning, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount < _currency!.minInvestment) {
                  return 'Minimum investment is ${_currency!.minInvestment.toStringAsFixed(0)} TCC';
                }
                if (amount > _currency!.maxInvestment) {
                  return 'Maximum investment is ${_currency!.maxInvestment.toStringAsFixed(0)} TCC';
                }
                if (amount > walletBalance) {
                  return 'Insufficient balance';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${_currency!.minInvestment.toStringAsFixed(0)} TCC',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Max: ${_currency!.maxInvestment.toStringAsFixed(0)} TCC',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Quick amount buttons
            _buildQuickAmountButtons(walletBalance),
            SizedBox(height: 24),

            // Conversion preview
            if (_tccAmount > 0) _buildConversionPreview(context),
            SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
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
            SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPurchasing || _tccAmount <= 0 ? null : _purchaseCurrency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPurchasing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Buy ${widget.currencyCode}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyInfoCard(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_currency!.flagEmoji, style: TextStyle(fontSize: 28)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currency!.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Current Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '1 TCC',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '= ${_currency!.rate.toStringAsFixed(4)} ${_currency!.code}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceCard(BuildContext context, double balance) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'TCC ${balance.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildQuickAmountButtons(double walletBalance) {
    final quickAmounts = [100.0, 500.0, 1000.0, 5000.0];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickAmounts.map((amount) {
        final isDisabled = amount > walletBalance;
        return InkWell(
          onTap: isDisabled
              ? null
              : () {
                  _amountController.text = amount.toStringAsFixed(0);
                },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey[100] : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDisabled ? Colors.grey[300]! : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'TCC ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDisabled ? Colors.grey[400] : AppColors.warning,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConversionPreview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
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
                '${_currencyAmount.toStringAsFixed(4)} ${widget.currencyCode}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rate', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(
                '1 TCC = ${_currency!.rate.toStringAsFixed(4)} ${widget.currencyCode}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
