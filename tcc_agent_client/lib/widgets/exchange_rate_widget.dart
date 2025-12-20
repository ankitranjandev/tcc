import 'package:flutter/material.dart';
import 'dart:async';
import '../config/app_colors.dart';

class ExchangeRateWidget extends StatefulWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double? rate;
  final bool isLive;
  final VoidCallback? onRefresh;

  const ExchangeRateWidget({
    super.key,
    this.baseCurrency = 'USD',
    this.targetCurrency = 'TCC',
    this.rate,
    this.isLive = true,
    this.onRefresh,
  });

  @override
  State<ExchangeRateWidget> createState() => _ExchangeRateWidgetState();
}

class _ExchangeRateWidgetState extends State<ExchangeRateWidget> {
  double? _currentRate;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentRate = widget.rate ?? 25000.0; // Default TCC rate
    _lastUpdated = DateTime.now();

    if (widget.isLive) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshRate();
    });
  }

  Future<void> _refreshRate() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // TODO: Replace with actual API call
      // final response = await ApiService().getExchangeRate(
      //   baseCurrency: widget.baseCurrency,
      //   targetCurrency: widget.targetCurrency,
      // );

      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Mock data - simulate small fluctuation
      final fluctuation = (_currentRate! * 0.001) * (0.5 - (DateTime.now().millisecond % 100) / 100);
      final newRate = _currentRate! + fluctuation;

      setState(() {
        _currentRate = newRate;
        _lastUpdated = DateTime.now();
      });

      widget.onRefresh?.call();
    } catch (e) {
      debugPrint('Error refreshing exchange rate: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.currency_exchange,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Exchange Rate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isRefreshing ? null : _refreshRate,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '1 ${widget.baseCurrency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentRate!.toStringAsFixed(2)} ${widget.targetCurrency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_lastUpdated != null)
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white70,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_getTimeAgo(_lastUpdated!)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Compact version for smaller spaces
class ExchangeRateCompact extends StatelessWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;

  const ExchangeRateCompact({
    super.key,
    this.baseCurrency = 'USD',
    this.targetCurrency = 'TCC',
    this.rate = 25000.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.currency_exchange,
            color: AppColors.primaryOrange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '1 $baseCurrency = ${rate.toStringAsFixed(2)} $targetCurrency',
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Exchange rate calculator widget
class ExchangeRateCalculator extends StatefulWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;

  const ExchangeRateCalculator({
    super.key,
    this.baseCurrency = 'USD',
    this.targetCurrency = 'TCC',
    this.rate = 25000.0,
  });

  @override
  State<ExchangeRateCalculator> createState() => _ExchangeRateCalculatorState();
}

class _ExchangeRateCalculatorState extends State<ExchangeRateCalculator> {
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  @override
  void dispose() {
    _baseController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _calculateBase(String value) {
    if (value.isEmpty) {
      _baseController.clear();
      return;
    }

    final targetAmount = double.tryParse(value);
    if (targetAmount != null) {
      final baseAmount = targetAmount / widget.rate;
      _baseController.text = baseAmount.toStringAsFixed(2);
    }
  }

  void _calculateTarget(String value) {
    if (value.isEmpty) {
      _targetController.clear();
      return;
    }

    final baseAmount = double.tryParse(value);
    if (baseAmount != null) {
      final targetAmount = baseAmount * widget.rate;
      _targetController.text = targetAmount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Currency Calculator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.baseCurrency,
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _calculateTarget(value);
              },
            ),
            const SizedBox(height: 12),
            const Center(
              child: Icon(Icons.swap_vert, color: AppColors.primaryOrange),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.targetCurrency,
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _calculateBase(value);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rate: 1 ${widget.baseCurrency} = ${widget.rate.toStringAsFixed(2)} ${widget.targetCurrency}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
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
