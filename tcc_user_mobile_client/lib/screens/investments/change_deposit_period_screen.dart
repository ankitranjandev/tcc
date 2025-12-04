import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';

class ChangeDepositPeriodScreen extends StatefulWidget {
  const ChangeDepositPeriodScreen({super.key});

  @override
  State<ChangeDepositPeriodScreen> createState() => _ChangeDepositPeriodScreenState();
}

class _ChangeDepositPeriodScreenState extends State<ChangeDepositPeriodScreen> {
  double _period = 1.0; // in years
  final int _lotQuantity = 8;
  final double _price = 234;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    final totalInvestment = _lotQuantity * _price * _period;
    final expectedReturn = totalInvestment * 1.506; // 50.6% return
    final returnAmount = expectedReturn - totalInvestment;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Change deposit Period'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Investment Header
              Row(
                children: [
                  Icon(Icons.wallet, size: 48, color: Colors.yellow.shade700),
                  SizedBox(width: 16),
                  Text(
                    'Gold',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Chip(
                    label: Text('Minerals'),
                    backgroundColor: Colors.yellow.shade100,
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Lot Quantity Section
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
                      'Lot Quantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            Text(
                              '$_lotQuantity Lot',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Price', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            Text(
                              currencyFormat.format(_price),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Period Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Period',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Min Period',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 100),
                        Text(
                          '6 months',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _period == 1.0 ? '1 year' : '${_period.toInt()} years',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.yellow.shade700,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.yellow.shade700,
                      ),
                      child: Slider(
                        value: _period,
                        min: 0.5,
                        max: 2,
                        divisions: 3,
                        onChanged: (value) => setState(() => _period = value),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('6 months', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                        Text('2 years', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48),

              // Return Calculation
              Text(
                'Total Investment of ${currencyFormat.format(totalInvestment)} after ${_period == 1.0 ? '1 year' : '${_period.toInt()} years'}',
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  children: [
                    TextSpan(text: 'You will get a return of '),
                    TextSpan(
                      text: currencyFormat.format(expectedReturn),
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '+${returnAmount.toInt()}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_upward, size: 16, color: AppColors.success),
                  Text(
                    ' 50.6 %',
                    style: TextStyle(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              SizedBox(height: 48),

              // Change Period Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deposit period changed successfully! (Mock)'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Change Period',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
