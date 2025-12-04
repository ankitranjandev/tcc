import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';

/// Stat Card Widget for Dashboard KPIs
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double? change;
  final bool isPercentage;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.accentBlue,
    this.change,
    this.isPercentage = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (change ?? 0) >= 0;
    final isMobile = context.isMobile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(
          isMobile ? AppTheme.space20 : AppTheme.space24,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [AppColors.shadowSmall],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(
                      isMobile ? AppTheme.space8 : AppTheme.space12,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                ),
                if (change != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space8,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPercentage
                                ? Formatters.formatPercentage(change!.abs())
                                : Formatters.formatNumber(change!.abs()),
                            style: TextStyle(
                              color: isPositive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? AppTheme.space8 : AppTheme.space12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isMobile ? 12 : 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? AppTheme.space4 : AppTheme.space8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
