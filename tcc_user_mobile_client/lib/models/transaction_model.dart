import '../utils/date_utils.dart' as date_utils;

class OtherParty {
  final String? name;
  final String? phone;
  final String? email;

  OtherParty({this.name, this.phone, this.email});

  factory OtherParty.fromJson(Map<String, dynamic> json) {
    return OtherParty(
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

class TransactionModel {
  final String id; // UUID
  final String transactionId; // Human-readable transaction ID (TXN20231224123456)
  final String type;
  final double amount;
  final double fee;
  final String status;
  final String direction; // CREDIT or DEBIT
  final DateTime date;
  final String? description;
  final String? recipient;
  final String? accountInfo;
  final OtherParty? otherParty;

  TransactionModel({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    this.fee = 0,
    required this.status,
    this.direction = 'UNKNOWN',
    required this.date,
    this.description,
    this.recipient,
    this.accountInfo,
    this.otherParty,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      direction: json['direction'] ?? 'UNKNOWN',
      date: date_utils.DateUtils.parseApiDate(json),
      description: json['description'],
      recipient: json['recipient'],
      accountInfo: json['accountInfo'],
      otherParty: json['other_party'] != null
          ? OtherParty.fromJson(json['other_party'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'amount': amount,
      'fee': fee,
      'status': status,
      'direction': direction,
      'date': date.toIso8601String(),
      'description': description,
      'recipient': recipient,
      'accountInfo': accountInfo,
      'other_party': otherParty?.toJson(),
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

  // Use direction from backend if available, otherwise fall back to type-based logic
  bool get isCredit {
    if (direction == 'CREDIT') return true;
    if (direction == 'DEBIT') return false;
    // Fallback for cases where direction is UNKNOWN
    return type == 'DEPOSIT' || type == 'INVESTMENT_RETURN' || type == 'REFUND';
  }
}
