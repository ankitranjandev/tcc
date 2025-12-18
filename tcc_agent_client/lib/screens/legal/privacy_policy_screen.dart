import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy Policy',
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
              _buildIntroduction(),
              const SizedBox(height: 20),
              _buildSection('1. Information We Collect', '''
We collect various types of information to provide and improve our services:

Personal Information:
• Full name and contact details (email, phone number)
• Date of birth and gender
• Government-issued identification documents
• Photographs for identity verification
• Residential and business address

Financial Information:
• Bank account details for commission payments
• Transaction history and patterns
• Commission earnings and payment records
• Float balance and recharge history

Device and Technical Information:
• Device ID, model, and operating system
• IP address and location data
• App usage statistics and preferences
• Browser type and language settings

Business Information:
• Business name and registration details
• Business location and operating hours
• Service area coverage
• Customer interaction logs
              '''),
              _buildSection('2. How We Use Your Information', '''
We use the collected information for the following purposes:

Account Management:
• Verify your identity and maintain account security
• Process your agent application and KYC verification
• Communicate important updates and notifications
• Provide customer support and resolve issues

Service Delivery:
• Enable transaction processing and commission calculations
• Monitor and improve service quality
• Detect and prevent fraud or unauthorized activities
• Ensure compliance with legal and regulatory requirements

Business Operations:
• Analyze usage patterns to improve our services
• Develop new features and functionalities
• Conduct research and statistical analysis
• Manage our business relationship with you
              '''),
              _buildSection('3. Information Sharing and Disclosure', '''
We may share your information in the following circumstances:

With Your Consent:
• When you explicitly agree to share information
• For services you specifically request

Service Providers:
• Payment processors for commission disbursements
• Cloud storage providers for data hosting
• Communication service providers for notifications
• Analytics providers for service improvement

Legal Requirements:
• To comply with legal obligations and court orders
• To respond to lawful requests from government authorities
• To protect our rights, privacy, safety, or property
• To investigate and prevent fraudulent activities

Business Transfers:
• In connection with mergers, acquisitions, or asset sales
• With parent companies or subsidiaries within our corporate group
              '''),
              _buildSection('4. Data Security', '''
We implement robust security measures to protect your information:

Technical Safeguards:
• Encryption of data in transit and at rest
• Secure servers with firewall protection
• Regular security audits and vulnerability assessments
• Multi-factor authentication for account access

Organizational Measures:
• Limited access to personal information on a need-to-know basis
• Confidentiality agreements with employees and contractors
• Regular security training for our staff
• Incident response procedures for data breaches

Your Responsibilities:
• Keep your login credentials confidential
• Use strong, unique passwords for your account
• Report any suspicious activities immediately
• Keep your app updated to the latest version
              '''),
              _buildSection('5. Data Retention', '''
We retain your information for as long as necessary:

Active Accounts:
• Personal information is retained while your account is active
• Transaction records are kept for 7 years for legal compliance
• Communication logs are retained for 2 years

Inactive Accounts:
• Accounts inactive for 12 months may be marked for deletion
• You will be notified before account deletion
• Some information may be retained for legal obligations

After Account Closure:
• Basic information retained for legal and regulatory compliance
• Anonymized data may be kept for analytical purposes
• Complete deletion can be requested subject to legal requirements
              '''),
              _buildSection('6. Your Rights and Choices', '''
You have several rights regarding your personal information:

Access and Portability:
• Request a copy of your personal information
• Receive your data in a structured, machine-readable format
• Transfer your data to another service provider

Correction and Updating:
• Update incorrect or outdated information
• Complete incomplete personal information
• Request verification of data accuracy

Deletion and Restriction:
• Request deletion of your personal information
• Restrict processing of your data in certain circumstances
• Object to specific uses of your information

Communication Preferences:
• Opt-out of promotional communications
• Manage notification settings in the app
• Unsubscribe from email newsletters
              '''),
              _buildSection('7. Location Information', '''
We collect and use location information to provide our services:

How We Use Location Data:
• Verify your service area and availability
• Match you with nearby customers
• Ensure compliance with regional regulations
• Provide location-based features and analytics

Your Controls:
• Enable or disable location services in device settings
• Choose when to share your location (always, while using app, never)
• View and delete location history in your account settings
              '''),
              _buildSection('8. Cookies and Tracking Technologies', '''
We use various tracking technologies:

Types of Technologies:
• Cookies for session management and preferences
• Analytics tools to understand app usage
• Crash reporting tools to improve stability
• Performance monitoring for app optimization

Your Choices:
• Adjust cookie settings in your browser
• Opt-out of analytics tracking in app settings
• Use private/incognito browsing modes
• Clear app cache and data periodically
              '''),
              _buildSection('9. Children\'s Privacy', '''
Our services are not intended for children:

• We do not knowingly collect information from children under 18
• Agents must be at least 18 years old to register
• If we discover underage usage, the account will be terminated
• Parents can contact us to remove their child's information
              '''),
              _buildSection('10. International Data Transfers', '''
Your information may be transferred internationally:

• Data may be processed in countries where we operate
• We ensure appropriate safeguards for international transfers
• You consent to international transfers by using our services
• We comply with applicable data transfer regulations
              '''),
              _buildSection('11. Third-Party Links', '''
Our app may contain links to third-party services:

• We are not responsible for third-party privacy practices
• Review privacy policies of linked services before use
• Third-party services may collect information independently
• We do not control third-party data collection
              '''),
              _buildSection('12. Updates to Privacy Policy', '''
We may update this privacy policy periodically:

• You will be notified of material changes via app or email
• Review the "Last Updated" date at the top
• Continued use after updates constitutes acceptance
• Previous versions available upon request
              '''),
              _buildSection('13. Contact Us', '''
For privacy-related questions or concerns:

Data Protection Officer
TCC Privacy Team
Email: privacy@tcc.com
Phone: 1-800-TCC-DATA

Mailing Address:
TCC Headquarters
Privacy Department
Business District
[City, State, ZIP]

Response Time: Within 30 business days
              '''),
              const SizedBox(height: 40),
              _buildDataProtectionNote(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Our Commitment',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TCC ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our TCC Agent mobile application.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Last Updated: January 1, 2024',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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

  Widget _buildDataProtectionNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your Privacy Matters',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We are committed to protecting your personal information and respecting your privacy. By using our services, you trust us with your information, and we take this responsibility seriously.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                   color: AppColors.success,
                   size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GDPR Compliant',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                   color: AppColors.success,
                   size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ISO 27001 Certified',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                   color: AppColors.success,
                   size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Regular Security Audits',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}