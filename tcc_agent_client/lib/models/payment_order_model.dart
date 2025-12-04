class PaymentOrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userMobile;
  final String? userEmail;
  final String recipientName;
  final String recipientMobile;
  final String? recipientEmail;
  final String recipientNationalId;
  final double amount;
  final String verificationCode;
  final String status; // pending, accepted, in_process, completed, cancelled
  final String? assignedAgentId;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? cancellationReason;

  PaymentOrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userMobile,
    this.userEmail,
    required this.recipientName,
    required this.recipientMobile,
    this.recipientEmail,
    required this.recipientNationalId,
    required this.amount,
    required this.verificationCode,
    required this.status,
    this.assignedAgentId,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.cancellationReason,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProcess => status == 'in_process';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      id: json['id'] ?? json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userMobile: json['user_mobile'] ?? '',
      userEmail: json['user_email'],
      recipientName: json['recipient_name'] ?? '',
      recipientMobile: json['recipient_mobile'] ?? '',
      recipientEmail: json['recipient_email'],
      recipientNationalId: json['recipient_national_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      verificationCode: json['verification_code'] ?? '',
      status: json['status'] ?? 'pending',
      assignedAgentId: json['assigned_agent_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancellationReason: json['cancellation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_mobile': userMobile,
      'user_email': userEmail,
      'recipient_name': recipientName,
      'recipient_mobile': recipientMobile,
      'recipient_email': recipientEmail,
      'recipient_national_id': recipientNationalId,
      'amount': amount,
      'verification_code': verificationCode,
      'status': status,
      'assigned_agent_id': assignedAgentId,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
    };
  }

  PaymentOrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userMobile,
    String? userEmail,
    String? recipientName,
    String? recipientMobile,
    String? recipientEmail,
    String? recipientNationalId,
    double? amount,
    String? verificationCode,
    String? status,
    String? assignedAgentId,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? cancellationReason,
  }) {
    return PaymentOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userMobile: userMobile ?? this.userMobile,
      userEmail: userEmail ?? this.userEmail,
      recipientName: recipientName ?? this.recipientName,
      recipientMobile: recipientMobile ?? this.recipientMobile,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientNationalId: recipientNationalId ?? this.recipientNationalId,
      amount: amount ?? this.amount,
      verificationCode: verificationCode ?? this.verificationCode,
      status: status ?? this.status,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
