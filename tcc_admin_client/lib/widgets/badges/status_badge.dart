import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.getStatusColor(status);
    final backgroundColor = badgeColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
