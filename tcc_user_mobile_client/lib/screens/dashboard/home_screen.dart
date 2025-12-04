import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/payment_bottom_sheet.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive_builder.dart';
import '../../widgets/responsive_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final mockService = MockDataService();
    final stats = mockService.dashboardStats;
    final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isTabletOrDesktop = screenWidth > ResponsiveHelper.mobileBreakpoint;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: isTabletOrDesktop ? 1200 : double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText.body(
                        'Welcome back,',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      ResponsiveText.headline(
                        user?.firstName ?? 'User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance Card
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3),
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText.body(
                          'TCC Coin Balance',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
                        ResponsiveText(
                          currencyFormat.format(user?.walletBalance ?? 0),
                          mobileFontSize: 28,
                          tabletFontSize: 32,
                          desktopFontSize: 36,
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 0.5)),
                        ResponsiveText.caption(
                          '\$1 = 1 Coin',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2.5)),
                        ElevatedButton(
                          onPressed: () => _showAddMoneyDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primaryBlue,
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 4),
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 1.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ResponsiveText.body('Add Money'),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),

                // Quick Actions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3),
                  ),
                  child: ResponsiveBuilder(
                    builder: (context, deviceType) {
                      final isCompact = deviceType == DeviceType.mobile;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2),
                        runSpacing: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2),
                        children: [
                          _buildQuickAction(
                            context,
                            'Transfer',
                            Icons.swap_horiz,
                            AppColors.primaryBlue,
                            () => _showTransferBottomSheet(context),
                            isCompact: isCompact,
                          ),
                          _buildQuickAction(
                            context,
                            'Bill Payment',
                            Icons.receipt_long,
                            AppColors.secondaryYellow,
                            () => _showBillPaymentBottomSheet(context),
                            isCompact: isCompact,
                          ),
                          _buildQuickAction(
                            context,
                            'Withdraw',
                            Icons.arrow_upward,
                            AppColors.secondaryGreen,
                            () => _showWithdrawalBottomSheet(context),
                            isCompact: isCompact,
                          ),
                          _buildQuickAction(
                            context,
                            'Find Agent',
                            Icons.person_pin_circle,
                            AppColors.warning,
                            () => context.push('/agent-search'),
                            isCompact: isCompact,
                          ),
                        ],
                      );
                    },
                  ),
                ),

              SizedBox(height: 24),

              // Stats Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Invested',
                        currencyFormat.format(stats['totalInvested']),
                        AppColors.yellowCardGradient,
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Expected Return',
                        currencyFormat.format(stats['expectedReturns']),
                        AppColors.greenCardGradient,
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Investment Options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Explore Investments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
              ),

              SizedBox(height: 16),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildInvestmentCard(
                      context,
                      'Agriculture',
                      'Invest in farms and agricultural projects',
                      Icons.agriculture,
                      AppColors.secondaryGreen,
                    ),
                    SizedBox(height: 12),
                    _buildInvestmentCard(
                      context,
                      'Minerals',
                      'Invest in silver, gold, and platinum',
                      Icons.diamond,
                      AppColors.secondaryYellow,
                    ),
                    SizedBox(height: 12),
                    _buildInvestmentCard(
                      context,
                      'Education',
                      'Invest in educational institutions',
                      Icons.school,
                      AppColors.primaryBlue,
                    ),
                    SizedBox(height: 12),
                    _buildInvestmentCard(
                      context,
                      'Currency',
                      'Invest in foreign exchange and currencies',
                      Icons.currency_exchange,
                      AppColors.warning,
                    ),
                  ],
                ),
              ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    LinearGradient gradient,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.white, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push('/investments/${title.toLowerCase()}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddMoneyBottomSheet(),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isCompact = true,
  }) {
    final actionWidth = ResponsiveHelper.getResponsiveValue<double>(
      context,
      mobile: isCompact ? 100 : 120,
      tablet: 140,
      desktop: 160,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: actionWidth,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 1.5),
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveHelper.getResponsiveValue<double>(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            ResponsiveText.caption(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferBottomSheet(BuildContext context) {
    final amountController = TextEditingController();
    final recipientController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Transfer Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Send money to another TCC user',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Phone Number',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '+232 XX XXX XXXX',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Le ',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter amount',
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    final recipient = recipientController.text;

                    if (recipient.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter valid details'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PaymentBottomSheet(
                        amount: amount,
                        title: 'Transfer Money',
                        description: 'Transfer Le ${amount.toStringAsFixed(0)} to $recipient',
                        metadata: {
                          'type': 'transfer',
                          'recipient': recipient,
                          'amount': amount,
                        },
                        onSuccess: (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Transfer successful!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onFailure: (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Transfer failed. Please try again.'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillPaymentBottomSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedBiller = 'EDSA (Electricity)';

    final billers = [
      'EDSA (Electricity)',
      'Guma Water (Water)',
      'Africell (Mobile)',
      'Orange (Mobile)',
      'Airtel (Mobile)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Pay Bills',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pay your utility and service bills',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: selectedBiller,
                  decoration: InputDecoration(
                    labelText: 'Select Biller',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: billers.map((biller) {
                    return DropdownMenuItem(
                      value: biller,
                      child: Text(biller),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBiller = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Le ',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Enter amount',
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);

                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PaymentBottomSheet(
                          amount: amount,
                          title: 'Pay Bill',
                          description: 'Pay Le ${amount.toStringAsFixed(0)} to $selectedBiller',
                          metadata: {
                            'type': 'bill_payment',
                            'biller': selectedBiller,
                            'amount': amount,
                          },
                          onSuccess: (result) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bill payment successful!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onFailure: (result) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bill payment failed. Please try again.'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWithdrawalBottomSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedMethod = 'Bank Transfer';

    final withdrawalMethods = [
      'Bank Transfer',
      'Mobile Money',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Withdraw Money',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Withdraw funds from your TCC wallet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Le ',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Enter amount',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'Withdrawal Method',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: withdrawalMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMethod = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);

                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text('Confirm Withdrawal'),
                          content: Text(
                            'Withdraw Le ${amount.toStringAsFixed(0)} to your $selectedMethod?\n\nProcessing may take 1-3 business days.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Withdrawal request submitted successfully!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMoneyBottomSheet extends StatefulWidget {
  @override
  State<_AddMoneyBottomSheet> createState() => _AddMoneyBottomSheetState();
}

class _AddMoneyBottomSheetState extends State<_AddMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Bank Transfer';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Transfer from your bank account',
    },
    {
      'name': 'Debit/Credit Card',
      'icon': Icons.credit_card,
      'description': 'Pay with your card',
    },
    {
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Pay with mobile money',
    },
    {
      'name': 'USSD',
      'icon': Icons.dialpad,
      'description': 'Pay via USSD code',
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add funds to your TCC wallet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Le ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter amount',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              // Quick amount buttons
              Row(
                children: [
                  _buildQuickAmountButton('1,000'),
                  SizedBox(width: 8),
                  _buildQuickAmountButton('5,000'),
                  SizedBox(width: 8),
                  _buildQuickAmountButton('10,000'),
                ],
              ),
              SizedBox(height: 24),

              // Payment Method
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),

              // Payment methods list
              ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),

              SizedBox(height: 24),

              // Add Money Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _processAddMoney(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _amountController.text = amount.replaceAll(',', '');
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Le $amount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['name'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method['name'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  method['icon'],
                  color: isSelected ? AppColors.primaryBlue : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primaryBlue : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      method['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _processAddMoney(BuildContext context) {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Close the current bottom sheet
    Navigator.pop(context);

    // Show payment bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentBottomSheet(
        amount: amount,
        title: 'Add Money',
        description: 'Add Le ${amount.toStringAsFixed(0)} to your TCC wallet',
        metadata: {
          'type': 'add_money',
          'amount': amount,
        },
        onSuccess: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Money added successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onFailure: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add money. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }


}
