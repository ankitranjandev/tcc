import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum PaymentMode {
  cash,
  bank,
  mobileMoney,
}

class PaymentModeSelector extends StatelessWidget {
  final PaymentMode? selectedMode;
  final ValueChanged<PaymentMode> onModeChanged;
  final bool enabled;

  const PaymentModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildModeOption(
          PaymentMode.cash,
          'Cash',
          Icons.money,
          'Receive cash from customer',
        ),
        const SizedBox(height: 12),
        _buildModeOption(
          PaymentMode.bank,
          'Bank Transfer',
          Icons.account_balance,
          'Customer pays via bank transfer',
        ),
        const SizedBox(height: 12),
        _buildModeOption(
          PaymentMode.mobileMoney,
          'Mobile Money',
          Icons.phone_android,
          'Customer pays via mobile money',
        ),
      ],
    );
  }

  Widget _buildModeOption(
    PaymentMode mode,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = selectedMode == mode;

    return InkWell(
      onTap: enabled ? () => onModeChanged(mode) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primaryOrange : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryOrange : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog version for modal selection
class PaymentModeDialog extends StatefulWidget {
  final PaymentMode? initialMode;

  const PaymentModeDialog({super.key, this.initialMode});

  @override
  State<PaymentModeDialog> createState() => _PaymentModeDialogState();
}

class _PaymentModeDialogState extends State<PaymentModeDialog> {
  PaymentMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Mode',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            PaymentModeSelector(
              selectedMode: _selectedMode,
              onModeChanged: (mode) {
                setState(() {
                  _selectedMode = mode;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedMode == null
                      ? null
                      : () => Navigator.pop(context, _selectedMode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show payment mode dialog
Future<PaymentMode?> showPaymentModeDialog(
  BuildContext context, {
  PaymentMode? initialMode,
}) async {
  return await showDialog<PaymentMode>(
    context: context,
    builder: (context) => PaymentModeDialog(initialMode: initialMode),
  );
}

// Helper to get payment mode display text
extension PaymentModeExtension on PaymentMode {
  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.bank:
        return 'Bank Transfer';
      case PaymentMode.mobileMoney:
        return 'Mobile Money';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash:
        return Icons.money;
      case PaymentMode.bank:
        return Icons.account_balance;
      case PaymentMode.mobileMoney:
        return Icons.phone_android;
    }
  }
}
