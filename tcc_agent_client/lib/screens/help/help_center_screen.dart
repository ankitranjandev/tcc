import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'faq_screen.dart';
import 'user_guide_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryOrange, Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.help_center,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to common questions and learn how to use the app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'QUICK HELP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.question_answer,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.menu_book,
            title: 'User Guide',
            subtitle: 'Step-by-step tutorials',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuideScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // Contact Support
          const Text(
            'CONTACT US',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {
              _showComingSoonDialog(context, 'Live Chat');
            },
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@tcc.com',
            onTap: () {
              _showEmailDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.phone_outlined,
            title: 'Call Us',
            subtitle: '+232 XX XXX XXXX',
            onTap: () {
              _showCallDialog(context);
            },
          ),
          const SizedBox(height: 24),

          // Resources
          const Text(
            'RESOURCES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.play_circle_outline,
            title: 'Video Tutorials',
            subtitle: 'Watch how-to videos',
            onTap: () {
              _showComingSoonDialog(context, 'Video Tutorials');
            },
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () {
              _showComingSoonDialog(context, 'Privacy Policy');
            },
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Our terms of service',
            onTap: () {
              _showComingSoonDialog(context, 'Terms & Conditions');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send us an email at:'),
            SizedBox(height: 8),
            SelectableText(
              'support@tcc.com',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'We typically respond within 24 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our support hotline:'),
            SizedBox(height: 8),
            SelectableText(
              '+232 XX XXX XXXX',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Available Monday - Friday\n8:00 AM - 6:00 PM',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
