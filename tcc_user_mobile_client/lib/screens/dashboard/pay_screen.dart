import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../notifications/notification_screen.dart';
import '../wallet/wallet_screen.dart';
import '../bill_payment/bill_provider_screen.dart';

class PayScreen extends StatelessWidget {
  const PayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pay your bills',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.account_balance_wallet_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WalletScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bill payment banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: AppColors.white,
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Auto-pay',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Pay Bills Instantly',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Manage all your utility bills in one place.\nQuick, secure, and hassle-free.',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Bill Categories
              _buildBillCategory(
                context,
                icon: Icons.flash_on,
                color: Colors.yellow.shade700,
                title: 'Electricity',
                subtitle: 'Pay your electricity bills instantly with auto-pay options.',
                onTap: () => _navigateToBillPayment(context, 'Electricity'),
              ),
              _buildBillCategory(
                context,
                icon: Icons.phone_android,
                color: Colors.purple,
                title: 'Mobile bills',
                subtitle: 'Recharge or pay postpaid bills for all operators.',
                onTap: () => _navigateToBillPayment(context, 'Mobile'),
              ),
              _buildBillCategory(
                context,
                icon: Icons.water_drop,
                color: Colors.blue,
                title: 'Water bills',
                subtitle: 'Quick water bill payments for your municipality.',
                onTap: () => _navigateToBillPayment(context, 'Water'),
              ),
              _buildBillCategory(
                context,
                icon: Icons.satellite_alt,
                color: Colors.grey,
                title: 'DTH',
                subtitle: 'Recharge your DTH connection for uninterrupted entertainment.',
                onTap: () => _navigateToBillPayment(context, 'DTH'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillCategory(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToBillPayment(BuildContext context, String billType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillProviderScreen(billType: billType),
      ),
    );
  }
}
