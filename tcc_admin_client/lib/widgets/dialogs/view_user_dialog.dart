import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/bank_account_model.dart';
import '../../services/bank_account_service.dart';

/// Dialog for viewing user details
class ViewUserDialog extends StatefulWidget {
  final UserModel user;

  const ViewUserDialog({
    super.key,
    required this.user,
  });

  @override
  State<ViewUserDialog> createState() => _ViewUserDialogState();
}

class _ViewUserDialogState extends State<ViewUserDialog> {
  final BankAccountService _bankAccountService = BankAccountService();
  List<BankAccountModel>? _bankAccounts;
  bool _isLoadingBankAccounts = true;
  String? _bankAccountsError;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() {
      _isLoadingBankAccounts = true;
      _bankAccountsError = null;
    });

    final response = await _bankAccountService.getUserBankAccounts(widget.user.id);

    if (mounted) {
      setState(() {
        _isLoadingBankAccounts = false;
        if (response.success && response.data != null) {
          _bankAccounts = response.data;
        } else {
          _bankAccountsError = response.error?.message ?? 'Failed to load bank accounts';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppTheme.space32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // User avatar and name
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                    child: Text(
                      widget.user.fullName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Status badges
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space8,
                children: [
                  _buildStatusBadge(
                    widget.user.status.displayName,
                    widget.user.status.name == 'ACTIVE' ? AppColors.success : AppColors.error,
                  ),
                  _buildStatusBadge(
                    'KYC: ${widget.user.kycStatus.displayName}',
                    _getKycStatusColor(widget.user.kycStatus),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Details sections
              _buildDetailSection('Personal Information', [
                _buildDetailRow('First Name', widget.user.firstName),
                _buildDetailRow('Last Name', widget.user.lastName),
                _buildDetailRow('Email', widget.user.email),
                _buildDetailRow('Phone', widget.user.phone ?? 'N/A'),
                if (widget.user.address != null)
                  _buildDetailRow('Address', widget.user.address!),
              ]),
              const SizedBox(height: AppTheme.space24),

              _buildDetailSection('Account Information', [
                _buildDetailRow('User ID', widget.user.id),
                _buildDetailRow('Status', widget.user.status.displayName),
                _buildDetailRow('KYC Status', widget.user.kycStatus.displayName),
                _buildDetailRow(
                  'Wallet Balance',
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##0.00').format(widget.user.walletBalance)}',
                ),
                _buildDetailRow(
                  'Created At',
                  DateFormat('MMM dd, yyyy HH:mm').format(widget.user.createdAt),
                ),
                if (widget.user.lastActive != null)
                  _buildDetailRow(
                    'Last Active',
                    DateFormat('MMM dd, yyyy HH:mm').format(widget.user.lastActive!),
                  ),
              ]),
              const SizedBox(height: AppTheme.space24),

              // Bank Accounts Section
              _buildBankAccountsSection(),
              const SizedBox(height: AppTheme.space24),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space16,
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getKycStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.pending:
        return AppColors.info;
    }
  }

  Widget _buildBankAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank Accounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.gray300),
          ),
          child: _buildBankAccountsContent(),
        ),
      ],
    );
  }

  Widget _buildBankAccountsContent() {
    if (_isLoadingBankAccounts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
        ),
      );
    }

    if (_bankAccountsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Text(
            _bankAccountsError!,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_bankAccounts == null || _bankAccounts!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Text(
            'No bank accounts found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _bankAccounts!.asMap().entries.map((entry) {
        final index = entry.key;
        final account = entry.value;
        return Column(
          children: [
            if (index > 0) const SizedBox(height: AppTheme.space16),
            if (index > 0)
              Divider(color: AppColors.gray300, height: 1),
            if (index > 0) const SizedBox(height: AppTheme.space16),
            _buildBankAccountCard(account),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBankAccountCard(BankAccountModel account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                account.bankName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                if (account.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: AppColors.accentBlue),
                    ),
                    child: Text(
                      'PRIMARY',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(width: AppTheme.space8),
                if (account.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        _buildDetailRow('Account Holder', account.accountHolderName),
        _buildDetailRow('Account Number', account.accountNumberMasked),
        _buildDetailRow(
          'Added On',
          DateFormat('MMM dd, yyyy').format(account.createdAt),
        ),
      ],
    );
  }
}
