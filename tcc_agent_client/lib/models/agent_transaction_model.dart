class AgentTransactionModel {
  final String id;
  final String agentId;
  final String? userId;
  final String type; // deposit, withdrawal, transfer, commission, credit_request
  final String status; // pending, processing, completed, failed, cancelled
  final double amount;
  final double? commissionAmount;
  final String? paymentMethod; // cash, bank, mobile_money, airtel_money
  final String? description;
  final TransactionMetadata? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  AgentTransactionModel({
    required this.id,
    required this.agentId,
    this.userId,
    required this.type,
    required this.status,
    required this.amount,
    this.commissionAmount,
    this.paymentMethod,
    this.description,
    this.metadata,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  bool get isDeposit => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isTransfer => type == 'transfer';
  bool get isCommission => type == 'commission';
  bool get isCreditRequest => type == 'credit_request';

  factory AgentTransactionModel.fromJson(Map<String, dynamic> json) {
    return AgentTransactionModel(
      id: json['id'] ?? json['transaction_id'] ?? '',
      agentId: json['agent_id'] ?? '',
      userId: json['user_id'],
      type: json['type'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0.0).toDouble(),
      commissionAmount: json['commission_amount'] != null
          ? (json['commission_amount']).toDouble()
          : null,
      paymentMethod: json['payment_method'],
      description: json['description'],
      metadata: json['metadata'] != null
          ? TransactionMetadata.fromJson(json['metadata'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      failureReason: json['failure_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'user_id': userId,
      'type': type,
      'status': status,
      'amount': amount,
      'commission_amount': commissionAmount,
      'payment_method': paymentMethod,
      'description': description,
      'metadata': metadata?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
  }

  AgentTransactionModel copyWith({
    String? id,
    String? agentId,
    String? userId,
    String? type,
    String? status,
    double? amount,
    double? commissionAmount,
    String? paymentMethod,
    String? description,
    TransactionMetadata? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return AgentTransactionModel(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class TransactionMetadata {
  final String? userNationalId;
  final String? userPhotoUrl;
  final String? receiptUrl;
  final Map<int, int>? currencyDenominations; // denomination -> count
  final String? verificationCode;
  final String? recipientName;
  final String? recipientMobile;
  final String? recipientEmail;

  TransactionMetadata({
    this.userNationalId,
    this.userPhotoUrl,
    this.receiptUrl,
    this.currencyDenominations,
    this.verificationCode,
    this.recipientName,
    this.recipientMobile,
    this.recipientEmail,
  });

  factory TransactionMetadata.fromJson(Map<String, dynamic> json) {
    Map<int, int>? denominations;
    if (json['currency_denominations'] != null) {
      denominations = {};
      final Map<String, dynamic> denoMap = json['currency_denominations'];
      denoMap.forEach((key, value) {
        denominations![int.parse(key)] = value as int;
      });
    }

    return TransactionMetadata(
      userNationalId: json['user_national_id'],
      userPhotoUrl: json['user_photo_url'],
      receiptUrl: json['receipt_url'],
      currencyDenominations: denominations,
      verificationCode: json['verification_code'],
      recipientName: json['recipient_name'],
      recipientMobile: json['recipient_mobile'],
      recipientEmail: json['recipient_email'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, int>? denoMap;
    if (currencyDenominations != null) {
      denoMap = {};
      currencyDenominations!.forEach((key, value) {
        denoMap![key.toString()] = value;
      });
    }

    return {
      'user_national_id': userNationalId,
      'user_photo_url': userPhotoUrl,
      'receipt_url': receiptUrl,
      'currency_denominations': denoMap,
      'verification_code': verificationCode,
      'recipient_name': recipientName,
      'recipient_mobile': recipientMobile,
      'recipient_email': recipientEmail,
    };
  }
}
