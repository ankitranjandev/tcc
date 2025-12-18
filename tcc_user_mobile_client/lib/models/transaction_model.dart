class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String status;
  final DateTime date;
  final String? description;
  final String? recipient;
  final String? accountInfo;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
    this.description,
    this.recipient,
    this.accountInfo,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      description: json['description'],
      recipient: json['recipient'],
      accountInfo: json['accountInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'description': description,
      'recipient': recipient,
      'accountInfo': accountInfo,
    };
  }

  String get statusText {
    switch (status) {
      case 'COMPLETED':
        return 'Successful';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isCredit =>
      type == 'DEPOSIT' || type == 'INVESTMENT_RETURN' || type == 'REFUND';
}
