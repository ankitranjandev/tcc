class BankAccountModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String branchAddress;
  final String? ifscCode;
  final String? swiftCode;
  final String? routingNumber;
  final bool isPrimary;
  final DateTime createdAt;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.branchAddress,
    this.ifscCode,
    this.swiftCode,
    this.routingNumber,
    this.isPrimary = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper: Returns masked account number (e.g., "****1234")
  String get displayAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '****$lastFour';
  }

  // Helper: Returns account type label based on codes present
  String get accountTypeLabel {
    if (ifscCode != null && ifscCode!.isNotEmpty) return 'Domestic';
    if (swiftCode != null && swiftCode!.isNotEmpty) return 'International';
    if (routingNumber != null && routingNumber!.isNotEmpty) return 'US';
    return 'Domestic';
  }

  // Helper: Check if this is an international account
  bool get isInternational => swiftCode != null && swiftCode!.isNotEmpty;

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] ?? '',
      bankName: json['bank_name'] ?? json['bankName'] ?? '',
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      accountHolderName: json['account_holder_name'] ?? json['accountHolderName'] ?? '',
      branchAddress: json['branch_address'] ?? json['branchAddress'] ?? '',
      ifscCode: json['ifsc_code'] ?? json['ifscCode'],
      swiftCode: json['swift_code'] ?? json['swiftCode'],
      routingNumber: json['routing_number'] ?? json['routingNumber'],
      isPrimary: json['is_primary'] ?? json['isPrimary'] ?? false,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'branch_address': branchAddress,
      if (ifscCode != null) 'ifsc_code': ifscCode,
      if (swiftCode != null) 'swift_code': swiftCode,
      if (routingNumber != null) 'routing_number': routingNumber,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // CopyWith for immutable updates
  BankAccountModel copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    String? branchAddress,
    String? ifscCode,
    String? swiftCode,
    String? routingNumber,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      branchAddress: branchAddress ?? this.branchAddress,
      ifscCode: ifscCode ?? this.ifscCode,
      swiftCode: swiftCode ?? this.swiftCode,
      routingNumber: routingNumber ?? this.routingNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
