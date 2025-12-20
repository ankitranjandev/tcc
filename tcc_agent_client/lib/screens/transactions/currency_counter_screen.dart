import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

class CurrencyCounterScreen extends StatefulWidget {
  const CurrencyCounterScreen({super.key});

  @override
  State<CurrencyCounterScreen> createState() => _CurrencyCounterScreenState();
}

class _CurrencyCounterScreenState extends State<CurrencyCounterScreen> {
  final Map<int, int> _denominationCounts = {};
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each denomination
    for (var denomination in AppConstants.currencyDenominations) {
      _controllers[denomination] = TextEditingController(text: '0');
      _denominationCounts[denomination] = 0;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    _denominationCounts.forEach((denomination, count) {
      total += denomination * count;
    });
    return total;
  }

  void _updateCount(int denomination, String value) {
    setState(() {
      _denominationCounts[denomination] = int.tryParse(value) ?? 0;
    });
  }

  void _incrementCount(int denomination) {
    setState(() {
      _denominationCounts[denomination] = (_denominationCounts[denomination] ?? 0) + 1;
      _controllers[denomination]?.text = _denominationCounts[denomination].toString();
    });
  }

  void _decrementCount(int denomination) {
    setState(() {
      final currentCount = _denominationCounts[denomination] ?? 0;
      if (currentCount > 0) {
        _denominationCounts[denomination] = currentCount - 1;
        _controllers[denomination]?.text = _denominationCounts[denomination].toString();
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (var denomination in AppConstants.currencyDenominations) {
        _denominationCounts[denomination] = 0;
        _controllers[denomination]?.text = '0';
      }
    });
  }

  void _handleContinue() {
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter amount to add'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Navigate to confirmation screen
    context.push('/transaction-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Count Cash'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Amount Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrangeLight,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TCC${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Denomination List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppConstants.currencyDenominations.length,
              itemBuilder: (context, index) {
                final denomination = AppConstants.currencyDenominations[index];
                return _buildDenominationCard(denomination);
              },
            ),
          ),

          // Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationCard(int denomination) {
    final count = _denominationCounts[denomination] ?? 0;
    final subtotal = denomination * count;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Denomination Info
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'SLL',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$denomination',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Counter Controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decrement Button
                      IconButton(
                        onPressed: () => _decrementCount(denomination),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.errorRed,
                        iconSize: 32,
                      ),

                      // Count Input
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _controllers[denomination],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _updateCount(denomination, value),
                        ),
                      ),

                      // Increment Button
                      IconButton(
                        onPressed: () => _incrementCount(denomination),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.successGreen,
                        iconSize: 32,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Subtotal
                  Center(
                    child: Text(
                      'Subtotal: SLL ${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
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
}
