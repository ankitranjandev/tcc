import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';

class CommissionDashboardScreen extends StatefulWidget {
  const CommissionDashboardScreen({super.key});

  @override
  State<CommissionDashboardScreen> createState() => _CommissionDashboardScreenState();
}

class _CommissionDashboardScreenState extends State<CommissionDashboardScreen> {
  String _selectedPeriod = 'week';

  // Mock data
  final Map<String, Map<String, dynamic>> _stats = {
    'today': {
      'earnings': 25000.0,
      'transactions': 3,
    },
    'week': {
      'earnings': 125000.0,
      'transactions': 18,
    },
    'month': {
      'earnings': 485000.0,
      'transactions': 67,
    },
  };

  final List<Map<String, dynamic>> _recentCommissions = [
    {
      'transaction_id': 'TXN123456',
      'amount': 12500.0,
      'transaction_amount': 500000.0,
      'rate': 2.5,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'paid',
    },
    {
      'transaction_id': 'TXN123457',
      'amount': 7500.0,
      'transaction_amount': 300000.0,
      'rate': 2.5,
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'paid',
    },
    {
      'transaction_id': 'TXN123458',
      'amount': 18750.0,
      'transaction_amount': 750000.0,
      'rate': 2.5,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'paid',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentStats = _stats[_selectedPeriod]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Dashboard'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.backgroundLight,
              child: Row(
                children: [
                  Expanded(child: _buildPeriodButton('Today', 'today')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodButton('This Week', 'week')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodButton('This Month', 'month')),
                ],
              ),
            ),

            // Earnings Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.commissionGreen,
                    AppColors.commissionGreen.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.commissionGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _selectedPeriod == 'today'
                            ? 'Today'
                            : _selectedPeriod == 'week'
                                ? 'This Week'
                                : 'This Month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SLL ${currentStats['earnings'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentStats['transactions']} Transactions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg/Transaction',
                      'SLL ${(currentStats['earnings'] / currentStats['transactions']).toStringAsFixed(0)}',
                      Icons.calculate,
                      AppColors.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Commission Rate',
                      '2.5%',
                      Icons.percent,
                      AppColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Earnings Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: _buildChart(),
            ),

            const SizedBox(height: 24),

            // Recent Commissions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Commissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentCommissions.length,
              itemBuilder: (context, index) {
                return _buildCommissionCard(_recentCommissions[index]);
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primaryOrange : AppColors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 15000),
              const FlSpot(1, 22000),
              const FlSpot(2, 18000),
              const FlSpot(3, 25000),
              const FlSpot(4, 30000),
              const FlSpot(5, 20000),
              const FlSpot(6, 25000),
            ],
            isCurved: true,
            color: AppColors.commissionGreen,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.commissionGreen.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard(Map<String, dynamic> commission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.commissionGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppColors.commissionGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        commission['transaction_id'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'SLL ${commission['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.commissionGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transaction: SLL ${commission['transaction_amount'].toStringAsFixed(0)} • Rate: ${commission['rate']}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
