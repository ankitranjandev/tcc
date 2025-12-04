import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../notifications/notification_screen.dart';

class GiftScreen extends StatelessWidget {
  const GiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gift',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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

              SizedBox(height: 24),

              // Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade200, Colors.pink.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sending gift is\nnow easy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Send Gift Button and Instructions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send Gift',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/send-gift'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('Send'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Instructions
              _buildInstructionTile(1, 'Select the type of gift you want to send - money, airtime, or vouchers.'),
              _buildInstructionTile(2, 'Enter recipient details using their TCC ID or mobile number.'),
              _buildInstructionTile(3, 'Choose the amount and add a personal message if desired.'),
              _buildInstructionTile(4, 'Review and confirm to send your gift instantly.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionTile(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '0$number',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
