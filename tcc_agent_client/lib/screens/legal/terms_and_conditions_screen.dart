import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Terms and Conditions',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLastUpdated(),
              const SizedBox(height: 20),
              _buildSection('1. Acceptance of Terms', '''
By registering for and using the TCC Agent services, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.
              '''),
              _buildSection('2. Agent Registration', '''
To become a TCC Agent, you must:
• Be at least 18 years of age
• Provide accurate and complete registration information
• Complete the KYC (Know Your Customer) verification process
• Maintain the confidentiality of your account credentials
• Notify us immediately of any unauthorized use of your account
              '''),
              _buildSection('3. KYC Verification Requirements', '''
As part of our compliance with regulatory requirements, all agents must:
• Submit valid government-issued identification documents
• Provide proof of address
• Submit bank account details for commission payments
• Keep all submitted information current and accurate
• Cooperate with periodic re-verification requests
              '''),
              _buildSection('4. Agent Responsibilities', '''
As a TCC Agent, you agree to:
• Conduct all transactions honestly and transparently
• Maintain accurate records of all transactions
• Comply with all applicable laws and regulations
• Protect customer information and maintain confidentiality
• Report any suspicious activities immediately
• Not engage in any fraudulent or illegal activities
              '''),
              _buildSection('5. Commission and Payments', '''
• Commission rates are determined by TCC and may vary based on transaction type
• Commissions are calculated based on successfully completed transactions
• Payments will be made to your registered bank account
• TCC reserves the right to withhold payments pending investigation of any irregularities
• You are responsible for any taxes on commission earned
              '''),
              _buildSection('6. Service Standards', '''
Agents must maintain high service standards including:
• Professional conduct at all times
• Timely response to customer queries
• Accurate processing of transactions
• Proper maintenance of float balance
• Regular availability during business hours
              '''),
              _buildSection('7. Prohibited Activities', '''
The following activities are strictly prohibited:
• Money laundering or terrorist financing
• Fraudulent transactions or misrepresentation
• Sharing account credentials with others
• Unauthorized modifications to the app
• Using the service for illegal activities
• Discrimination against customers
• Charging customers additional unauthorized fees
              '''),
              _buildSection('8. Account Suspension and Termination', '''
TCC reserves the right to suspend or terminate your agent account if:
• You violate any of these terms and conditions
• You provide false or misleading information
• You engage in fraudulent activities
• You fail to maintain required service standards
• Required by law or regulatory authorities
              '''),
              _buildSection('9. Liability and Indemnification', '''
• TCC is not liable for any indirect, incidental, or consequential damages
• You agree to indemnify TCC against any claims arising from your use of the service
• TCC's total liability shall not exceed the commissions earned in the past 3 months
• You are responsible for any losses due to negligence or misconduct
              '''),
              _buildSection('10. Data Protection and Privacy', '''
• We collect and process your data in accordance with our Privacy Policy
• You must protect customer data and use it only for authorized purposes
• You must comply with all applicable data protection laws
• Any data breach must be reported immediately
              '''),
              _buildSection('11. Intellectual Property', '''
• All TCC trademarks, logos, and content remain our property
• You are granted a limited license to use our materials for authorized purposes
• You may not modify, copy, or distribute our intellectual property
• Any feedback or suggestions you provide become TCC property
              '''),
              _buildSection('12. Dispute Resolution', '''
• Any disputes will first be attempted to be resolved through good faith negotiations
• If negotiations fail, disputes will be resolved through binding arbitration
• The arbitration will be conducted in accordance with local laws
• Each party will bear their own costs unless otherwise determined
              '''),
              _buildSection('13. Modifications to Terms', '''
• TCC reserves the right to modify these terms at any time
• You will be notified of any material changes
• Continued use of the service constitutes acceptance of modified terms
• If you do not agree with changes, you may terminate your account
              '''),
              _buildSection('14. Governing Law', '''
These terms are governed by the laws of the jurisdiction in which TCC operates, without regard to conflict of law principles.
              '''),
              _buildSection('15. Contact Information', '''
For questions about these Terms and Conditions, please contact:

TCC Support Team
Email: support@tcc.com
Phone: 1-800-TCC-HELP
Address: TCC Headquarters, Business District

Business Hours: Monday-Friday, 9 AM - 6 PM
              '''),
              const SizedBox(height: 40),
              _buildAcceptanceNote(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Last Updated: January 1, 2024',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 10),
              Text(
                'Agreement',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'By creating an account and using TCC Agent services, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}