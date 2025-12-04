import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/investment_model.dart';

class PortfolioInvestmentDetailScreen extends StatelessWidget {
  final InvestmentModel investment;

  const PortfolioInvestmentDetailScreen({
    super.key,
    required this.investment,
  });

  Color get _categoryColor {
    switch (investment.category.toUpperCase()) {
      case 'AGRICULTURE':
        return AppColors.secondaryGreen;
      case 'MINERALS':
        return AppColors.secondaryYellow;
      case 'EDUCATION':
        return AppColors.primaryBlue;
      case 'CURRENCY':
        return AppColors.warning;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final profit = investment.expectedReturn - investment.amount;
    final profitPercentage = (profit / investment.amount) * 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Investment Details',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              investment.status,
              style: TextStyle(
                color: _categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Investment Name and Category
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _categoryColor,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          investment.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Progress Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Investment Progress',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(investment.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: investment.progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Started: ${dateFormat.format(investment.startDate)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Matures: ${dateFormat.format(investment.endDate)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Investment Stats
              Text(
                'Investment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'ROI',
                      '${investment.roi}%',
                      AppColors.primaryBlue,
                      Icons.trending_up,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Period',
                      '${investment.period} months',
                      AppColors.secondaryYellow,
                      Icons.calendar_today,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Days Left',
                      '${investment.daysLeft}',
                      AppColors.secondaryGreen,
                      Icons.timer,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Financial Details
              Text(
                'Financial Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _buildFinancialRow(context, 'Amount Invested', currencyFormat.format(investment.amount)),
                    SizedBox(height: 16),
                    _buildFinancialRow(context, 'Expected Return', currencyFormat.format(investment.expectedReturn)),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(profit),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${profitPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Timeline
              Text(
                'Investment Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),

              _buildTimelineItem(
                context,
                'Investment Started',
                dateFormat.format(investment.startDate),
                true,
                Icons.play_circle,
              ),
              _buildTimelineItem(
                context,
                'Current Status',
                'Day ${DateTime.now().difference(investment.startDate).inDays} of ${investment.endDate.difference(investment.startDate).inDays}',
                true,
                Icons.pending,
              ),
              _buildTimelineItem(
                context,
                'Maturity Date',
                dateFormat.format(investment.endDate),
                false,
                Icons.check_circle,
              ),
              SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Show investment certificate/details
                        _showCertificate(context);
                      },
                      icon: Icon(Icons.description),
                      label: Text('Certificate'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primaryBlue),
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to transactions
                        context.go('/dashboard');
                        // Note: In a real app, you'd navigate to transactions tab
                      },
                      icon: Icon(Icons.history),
                      label: Text('History'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, String title, String subtitle, bool isCompleted, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _categoryColor.withValues(alpha: 0.1)
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? _categoryColor : Theme.of(context).disabledColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (investment.category.toUpperCase()) {
      case 'AGRICULTURE':
        return Icons.agriculture;
      case 'MINERALS':
        return Icons.diamond;
      case 'EDUCATION':
        return Icons.school;
      case 'CURRENCY':
        return Icons.currency_exchange;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showCertificate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.secondaryYellow),
            SizedBox(width: 8),
            Expanded(
              child: Text('Investment Certificate'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Certificate ID: ${investment.id}'),
            SizedBox(height: 8),
            Text('Investment: ${investment.name}'),
            SizedBox(height: 8),
            Text('Category: ${investment.category}'),
            SizedBox(height: 8),
            Text('Status: ${investment.status}'),
            SizedBox(height: 16),
            Text(
              'This is a mock certificate. In a production app, this would show a downloadable PDF certificate.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Certificate download feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.download),
            label: Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
