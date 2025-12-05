/// Consumer Model (for managing TCC user client app consumers)
class ConsumerModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? countryCode;
  final DateTime? dateOfBirth;
  final String? address;
  final KycStatus kycStatus;
  final ConsumerStatus status;
  final DateTime createdAt;
  final DateTime? lastActive;
  final double walletBalance;
  final bool hasBankDetails;
  final bool hasInvestments;
  final int totalTransactions;
  final double totalInvested;

  ConsumerModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.countryCode,
    this.dateOfBirth,
    this.address,
    required this.kycStatus,
    required this.status,
    required this.createdAt,
    this.lastActive,
    required this.walletBalance,
    required this.hasBankDetails,
    required this.hasInvestments,
    this.totalTransactions = 0,
    this.totalInvested = 0.0,
  });

  String get fullName => '$firstName $lastName';

  /// Create ConsumerModel from JSON
  factory ConsumerModel.fromJson(Map<String, dynamic> json) {
    // Parse KYC status - handle both uppercase and lowercase
    KycStatus parseKycStatus(String status) {
      final lowerStatus = status.toLowerCase();
      switch (lowerStatus) {
        case 'pending':
          return KycStatus.pending;
        case 'approved':
          return KycStatus.approved;
        case 'rejected':
          return KycStatus.rejected;
        case 'submitted':
        case 'under_review':
        case 'underreview':
          return KycStatus.underReview;
        default:
          return KycStatus.pending;
      }
    }

    // Parse consumer status - handle is_active boolean or status string
    ConsumerStatus parseConsumerStatus(Map<String, dynamic> json) {
      if (json.containsKey('status')) {
        final statusStr = json['status'] as String;
        final lowerStatus = statusStr.toLowerCase();
        switch (lowerStatus) {
          case 'active':
            return ConsumerStatus.active;
          case 'inactive':
            return ConsumerStatus.inactive;
          case 'suspended':
            return ConsumerStatus.suspended;
          default:
            return ConsumerStatus.active;
        }
      } else if (json.containsKey('is_active')) {
        final isActive = json['is_active'] as bool;
        return isActive ? ConsumerStatus.active : ConsumerStatus.inactive;
      }
      return ConsumerStatus.active;
    }

    // Helper to parse numeric values that might be strings
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    return ConsumerModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      countryCode: json['country_code'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      kycStatus: parseKycStatus(json['kyc_status'] as String? ?? 'pending'),
      status: parseConsumerStatus(json),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActive: json['last_active'] != null || json['last_login_at'] != null
          ? DateTime.parse(
              (json['last_active'] ?? json['last_login_at']) as String,
            )
          : null,
      walletBalance: parseDouble(json['wallet_balance']),
      hasBankDetails: json['has_bank_details'] as bool? ?? false,
      hasInvestments: json['has_investments'] as bool? ?? false,
      totalTransactions: parseInt(json['total_transactions']),
      totalInvested: parseDouble(json['total_invested']),
    );
  }

  /// Convert ConsumerModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'country_code': countryCode,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'kyc_status': kycStatus.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'wallet_balance': walletBalance,
      'has_bank_details': hasBankDetails,
      'has_investments': hasInvestments,
      'total_transactions': totalTransactions,
      'total_invested': totalInvested,
    };
  }

  /// Copy with method
  ConsumerModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? countryCode,
    DateTime? dateOfBirth,
    String? address,
    KycStatus? kycStatus,
    ConsumerStatus? status,
    DateTime? createdAt,
    DateTime? lastActive,
    double? walletBalance,
    bool? hasBankDetails,
    bool? hasInvestments,
    int? totalTransactions,
    double? totalInvested,
  }) {
    return ConsumerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      kycStatus: kycStatus ?? this.kycStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      walletBalance: walletBalance ?? this.walletBalance,
      hasBankDetails: hasBankDetails ?? this.hasBankDetails,
      hasInvestments: hasInvestments ?? this.hasInvestments,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalInvested: totalInvested ?? this.totalInvested,
    );
  }
}

/// KYC Status Enum
enum KycStatus {
  pending,
  approved,
  rejected,
  underReview;

  String get displayName {
    switch (this) {
      case KycStatus.pending:
        return 'Pending';
      case KycStatus.approved:
        return 'Approved';
      case KycStatus.rejected:
        return 'Rejected';
      case KycStatus.underReview:
        return 'Under Review';
    }
  }
}

/// Consumer Status Enum
enum ConsumerStatus {
  active,
  inactive,
  suspended;

  String get displayName {
    switch (this) {
      case ConsumerStatus.active:
        return 'Active';
      case ConsumerStatus.inactive:
        return 'Inactive';
      case ConsumerStatus.suspended:
        return 'Suspended';
    }
  }
}
