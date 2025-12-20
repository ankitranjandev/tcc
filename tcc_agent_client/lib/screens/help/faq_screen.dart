import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class FAQItem {
  final String question;
  final String answer;
  final String category;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
    this.isExpanded = false,
  });
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<FAQItem> _filteredFAQs = [];

  final List<String> _categories = [
    'All',
    'Account',
    'Transactions',
    'Payments',
    'Voting',
    'Commissions',
    'Technical',
  ];

  final List<FAQItem> _faqs = [
    // Account FAQs
    FAQItem(
      category: 'Account',
      question: 'How do I register as a TCC agent?',
      answer: 'To register as a TCC agent:\n1. Download the TCC Agent app\n2. Tap "Register" on the login screen\n3. Enter your phone number and verify with OTP\n4. Complete your profile information\n5. Wait for admin approval\n\nYou will receive a notification once your account is approved.',
    ),
    FAQItem(
      category: 'Account',
      question: 'How do I reset my password?',
      answer: 'To reset your password:\n1. Go to Settings\n2. Tap "Change Password"\n3. Enter your current password\n4. Enter and confirm your new password\n5. Tap "Update Password"\n\nYour password must be at least 8 characters with uppercase, lowercase, numbers, and special characters.',
    ),
    FAQItem(
      category: 'Account',
      question: 'How do I enable biometric authentication?',
      answer: 'To enable biometric authentication:\n1. Go to Settings\n2. Tap "Biometric Authentication"\n3. Toggle the switch to enable\n4. Authenticate with your fingerprint or face ID\n\nOnce enabled, you can use biometrics to login and authorize transactions.',
    ),

    // Transaction FAQs
    FAQItem(
      category: 'Transactions',
      question: 'How do I process a deposit for a customer?',
      answer: 'To process a deposit:\n1. Go to "Add Money" tab\n2. Select payment mode (Cash/Bank/Mobile Money)\n3. Enter customer details and amount\n4. Verify customer information\n5. Collect payment from customer\n6. Complete the transaction\n\nYou will earn commission on successful deposits.',
    ),
    FAQItem(
      category: 'Transactions',
      question: 'What are the transaction limits?',
      answer: 'Transaction limits vary by type:\n\n• Deposits: TCC10,000 - 10,000,000\n• Withdrawals: TCC10,000 - 5,000,000\n• Transfers: TCC1,000 - 5,000,000\n\nLimits may be higher for verified customers. Contact support if you need to process larger amounts.',
    ),
    FAQItem(
      category: 'Transactions',
      question: 'How long do transactions take to process?',
      answer: 'Transaction processing times:\n\n• Cash deposits: Instant\n• Bank transfers: 1-2 business days\n• Mobile money: Instant to 1 hour\n• Withdrawals: Instant\n\nAll transactions are recorded immediately in the app.',
    ),

    // Payment FAQs
    FAQItem(
      category: 'Payments',
      question: 'How do I verify a payment order?',
      answer: 'To verify a payment order:\n1. Go to "Payment Orders" tab\n2. Find the order you want to verify\n3. Ask customer for verification code\n4. Enter the code\n5. Verify customer identity\n6. Complete the payment\n\nAlways verify customer identity before completing payments.',
    ),
    FAQItem(
      category: 'Payments',
      question: 'What payment methods are accepted?',
      answer: 'We accept the following payment methods:\n\n• Cash\n• Bank Transfer (all major banks)\n• Mobile Money (Orange Money, Africell, etc.)\n\nYou can select the payment method when processing transactions.',
    ),

    // Voting FAQs
    FAQItem(
      category: 'Voting',
      question: 'How does the voting system work?',
      answer: 'The voting system allows you to:\n\n1. View open elections\n2. Cast your vote (one vote per election)\n3. View results after voting or when election closes\n4. Track voting history\n\nEach vote costs a small fee that is deducted from your wallet.',
    ),
    FAQItem(
      category: 'Voting',
      question: 'Can I change my vote after casting it?',
      answer: 'No, votes cannot be changed once cast. This ensures the integrity of the voting process.\n\nPlease review your selection carefully before confirming your vote.',
    ),

    // Commission FAQs
    FAQItem(
      category: 'Commissions',
      question: 'How are commissions calculated?',
      answer: 'Commissions are calculated as a percentage of transaction amounts:\n\n• Deposits: 1-2%\n• Withdrawals: 1-2%\n• Transfers: 0.5-1%\n• Bill Payments: Fixed fee\n\nCommissions are credited to your wallet immediately after transaction completion.',
    ),
    FAQItem(
      category: 'Commissions',
      question: 'When can I withdraw my commissions?',
      answer: 'You can withdraw commissions at any time, subject to:\n\n• Minimum withdrawal: TCC50,000\n• Withdrawals to your linked bank account\n• Processing time: 1-2 business days\n\nGo to your wallet to initiate a withdrawal.',
    ),

    // Technical FAQs
    FAQItem(
      category: 'Technical',
      question: 'Can I use the app offline?',
      answer: 'The app has limited offline functionality:\n\n• View cached data\n• Queue transactions for later sync\n• Access transaction history\n\nAn internet connection is required to process new transactions and sync data.',
    ),
    FAQItem(
      category: 'Technical',
      question: 'What should I do if the app is not working?',
      answer: 'If you experience issues:\n\n1. Check your internet connection\n2. Close and restart the app\n3. Clear app cache (Settings > Clear Cache)\n4. Update to the latest version\n5. Contact support if issue persists\n\nFor urgent issues, call our support hotline.',
    ),
    FAQItem(
      category: 'Technical',
      question: 'How do I update the app?',
      answer: 'To update the app:\n\n1. Open Google Play Store (Android) or App Store (iOS)\n2. Search for "TCC Agent"\n3. Tap "Update" if available\n\nEnable automatic updates to always have the latest version.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _faqs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    setState(() {
      _filteredFAQs = _faqs.where((faq) {
        final matchesCategory = _selectedCategory == 'All' || faq.category == _selectedCategory;
        final matchesSearch = _searchController.text.isEmpty ||
            faq.question.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            faq.answer.toLowerCase().contains(_searchController.text.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFAQs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _filterFAQs(),
            ),
          ),

          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterFAQs();
                      });
                    },
                    selectedColor: AppColors.primaryOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // FAQ List
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      return _buildFAQItem(_filteredFAQs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.help_outline,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                Text(
                  faq.answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
