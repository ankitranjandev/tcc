import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';

class WithdrawInvestmentScreen extends StatefulWidget {
  const WithdrawInvestmentScreen({super.key});

  @override
  State<WithdrawInvestmentScreen> createState() => _WithdrawInvestmentScreenState();
}

class _WithdrawInvestmentScreenState extends State<WithdrawInvestmentScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Withdraw',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Investment Header
              Row(
                children: [
                  Icon(Icons.wallet, size: 48, color: AppColors.secondaryYellow),
                  SizedBox(width: 16),
                  Text(
                    'Gold',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  Spacer(),
                  Chip(
                    label: Text('Minerals'),
                    backgroundColor: AppColors.secondaryYellow.withValues(alpha: 0.2),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Quantity
              Text('Qty', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
              Text('100 gms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              SizedBox(height: 24),

              // Total Amount
              Text(
                'Total Amount to be withdrawn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                currencyFormat.format(45688),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              Spacer(),

              // Transfer To Section
              Text(
                'Transfer ${currencyFormat.format(45000)} to',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 16),

              // Bank Selection
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'VISA',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  title: Text('HDFC Bank'),
                  subtitle: Text('********2193'),
                  trailing: Icon(Icons.keyboard_arrow_down),
                  onTap: () {},
                ),
              ),

              SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/withdraw-agreement'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue',
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
