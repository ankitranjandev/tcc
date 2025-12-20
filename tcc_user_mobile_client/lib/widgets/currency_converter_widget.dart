import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../services/currency_service.dart';
import '../models/currency_rate_model.dart';

class CurrencyConverterWidget extends StatefulWidget {
  const CurrencyConverterWidget({super.key});

  @override
  State<CurrencyConverterWidget> createState() => _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _amountController = TextEditingController(text: '1000');

  String _fromCurrency = 'TCC';
  String _toCurrency = 'USD';
  double? _convertedAmount;
  double? _exchangeRate;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _currencies = [
    {'code': 'TCC', 'name': 'TCC Coin', 'symbol': 'TCC'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': '₵'},
  ];

  @override
  void initState() {
    super.initState();
    _convertCurrency();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convertCurrency() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _convertedAmount = null;
        _exchangeRate = null;
        _errorMessage = null;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
        _convertedAmount = null;
        _exchangeRate = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _currencyService.convertCurrency(
        from: _fromCurrency,
        to: _toCurrency,
        amount: amount,
      );

      if (result['success'] == true) {
        final conversion = result['data'] as CurrencyConversion;
        setState(() {
          _convertedAmount = conversion.convertedAmount;
          _exchangeRate = conversion.rate;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to convert currency';
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

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Currency Converter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          // From Currency
          _buildCurrencyInput(
            label: 'From',
            selectedCurrency: _fromCurrency,
            onCurrencyChanged: (value) {
              setState(() {
                _fromCurrency = value!;
              });
              _convertCurrency();
            },
            controller: _amountController,
            onAmountChanged: (value) {
              _convertCurrency();
            },
          ),

          SizedBox(height: 12),

          // Swap button
          Center(
            child: InkWell(
              onTap: _swapCurrencies,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_vert,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // To Currency
          _buildCurrencyOutput(
            label: 'To',
            selectedCurrency: _toCurrency,
            onCurrencyChanged: (value) {
              setState(() {
                _toCurrency = value!;
              });
              _convertCurrency();
            },
            amount: _convertedAmount,
          ),

          // Exchange rate display
          if (_exchangeRate != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1 $_fromCurrency = ${NumberFormat('#,##0.0000').format(_exchangeRate)} $_toCurrency',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error message
          if (_errorMessage != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required String selectedCurrency,
    required ValueChanged<String?> onCurrencyChanged,
    required TextEditingController controller,
    required ValueChanged<String> onAmountChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                  onChanged: onAmountChanged,
                ),
              ),
              SizedBox(width: 12),
              _buildCurrencyDropdown(selectedCurrency, onCurrencyChanged),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOutput({
    required String label,
    required String selectedCurrency,
    required ValueChanged<String?> onCurrencyChanged,
    required double? amount,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  amount != null ? NumberFormat('#,##0.00').format(amount) : '0.00',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 12),
              _buildCurrencyDropdown(selectedCurrency, onCurrencyChanged),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown(String selectedCurrency, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: selectedCurrency,
        underline: SizedBox(),
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, size: 20),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        items: _currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency['code'],
            child: Text(
              currency['code']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
