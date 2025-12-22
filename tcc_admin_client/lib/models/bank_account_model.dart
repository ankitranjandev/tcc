/// Model class representing a bank account in admin view
class BankAccountModel {
  final String id;
  final String userId;
  final String bankName;
  final String accountNumberMasked;
  final String accountHolderName;
  final bool isPrimary;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccountModel({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountNumberMasked,
    required this.accountHolderName,
    required this.isPrimary,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a BankAccountModel from JSON
  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankName: json['bank_name'] as String,
      accountNumberMasked: json['account_number_masked'] as String,
      accountHolderName: json['account_holder_name'] as String,
      isPrimary: json['is_primary'] as bool,
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert BankAccountModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_name': bankName,
      'account_number_masked': accountNumberMasked,
      'account_holder_name': accountHolderName,
      'is_primary': isPrimary,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
