/// Transaction Model
class TransactionModel {
  final String id;
  final String userId;
  final String? userName;
  final TransactionType type;
  final double amount;
  final double fee;
  final double total;
  final TransactionStatus status;
  final String? paymentMethod;
  final String? agentId;
  final String? agentName;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.type,
    required this.amount,
    required this.fee,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.agentId,
    this.agentName,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  /// Create TransactionModel from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Build user name from available fields
    String? userName;
    if (json['from_user_first_name'] != null && json['from_user_last_name'] != null) {
      userName = '${json['from_user_first_name']} ${json['from_user_last_name']}';
    } else if (json['user_name'] != null) {
      userName = json['user_name'] as String;
    }

    // Build agent name from available fields
    String? agentName;
    if (json['to_user_first_name'] != null && json['to_user_last_name'] != null) {
      agentName = '${json['to_user_first_name']} ${json['to_user_last_name']}';
    } else if (json['agent_name'] != null) {
      agentName = json['agent_name'] as String;
    }

    return TransactionModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['from_user_id'] ?? '') as String,
      userName: userName,
      type: _parseTransactionType(json['type'] as String),
      amount: _parseAmount(json['amount']),
      fee: _parseAmount(json['fee']),
      total: _parseAmount(json['total'] ?? json['net_amount']),
      status: _parseTransactionStatus(json['status'] as String),
      paymentMethod: json['payment_method'] as String?,
      agentId: (json['agent_id'] ?? json['to_user_id']) as String?,
      agentName: agentName,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: (json['completed_at'] ?? json['processed_at']) != null
          ? DateTime.parse((json['completed_at'] ?? json['processed_at']) as String)
          : null,
    );
  }

  /// Parse amount from dynamic value (handles both string and numeric values)
  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse transaction type from string (supports both camelCase and UPPER_SNAKE_CASE)
  static TransactionType _parseTransactionType(String type) {
    final lowerType = type.toLowerCase();
    switch (lowerType) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'transfer':
        return TransactionType.transfer;
      case 'bill_payment':
      case 'billpayment':
        return TransactionType.billPayment;
      case 'investment':
        return TransactionType.investment;
      case 'investment_return':
      case 'investmentreturn':
        return TransactionType.investmentReturn;
      case 'voting':
      case 'vote':
        return TransactionType.voting;
      case 'refund':
        return TransactionType.refund;
      case 'commission':
        return TransactionType.commission;
      case 'agent_credit':
      case 'agentcredit':
        return TransactionType.agentCredit;
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }

  /// Parse transaction status from string (supports both camelCase and UPPER_SNAKE_CASE)
  static TransactionStatus _parseTransactionStatus(String status) {
    final lowerStatus = status.toLowerCase();
    switch (lowerStatus) {
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'rejected':
        return TransactionStatus.rejected;
      default:
        throw ArgumentError('Unknown transaction status: $status');
    }
  }

  /// Convert TransactionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'type': type.name,
      'amount': amount,
      'fee': fee,
      'total': total,
      'status': status.name,
      'payment_method': paymentMethod,
      'agent_id': agentId,
      'agent_name': agentName,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Copy with method
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    TransactionType? type,
    double? amount,
    double? fee,
    double? total,
    TransactionStatus? status,
    String? paymentMethod,
    String? agentId,
    String? agentName,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Transaction Type Enum
enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  billPayment,
  investment,
  investmentReturn,
  voting,
  refund,
  commission,
  agentCredit;

  String get name {
    switch (this) {
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.transfer:
        return 'transfer';
      case TransactionType.billPayment:
        return 'billPayment';
      case TransactionType.investment:
        return 'investment';
      case TransactionType.investmentReturn:
        return 'investmentReturn';
      case TransactionType.voting:
        return 'voting';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.commission:
        return 'commission';
      case TransactionType.agentCredit:
        return 'agentCredit';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.billPayment:
        return 'Bill Payment';
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.investmentReturn:
        return 'Investment Return';
      case TransactionType.voting:
        return 'E-Voting';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.commission:
        return 'Commission';
      case TransactionType.agentCredit:
        return 'Agent Credit';
    }
  }
}

/// Transaction Status Enum
enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  rejected;

  String get name {
    switch (this) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.processing:
        return 'processing';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.cancelled:
        return 'cancelled';
      case TransactionStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.rejected:
        return 'Rejected';
    }
  }
}
