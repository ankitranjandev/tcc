class CommissionModel {
  final String id;
  final String agentId;
  final String transactionId;
  final double amount;
  final double rate; // percentage
  final double transactionAmount;
  final String status; // pending, paid, cancelled
  final DateTime createdAt;
  final DateTime? paidAt;

  CommissionModel({
    required this.id,
    required this.agentId,
    required this.transactionId,
    required this.amount,
    required this.rate,
    required this.transactionAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] ?? json['commission_id'] ?? '',
      agentId: json['agent_id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      rate: (json['rate'] ?? 0.0).toDouble(),
      transactionAmount: (json['transaction_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'transaction_id': transactionId,
      'amount': amount,
      'rate': rate,
      'transaction_amount': transactionAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class CommissionStats {
  final double totalEarnings;
  final double dailyEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int totalTransactions;
  final int dailyTransactions;
  final int weeklyTransactions;
  final int monthlyTransactions;
  final double currentRate;

  CommissionStats({
    required this.totalEarnings,
    required this.dailyEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalTransactions,
    required this.dailyTransactions,
    required this.weeklyTransactions,
    required this.monthlyTransactions,
    required this.currentRate,
  });

  factory CommissionStats.fromJson(Map<String, dynamic> json) {
    return CommissionStats(
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      dailyEarnings: (json['daily_earnings'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weekly_earnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] ?? 0.0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      dailyTransactions: json['daily_transactions'] ?? 0,
      weeklyTransactions: json['weekly_transactions'] ?? 0,
      monthlyTransactions: json['monthly_transactions'] ?? 0,
      currentRate: (json['current_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'daily_earnings': dailyEarnings,
      'weekly_earnings': weeklyEarnings,
      'monthly_earnings': monthlyEarnings,
      'total_transactions': totalTransactions,
      'daily_transactions': dailyTransactions,
      'weekly_transactions': weeklyTransactions,
      'monthly_transactions': monthlyTransactions,
      'current_rate': currentRate,
    };
  }
}
