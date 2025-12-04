/// Investment Model
/// Represents an investment made by a user
class InvestmentModel {
  final String id;
  final String category;
  final String? subCategory;
  final double amount;
  final int tenureMonths;
  final double returnRate;
  final double expectedReturn;
  final double? actualReturn;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool insuranceTaken;
  final double? insuranceCost;
  final InvestmentUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentModel({
    required this.id,
    required this.category,
    this.subCategory,
    required this.amount,
    required this.tenureMonths,
    required this.returnRate,
    required this.expectedReturn,
    this.actualReturn,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.insuranceTaken,
    this.insuranceCost,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      category: json['category'] as String,
      subCategory: json['subCategory'] as String?,
      amount: (json['amount'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      returnRate: (json['returnRate'] as num).toDouble(),
      expectedReturn: (json['expectedReturn'] as num).toDouble(),
      actualReturn: json['actualReturn'] != null ? (json['actualReturn'] as num).toDouble() : null,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      insuranceTaken: json['insuranceTaken'] as bool,
      insuranceCost: json['insuranceCost'] != null ? (json['insuranceCost'] as num).toDouble() : null,
      user: InvestmentUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      'amount': amount,
      'tenureMonths': tenureMonths,
      'returnRate': returnRate,
      'expectedReturn': expectedReturn,
      if (actualReturn != null) 'actualReturn': actualReturn,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'insuranceTaken': insuranceTaken,
      if (insuranceCost != null) 'insuranceCost': insuranceCost,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate progress percentage
  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;

    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;

    return (elapsedDays / totalDays * 100).clamp(0.0, 100.0);
  }

  /// Check if investment is active
  bool get isActive => status == 'ACTIVE';

  /// Check if investment is matured
  bool get isMatured => status == 'MATURED';

  /// Check if investment is withdrawn
  bool get isWithdrawn => status == 'WITHDRAWN';

  /// Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }
}

/// Investment User Model
class InvestmentUser {
  final String id;
  final String name;
  final String email;
  final String? phone;

  InvestmentUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory InvestmentUser.fromJson(Map<String, dynamic> json) {
    return InvestmentUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
    };
  }
}
