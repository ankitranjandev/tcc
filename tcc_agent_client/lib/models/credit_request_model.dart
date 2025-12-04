class CreditRequestModel {
  final String id;
  final String agentId;
  final double amount;
  final String status; // pending, approved, rejected
  final String? receiptUrl;
  final DateTime transactionDate;
  final String? bankReceiptDetails;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processingNotes;
  final String? rejectionReason;

  CreditRequestModel({
    required this.id,
    required this.agentId,
    required this.amount,
    required this.status,
    this.receiptUrl,
    required this.transactionDate,
    this.bankReceiptDetails,
    required this.createdAt,
    this.processedAt,
    this.processingNotes,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory CreditRequestModel.fromJson(Map<String, dynamic> json) {
    return CreditRequestModel(
      id: json['id'] ?? json['request_id'] ?? '',
      agentId: json['agent_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      receiptUrl: json['receipt_url'],
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      bankReceiptDetails: json['bank_receipt_details'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      processingNotes: json['processing_notes'],
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'amount': amount,
      'status': status,
      'receipt_url': receiptUrl,
      'transaction_date': transactionDate.toIso8601String(),
      'bank_receipt_details': bankReceiptDetails,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'processing_notes': processingNotes,
      'rejection_reason': rejectionReason,
    };
  }
}
