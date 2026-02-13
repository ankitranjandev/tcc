import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
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
              '1. Introduction',
              'TCC Financial Services Limited ("TCC", "we", "us", or "our") is committed to protecting your privacy and personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application ("App") and related services.\n\n'
              'By using our App, you consent to the practices described in this Privacy Policy. If you do not agree with our policies and practices, please do not use our App.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              '2.1 Personal Information\n'
              'We collect personal information that you provide directly to us, including:\n'
              '• Full name and date of birth\n'
              '• National identification number\n'
              '• Phone number and email address\n'
              '• Physical address\n'
              '• Profile photograph\n'
              '• Bank account details\n'
              '• Government-issued ID documents for KYC verification\n\n'
              '2.2 Financial Information\n'
              '• Transaction history and patterns\n'
              '• Account balances and wallet information\n'
              '• Payment methods and billing information\n'
              '• Investment preferences and portfolio data\n\n'
              '2.3 Device and Technical Information\n'
              '• Device type, model, and operating system\n'
              '• Unique device identifiers\n'
              '• IP address and network information\n'
              '• App usage data and analytics\n'
              '• Location data (with your consent)\n\n'
              '2.4 Biometric Data\n'
              '• Selfie photographs for identity verification\n'
              '• Facial recognition data for authentication (if enabled)',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use the information we collect for the following purposes:\n\n'
              '3.1 Service Delivery\n'
              '• Processing transactions and maintaining your account\n'
              '• Providing wallet, investment, and bill payment services\n'
              '• Executing currency exchange and transfers\n'
              '• Managing your investment portfolio\n\n'
              '3.2 Identity Verification and Security\n'
              '• Verifying your identity through KYC processes\n'
              '• Preventing fraud, money laundering, and unauthorized access\n'
              '• Ensuring compliance with regulatory requirements\n'
              '• Investigating suspicious activities\n\n'
              '3.3 Communication\n'
              '• Sending transaction confirmations and receipts\n'
              '• Providing customer support and responding to inquiries\n'
              '• Sending service updates and security alerts\n'
              '• Marketing communications (with your consent)\n\n'
              '3.4 Improvement and Analytics\n'
              '• Analyzing usage patterns to improve our services\n'
              '• Developing new features and products\n'
              '• Conducting research and statistical analysis\n'
              '• Personalizing your experience',
            ),
            _buildSection(
              context,
              '4. Information Sharing and Disclosure',
              'We may share your information with:\n\n'
              '4.1 Service Providers\n'
              '• Payment processors and banking partners\n'
              '• Cloud storage and hosting providers\n'
              '• Identity verification services\n'
              '• Customer support platforms\n'
              '• Analytics and marketing service providers\n\n'
              '4.2 Regulatory and Legal Authorities\n'
              '• Central Bank of Sierra Leone and financial regulators\n'
              '• Law enforcement agencies (when legally required)\n'
              '• Courts and legal proceedings\n'
              '• Tax authorities as required by law\n\n'
              '4.3 Business Partners\n'
              '• Bill payment service providers\n'
              '• Investment product partners\n'
              '• Mobile network operators\n\n'
              '4.4 We DO NOT sell your personal information to third parties for marketing purposes.',
            ),
            _buildSection(
              context,
              '5. Data Security',
              '5.1 Security Measures\n'
              'We implement robust security measures to protect your data:\n'
              '• End-to-end encryption for data transmission\n'
              '• Secure data storage with encryption at rest\n'
              '• Multi-factor authentication options\n'
              '• Regular security audits and penetration testing\n'
              '• Access controls and employee training\n'
              '• Intrusion detection and prevention systems\n\n'
              '5.2 Your Security Responsibilities\n'
              '• Keep your login credentials confidential\n'
              '• Use strong, unique passwords\n'
              '• Enable biometric authentication when available\n'
              '• Report suspicious activity immediately\n'
              '• Do not share your OTP or PIN with anyone',
            ),
            _buildSection(
              context,
              '6. Data Retention',
              '6.1 We retain your personal information for as long as necessary to:\n'
              '• Provide our services to you\n'
              '• Comply with legal and regulatory obligations\n'
              '• Resolve disputes and enforce our agreements\n'
              '• Prevent fraud and maintain security\n\n'
              '6.2 Retention Periods\n'
              '• Account information: Duration of account plus 7 years\n'
              '• Transaction records: 10 years (as required by financial regulations)\n'
              '• KYC documents: Duration of relationship plus 7 years\n'
              '• Marketing data: Until consent is withdrawn\n\n'
              '6.3 After the retention period, we will securely delete or anonymize your data.',
            ),
            _buildSection(
              context,
              '7. Your Rights and Choices',
              'You have the following rights regarding your personal data:\n\n'
              '7.1 Access\n'
              '• Request a copy of your personal data we hold\n\n'
              '7.2 Correction\n'
              '• Request correction of inaccurate or incomplete data\n'
              '• Update your profile information through the App\n\n'
              '7.3 Deletion\n'
              '• Request deletion of your account and data (subject to legal retention requirements)\n'
              '• Note: Some data may be retained for regulatory compliance\n\n'
              '7.4 Portability\n'
              '• Request your data in a structured, machine-readable format\n\n'
              '7.5 Objection\n'
              '• Opt out of marketing communications\n'
              '• Object to certain processing activities\n\n'
              '7.6 Withdrawal of Consent\n'
              '• Withdraw consent for optional data processing\n'
              '• Note: This may affect your ability to use certain features\n\n'
              'To exercise these rights, contact us at privacy@tcc.com.',
            ),
            _buildSection(
              context,
              '8. Cookies and Tracking Technologies',
              '8.1 We use cookies and similar technologies to:\n'
              '• Remember your preferences and settings\n'
              '• Analyze App usage and performance\n'
              '• Provide personalized content\n'
              '• Detect and prevent fraud\n\n'
              '8.2 You can manage cookie preferences in your device settings.',
            ),
            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Our App is not intended for individuals under 18 years of age. We do not knowingly collect personal information from children. If we become aware that we have collected data from a minor, we will take steps to delete it promptly.\n\n'
              'If you believe we have inadvertently collected information from a minor, please contact us immediately.',
            ),
            _buildSection(
              context,
              '10. International Data Transfers',
              'Your data may be transferred to and processed in countries outside Sierra Leone. When we transfer data internationally, we ensure appropriate safeguards are in place:\n\n'
              '• Standard contractual clauses approved by relevant authorities\n'
              '• Data processing agreements with service providers\n'
              '• Compliance with applicable data protection laws',
            ),
            _buildSection(
              context,
              '11. Third-Party Links and Services',
              'Our App may contain links to third-party websites and services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any personal information.',
            ),
            _buildSection(
              context,
              '12. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes through:\n\n'
              '• In-app notifications\n'
              '• Email notifications\n'
              '• Updates posted on our website\n\n'
              'Your continued use of the App after changes indicates acceptance of the updated policy.',
            ),
            _buildSection(
              context,
              '13. Contact Us',
              'For questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us:\n\n'
              'TCC Financial Services Limited\n'
              'Data Protection Officer\n'
              'Email: privacy@tcc.com\n'
              'Phone: +232 123 456 789\n'
              'Address: Freetown, Sierra Leone\n\n'
              'Response Time: We aim to respond to all data protection inquiries within 30 days.',
            ),
            _buildSection(
              context,
              '14. Regulatory Information',
              '14.1 TCC is registered with the Data Protection Commission of Sierra Leone.\n\n'
              '14.2 We comply with:\n'
              '• Sierra Leone Data Protection regulations\n'
              '• Central Bank of Sierra Leone guidelines\n'
              '• Anti-Money Laundering (AML) regulations\n'
              '• International data protection standards\n\n'
              '14.3 You have the right to lodge a complaint with the Data Protection Commission if you believe your data protection rights have been violated.',
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
            Icons.privacy_tip,
            color: AppColors.primaryBlue,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your privacy is important to us. Learn how we protect your data.',
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
