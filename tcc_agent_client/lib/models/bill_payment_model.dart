class BillPaymentModel {
  final String id;
  final String userId;
  final String billType; // 'water', 'electricity', 'dstv', 'others'
  final String billId;
  final String billName;
  final double amount;
  final String paymentMethod; // 'wallet', 'bank', 'mobile_money'
  final String? bankAccountId;
  final String transactionId;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  BillPaymentModel({
    required this.id,
    required this.userId,
    required this.billType,
    required this.billId,
    required this.billName,
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  factory BillPaymentModel.fromJson(Map<String, dynamic> json) {
    return BillPaymentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      billType: json['bill_type'] ?? '',
      billId: json['bill_id'] ?? '',
      billName: json['bill_name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      bankAccountId: json['bank_account_id'],
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      failureReason: json['failure_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bill_type': billType,
      'bill_id': billId,
      'bill_name': billName,
      'amount': amount,
      'payment_method': paymentMethod,
      'bank_account_id': bankAccountId,
      'transaction_id': transactionId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
  }

  BillPaymentModel copyWith({
    String? id,
    String? userId,
    String? billType,
    String? billId,
    String? billName,
    double? amount,
    String? paymentMethod,
    String? bankAccountId,
    String? transactionId,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return BillPaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      billType: billType ?? this.billType,
      billId: billId ?? this.billId,
      billName: billName ?? this.billName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class BillCategory {
  final String type;
  final String name;
  final String icon;
  final String description;
  final bool isAvailable;

  BillCategory({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    this.isAvailable = true,
  });

  static List<BillCategory> getCategories() {
    return [
      BillCategory(
        type: 'water',
        name: 'Water Bill',
        icon: '💧',
        description: 'Pay your water utility bills',
      ),
      BillCategory(
        type: 'electricity',
        name: 'Electricity Bill',
        icon: '⚡',
        description: 'Pay your electricity bills',
      ),
      BillCategory(
        type: 'dstv',
        name: 'DSTV',
        icon: '📺',
        description: 'Pay for DSTV subscription',
      ),
      BillCategory(
        type: 'others',
        name: 'Others',
        icon: '📄',
        description: 'Other bill payments',
      ),
    ];
  }
}
