import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add money to my wallet?',
      'answer': 'To add money to your TCC wallet:\n\n'
          '1. Go to the Wallet tab\n'
          '2. Tap "Add Money" or the + button\n'
          '3. Enter the amount you want to add\n'
          '4. Choose your payment method (card or Apple Pay)\n'
          '5. Complete the secure payment\n\n'
          'Your wallet balance will be updated immediately after successful payment.',
    },
    {
      'question': 'How do I send money to someone?',
      'answer': 'To send money to another TCC user:\n\n'
          '1. Go to the Pay tab\n'
          '2. Enter the recipient\'s phone number or select from contacts\n'
          '3. Enter the amount to send\n'
          '4. Review the details and tap "Send"\n'
          '5. Enter the OTP sent to your phone\n\n'
          'The recipient will receive the funds instantly in their TCC wallet.',
    },
    {
      'question': 'What is KYC verification?',
      'answer': 'KYC (Know Your Customer) verification is required to:\n\n'
          '• Make investments\n'
          '• Send larger amounts\n'
          '• Withdraw funds to bank accounts\n\n'
          'To complete KYC:\n'
          '1. Go to Profile > Complete KYC\n'
          '2. Upload a valid government ID (front and back)\n'
          '3. Take a selfie for verification\n'
          '4. Wait for approval (usually within 24 hours)\n\n'
          'Your documents are securely stored and only used for verification.',
    },
    {
      'question': 'How do investments work?',
      'answer': 'TCC offers various investment opportunities:\n\n'
          '• Agriculture investments\n'
          '• Education investments\n'
          '• Currency investments\n\n'
          'To invest:\n'
          '1. Go to Investments from the home screen\n'
          '2. Browse available investment categories\n'
          '3. Select a product and choose your investment amount\n'
          '4. Review expected returns and tenure\n'
          '5. Confirm your investment\n\n'
          '⚠️ All investments carry risk. Past performance does not guarantee future results.',
    },
    {
      'question': 'How do I withdraw money?',
      'answer': 'To withdraw funds from your TCC wallet:\n\n'
          '1. Go to Wallet > Withdraw\n'
          '2. Select your linked bank account\n'
          '3. Enter the amount to withdraw\n'
          '4. Confirm with OTP verification\n\n'
          'Bank transfers typically take 1-3 business days to complete.',
    },
    {
      'question': 'Is my money safe?',
      'answer': 'Yes, TCC takes security seriously:\n\n'
          '• All transactions are encrypted\n'
          '• 3D Secure authentication for card payments\n'
          '• OTP verification for sensitive actions\n'
          '• Funds held with licensed financial partners\n'
          '• Regular security audits\n\n'
          'TCC is regulated and compliant with Sierra Leone financial laws.',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'You can reach our support team:\n\n'
          '📧 Email: support@tcc.com\n'
          '📱 Phone: +232 123 456 789\n'
          '💬 WhatsApp: +232 123 456 789\n\n'
          'Support hours: Monday - Friday, 9 AM - 6 PM GMT',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQ'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.help_outline, size: 48, color: AppColors.primaryBlue),
                SizedBox(height: 12),
                Text(
                  'How can we help you?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Find answers to frequently asked questions below',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // FAQ List
          ...List.generate(_faqs.length, (index) {
            final faq = _faqs[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  faq['question']!,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                children: [
                  Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 24),

          // Contact Support Button
          ElevatedButton.icon(
            onPressed: () => _launchEmail(),
            icon: Icon(Icons.email_outlined),
            label: Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'support@tcc.com');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
