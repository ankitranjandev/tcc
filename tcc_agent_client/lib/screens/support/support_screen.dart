import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@tcc.com',
      query: 'subject=Agent Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+23276000000');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.primaryOrangeLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'re Here to Help',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Methods
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@tcc.com',
              description: 'Get a response within 24 hours',
              color: AppColors.infoBlue,
              onTap: _launchEmail,
            ),

            const SizedBox(height: 12),

            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+232 76 000 000',
              description: 'Mon-Fri, 9:00 AM - 5:00 PM',
              color: AppColors.successGreen,
              onTap: _launchPhone,
            ),

            const SizedBox(height: 12),

            _buildContactCard(
              icon: Icons.location_on_outlined,
              title: 'Visit Office',
              subtitle: 'Freetown, Sierra Leone',
              description: 'Walk-in support available',
              color: AppColors.secondaryTeal,
              onTap: null,
            ),

            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            _buildFAQCard(
              'How do I add money to a user account?',
              'Search for the user by mobile number, verify their identity with photo and ID, count the cash denominations, and confirm the transaction.',
            ),

            const SizedBox(height: 12),

            _buildFAQCard(
              'When will I receive my commission?',
              'Commissions are credited instantly after each successful transaction and can be viewed in your Commission Dashboard.',
            ),

            const SizedBox(height: 12),

            _buildFAQCard(
              'How long does wallet credit approval take?',
              'Wallet credit requests are typically approved within 24-48 hours after admin verification of your deposit receipt.',
            ),

            const SizedBox(height: 12),

            _buildFAQCard(
              'What should I do if a transaction fails?',
              'Contact our support team immediately with the transaction ID. We\'ll investigate and resolve the issue promptly.',
            ),

            const SizedBox(height: 32),

            // Submit Request Button
            ElevatedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.send),
              label: const Text('Submit Support Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(String question, String answer) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
