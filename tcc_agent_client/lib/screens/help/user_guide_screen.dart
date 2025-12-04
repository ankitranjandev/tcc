import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class GuideSection {
  final String title;
  final String description;
  final IconData icon;
  final List<GuideStep> steps;

  GuideSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
  });
}

class GuideStep {
  final String title;
  final String description;
  final String? tip;

  GuideStep({
    required this.title,
    required this.description,
    this.tip,
  });
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static final List<GuideSection> _guides = [
    GuideSection(
      title: 'Getting Started',
      description: 'Learn the basics of using the TCC Agent app',
      icon: Icons.rocket_launch,
      steps: [
        GuideStep(
          title: 'Register Your Account',
          description: 'Enter your phone number and complete the OTP verification. Fill in your profile details and wait for admin approval.',
          tip: 'Make sure to provide accurate information for faster approval.',
        ),
        GuideStep(
          title: 'Complete Your Profile',
          description: 'Add your personal information, including name, address, and contact details. Upload a profile photo for better customer trust.',
        ),
        GuideStep(
          title: 'Explore the Dashboard',
          description: 'Familiarize yourself with the dashboard showing your wallet balance, recent transactions, and quick actions.',
        ),
      ],
    ),
    GuideSection(
      title: 'Processing Deposits',
      description: 'Help customers add money to their wallets',
      icon: Icons.add_circle_outline,
      steps: [
        GuideStep(
          title: 'Navigate to Add Money',
          description: 'Tap the "Add Money" tab from the bottom navigation or dashboard quick action.',
        ),
        GuideStep(
          title: 'Select Payment Mode',
          description: 'Choose how the customer will pay: Cash, Bank Transfer, or Mobile Money.',
          tip: 'Cash deposits are processed instantly.',
        ),
        GuideStep(
          title: 'Enter Customer Details',
          description: 'Input the customer\'s phone number, amount, and any additional details required.',
        ),
        GuideStep(
          title: 'Collect Payment',
          description: 'Collect the payment from the customer using the selected method.',
        ),
        GuideStep(
          title: 'Complete Transaction',
          description: 'Confirm and complete the transaction. The customer will receive a confirmation, and you\'ll earn commission.',
        ),
      ],
    ),
    GuideSection(
      title: 'Verifying Payments',
      description: 'How to verify and complete payment orders',
      icon: Icons.verified_user,
      steps: [
        GuideStep(
          title: 'Open Payment Orders',
          description: 'Go to the "Payment Orders" tab to see pending orders.',
        ),
        GuideStep(
          title: 'Select an Order',
          description: 'Tap on an order to view its details, including amount and customer information.',
        ),
        GuideStep(
          title: 'Get Verification Code',
          description: 'Ask the customer to provide their 6-digit verification code.',
          tip: 'Never share your own verification codes with customers.',
        ),
        GuideStep(
          title: 'Verify Customer',
          description: 'Enter the code and verify the customer\'s identity. You can also scan their QR code for faster verification.',
        ),
        GuideStep(
          title: 'Complete Payment',
          description: 'After verification, hand over the cash to the customer and complete the order.',
        ),
      ],
    ),
    GuideSection(
      title: 'Paying Bills',
      description: 'Process bill payments for customers',
      icon: Icons.receipt_long,
      steps: [
        GuideStep(
          title: 'Access Bill Payment',
          description: 'Tap "Bill Payment" from the dashboard or navigation menu.',
        ),
        GuideStep(
          title: 'Select Bill Type',
          description: 'Choose the type of bill: Water, Electricity, DSTV, or Others.',
        ),
        GuideStep(
          title: 'Enter Bill Details',
          description: 'Input the bill account number, customer name, and amount to pay.',
        ),
        GuideStep(
          title: 'Choose Payment Method',
          description: 'Select how the customer will pay: Wallet, Bank, or Mobile Money.',
        ),
        GuideStep(
          title: 'Confirm and Pay',
          description: 'Review all details and confirm the payment. Customer will receive a receipt.',
        ),
      ],
    ),
    GuideSection(
      title: 'Voting in Elections',
      description: 'Participate in community elections',
      icon: Icons.how_to_vote,
      steps: [
        GuideStep(
          title: 'View Elections',
          description: 'Tap "Elections" to see all open and closed elections.',
        ),
        GuideStep(
          title: 'Select an Election',
          description: 'Choose an election you want to participate in.',
        ),
        GuideStep(
          title: 'Review Options',
          description: 'Read the question and all available options carefully.',
          tip: 'You cannot change your vote once submitted.',
        ),
        GuideStep(
          title: 'Cast Your Vote',
          description: 'Select your preferred option and confirm. The voting charge will be deducted from your wallet.',
        ),
        GuideStep(
          title: 'View Results',
          description: 'After voting or when the election closes, you can view the results.',
        ),
      ],
    ),
    GuideSection(
      title: 'Managing Your Wallet',
      description: 'Check balance and track commissions',
      icon: Icons.account_balance_wallet,
      steps: [
        GuideStep(
          title: 'View Wallet Balance',
          description: 'Your current balance is displayed on the dashboard. Tap to see detailed breakdown.',
        ),
        GuideStep(
          title: 'Track Commissions',
          description: 'View your commission earnings from the Commissions tab. Filter by date to see historical data.',
        ),
        GuideStep(
          title: 'Request Withdrawal',
          description: 'When ready to withdraw, go to Wallet and select "Withdraw". Enter amount and confirm.',
          tip: 'Minimum withdrawal is SLL 50,000.',
        ),
      ],
    ),
    GuideSection(
      title: 'Using QR Codes',
      description: 'Scan and generate QR codes for faster transactions',
      icon: Icons.qr_code_scanner,
      steps: [
        GuideStep(
          title: 'Scan Customer QR',
          description: 'Tap the QR icon and allow camera access. Point at customer\'s QR code to scan.',
        ),
        GuideStep(
          title: 'Generate Your QR',
          description: 'Show your QR code to customers for quick identification and verification.',
        ),
        GuideStep(
          title: 'Verify with QR',
          description: 'For payment orders, you can scan the customer\'s verification QR instead of entering the code manually.',
        ),
      ],
    ),
    GuideSection(
      title: 'Troubleshooting',
      description: 'Common issues and solutions',
      icon: Icons.build,
      steps: [
        GuideStep(
          title: 'Transaction Failed',
          description: 'Check internet connection and retry. If issue persists, contact support with transaction ID.',
        ),
        GuideStep(
          title: 'App Running Slow',
          description: 'Go to Settings > Clear Cache. This will remove temporary files and improve performance.',
          tip: 'Clear cache regularly for optimal performance.',
        ),
        GuideStep(
          title: 'Cannot Login',
          description: 'Verify your phone number is correct. Request a new OTP if the current one expired.',
        ),
        GuideStep(
          title: 'Missing Commission',
          description: 'Commissions are credited instantly. Check your commission history. Contact support if amount is incorrect.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _guides.length,
        itemBuilder: (context, index) {
          return _buildGuideCard(context, _guides[index]);
        },
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, GuideSection guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideDetailScreen(guide: guide),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  guide.icon,
                  color: AppColors.primaryOrange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${guide.steps.length} steps',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail screen for a specific guide
class GuideDetailScreen extends StatelessWidget {
  final GuideSection guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  guide.icon,
                  size: 48,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Steps
          ...guide.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildStepCard(step, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildStepCard(GuideStep step, int stepNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (step.tip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tip',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.tip!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
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
}
