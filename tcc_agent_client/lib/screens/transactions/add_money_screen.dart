import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  bool _isSearching = false;
  bool _userFound = false;

  // Mock user data
  final Map<String, dynamic> _mockUser = {
    'name': 'John Doe',
    'mobile': '232-76-123456',
    'email': 'john.doe@example.com',
    'national_id': 'SL123456789',
    'wallet_balance': 500000.0,
  };

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSearching = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSearching = false;
      _userFound = true;
    });
  }

  void _handleContinue() {
    // Navigate to user verification screen
    context.push('/user-verification');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money to User'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.infoBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.infoBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter user mobile number to add money to their TCC wallet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Mobile Number Input
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: InputDecoration(
                    labelText: 'User Mobile Number',
                    hintText: 'Enter mobile number',
                    prefixIcon: Icon(Icons.phone, color: AppColors.primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.length < 8) {
                      return 'Please enter a valid mobile number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Search Button
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Search User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),

                if (_userFound) ...[
                  const SizedBox(height: 32),

                  // User Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mockUser['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _mockUser['mobile'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: AppColors.successGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Divider(color: AppColors.borderLight),
                          const SizedBox(height: 16),

                          _buildDetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _mockUser['email'],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.badge_outlined,
                            label: 'National ID',
                            value: _mockUser['national_id'],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.account_balance_wallet,
                            label: 'Current Wallet Balance',
                            value: 'SLL ${_mockUser['wallet_balance'].toStringAsFixed(2)}',
                            valueColor: AppColors.primaryOrange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue Button
                  ElevatedButton.icon(
                    onPressed: _handleContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Verify User & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
