import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By downloading, installing, or using the TCC mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use the App.\n\n'
              'These Terms constitute a legally binding agreement between you and TCC Financial Services Limited ("TCC", "we", "us", or "our"). We reserve the right to modify these Terms at any time, and such modifications will be effective immediately upon posting in the App.',
            ),
            _buildSection(
              context,
              '2. Eligibility',
              '2.1 You must be at least 18 years of age to use our services.\n\n'
              '2.2 You must be a legal resident of Sierra Leone or an authorized jurisdiction where TCC operates.\n\n'
              '2.3 You must provide accurate, current, and complete information during registration and keep your account information updated.\n\n'
              '2.4 You must complete our Know Your Customer (KYC) verification process to access full features of the App.',
            ),
            _buildSection(
              context,
              '3. Account Registration and Security',
              '3.1 You are responsible for maintaining the confidentiality of your account credentials, including your password and PIN.\n\n'
              '3.2 You agree to notify TCC immediately of any unauthorized access to or use of your account.\n\n'
              '3.3 You are solely responsible for all activities that occur under your account.\n\n'
              '3.4 TCC reserves the right to suspend or terminate your account if we suspect fraudulent activity or violation of these Terms.\n\n'
              '3.5 You must not share your account credentials with any third party or allow others to access your account.',
            ),
            _buildSection(
              context,
              '4. Financial Services',
              '4.1 Digital Wallet Services\n'
              '• TCC provides digital wallet services for storing, sending, and receiving funds.\n'
              '• All transactions are subject to applicable fees as disclosed in the App.\n'
              '• Transaction limits may apply based on your verification level.\n\n'
              '4.2 Bill Payment Services\n'
              '• TCC facilitates bill payments to registered billers and service providers.\n'
              '• You are responsible for ensuring the accuracy of payment details.\n'
              '• Completed payments cannot be reversed unless authorized by the recipient.\n\n'
              '4.3 Investment Services\n'
              '• TCC offers investment products including but not limited to fixed deposits and currency holdings.\n'
              '• Past performance does not guarantee future results.\n'
              '• All investments carry inherent risks, and you may lose some or all of your investment.\n'
              '• Investment terms and returns are subject to market conditions and applicable regulations.\n\n'
              '4.4 Currency Exchange\n'
              '• Exchange rates are determined by prevailing market rates and may fluctuate.\n'
              '• TCC reserves the right to apply spreads and fees to currency exchange transactions.',
            ),
            _buildSection(
              context,
              '5. Fees and Charges',
              '5.1 You agree to pay all applicable fees for services used through the App.\n\n'
              '5.2 Fee schedules are available within the App and may be updated from time to time.\n\n'
              '5.3 Fees will be deducted automatically from your wallet balance or specified payment method.\n\n'
              '5.4 All fees are non-refundable unless otherwise stated or required by law.',
            ),
            _buildSection(
              context,
              '6. Prohibited Activities',
              'You agree NOT to use the App for:\n\n'
              '• Money laundering, terrorist financing, or any illegal financial activities\n'
              '• Fraudulent transactions or identity theft\n'
              '• Circumventing any security measures or access controls\n'
              '• Transmitting viruses, malware, or harmful code\n'
              '• Interfering with the operation of the App or TCC\'s systems\n'
              '• Violating any applicable laws, regulations, or third-party rights\n'
              '• Creating multiple accounts for fraudulent purposes\n'
              '• Conducting unauthorized commercial activities through the App',
            ),
            _buildSection(
              context,
              '7. Intellectual Property',
              '7.1 The App, including its design, features, content, and underlying technology, is owned by TCC and protected by intellectual property laws.\n\n'
              '7.2 You are granted a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes.\n\n'
              '7.3 You may not copy, modify, distribute, sell, or lease any part of the App without our prior written consent.',
            ),
            _buildSection(
              context,
              '8. Privacy and Data Protection',
              '8.1 Your use of the App is subject to our Privacy Policy, which is incorporated into these Terms by reference.\n\n'
              '8.2 By using the App, you consent to the collection, use, and disclosure of your personal information as described in our Privacy Policy.\n\n'
              '8.3 We implement appropriate security measures to protect your data, but cannot guarantee absolute security.',
            ),
            _buildSection(
              context,
              '9. Disclaimers and Limitation of Liability',
              '9.1 THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.\n\n'
              '9.2 TCC DOES NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE.\n\n'
              '9.3 TO THE MAXIMUM EXTENT PERMITTED BY LAW, TCC SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES.\n\n'
              '9.4 OUR TOTAL LIABILITY FOR ANY CLAIMS ARISING FROM YOUR USE OF THE APP SHALL NOT EXCEED THE FEES PAID BY YOU IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM.',
            ),
            _buildSection(
              context,
              '10. Indemnification',
              'You agree to indemnify, defend, and hold harmless TCC, its officers, directors, employees, and agents from any claims, damages, losses, or expenses (including reasonable legal fees) arising from:\n\n'
              '• Your use of the App\n'
              '• Your violation of these Terms\n'
              '• Your violation of any applicable laws or regulations\n'
              '• Your infringement of any third-party rights',
            ),
            _buildSection(
              context,
              '11. Dispute Resolution',
              '11.1 Any disputes arising from these Terms or your use of the App shall first be attempted to be resolved through good faith negotiation.\n\n'
              '11.2 If negotiation fails, disputes shall be submitted to binding arbitration in Freetown, Sierra Leone.\n\n'
              '11.3 These Terms shall be governed by and construed in accordance with the laws of Sierra Leone.',
            ),
            _buildSection(
              context,
              '12. Termination',
              '12.1 You may terminate your account at any time by contacting TCC support.\n\n'
              '12.2 TCC may suspend or terminate your account for violation of these Terms or for any reason at our discretion.\n\n'
              '12.3 Upon termination, your right to use the App will cease immediately.\n\n'
              '12.4 Any outstanding obligations or liabilities will survive termination.',
            ),
            _buildSection(
              context,
              '13. Regulatory Compliance',
              '13.1 TCC operates in compliance with applicable financial regulations and is licensed by relevant regulatory authorities in Sierra Leone.\n\n'
              '13.2 We cooperate with law enforcement and regulatory bodies as required by law.\n\n'
              '13.3 You agree to comply with all applicable anti-money laundering (AML) and know your customer (KYC) requirements.',
            ),
            _buildSection(
              context,
              '14. Contact Information',
              'For questions or concerns regarding these Terms, please contact us:\n\n'
              'TCC Financial Services Limited\n'
              'Email: legal@tcc.com\n'
              'Phone: +232 123 456 789\n'
              'Address: Freetown, Sierra Leone',
            ),
            SizedBox(height: 16),
            _buildLastUpdated(context),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gavel,
            color: AppColors.primaryBlue,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please read these terms carefully before using our services.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: 8),
          Text(
            'Last updated: February 2026',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
