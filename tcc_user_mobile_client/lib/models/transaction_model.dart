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
