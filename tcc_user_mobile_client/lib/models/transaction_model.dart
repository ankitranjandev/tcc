import '../utils/date_utils.dart' as date_utils;

class TransactionModel {
  final String id; // UUID
  final String transactionId; // Human-readable transaction ID (TXN20231224123456)
  final String type;
  final double amount;
  final String status;
  final DateTime date;
  final String? description;
  final String? recipient;
  final String? accountInfo;

  TransactionModel({
    required this.id,
    required this.transactionId,
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
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      date: date_utils.DateUtils.parseApiDate(json),
      description: json['description'],
      recipient: json['recipient'],
      accountInfo: json['accountInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
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
