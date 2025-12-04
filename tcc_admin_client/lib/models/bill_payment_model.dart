/// Bill Payment Model
/// Represents a bill payment transaction
class BillPaymentModel {
  final String id;
  final String transactionId;
  final String referenceNumber;
  final String billType;
  final BillProvider provider;
  final String accountNumber;
  final String customerName;
  final double amount;
  final double fee;
  final double totalAmount;
  final String status;
  final String description;
  final BillUser user;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  BillPaymentModel({
    required this.id,
    required this.transactionId,
    required this.referenceNumber,
    required this.billType,
    required this.provider,
    required this.accountNumber,
    required this.customerName,
    required this.amount,
    required this.fee,
    required this.totalAmount,
    required this.status,
    required this.description,
    required this.user,
    required this.createdAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory BillPaymentModel.fromJson(Map<String, dynamic> json) {
    return BillPaymentModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      referenceNumber: json['reference_number'] as String? ?? '',
      billType: json['bill_type'] as String,
      provider: BillProvider.fromJson(json['provider'] as Map<String, dynamic>),
      accountNumber: json['account_number'] as String,
      customerName: json['customer_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      description: json['description'] as String? ?? '',
      user: BillUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'reference_number': referenceNumber,
      'bill_type': billType,
      'provider': provider.toJson(),
      'account_number': accountNumber,
      'customer_name': customerName,
      'amount': amount,
      'fee': fee,
      'total_amount': totalAmount,
      'status': status,
      'description': description,
      'user': user.toJson(),
      'created_at': createdAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if payment is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Check if payment is pending
  bool get isPending => status == 'PENDING';

  /// Check if payment is failed
  bool get isFailed => status == 'FAILED';
}

/// Bill Provider Model
class BillProvider {
  final String name;
  final String? logoUrl;

  BillProvider({
    required this.name,
    this.logoUrl,
  });

  factory BillProvider.fromJson(Map<String, dynamic> json) {
    return BillProvider(
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
    };
  }
}

/// Bill User Model
class BillUser {
  final String id;
  final String name;
  final String email;

  BillUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory BillUser.fromJson(Map<String, dynamic> json) {
    return BillUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
