/// User Model (for admin to manage)
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? address;
  final KycStatus kycStatus;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastActive;
  final double walletBalance;
  final bool hasBankDetails;
  final bool hasInvestments;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.address,
    required this.kycStatus,
    required this.status,
    required this.createdAt,
    this.lastActive,
    required this.walletBalance,
    required this.hasBankDetails,
    required this.hasInvestments,
  });

  String get fullName => '$firstName $lastName';

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
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

    // Parse user status - handle is_active boolean or status string
    UserStatus parseUserStatus(Map<String, dynamic> json) {
      if (json.containsKey('status')) {
        final statusStr = json['status'] as String;
        final lowerStatus = statusStr.toLowerCase();
        switch (lowerStatus) {
          case 'active':
            return UserStatus.active;
          case 'inactive':
            return UserStatus.inactive;
          case 'suspended':
            return UserStatus.suspended;
          default:
            return UserStatus.active;
        }
      } else if (json.containsKey('is_active')) {
        final isActive = json['is_active'] as bool;
        return isActive ? UserStatus.active : UserStatus.inactive;
      }
      return UserStatus.active;
    }

    // Helper to parse numeric values that might be strings
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      kycStatus: parseKycStatus(json['kyc_status'] as String),
      status: parseUserStatus(json),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActive: json['last_active'] != null || json['last_login_at'] != null
          ? DateTime.parse((json['last_active'] ?? json['last_login_at']) as String)
          : null,
      walletBalance: parseDouble(json['wallet_balance']),
      hasBankDetails: json['has_bank_details'] as bool? ?? false,
      hasInvestments: json['has_investments'] as bool? ?? false,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'kyc_status': kycStatus.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'wallet_balance': walletBalance,
      'has_bank_details': hasBankDetails,
      'has_investments': hasInvestments,
    };
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    KycStatus? kycStatus,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastActive,
    double? walletBalance,
    bool? hasBankDetails,
    bool? hasInvestments,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      kycStatus: kycStatus ?? this.kycStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      walletBalance: walletBalance ?? this.walletBalance,
      hasBankDetails: hasBankDetails ?? this.hasBankDetails,
      hasInvestments: hasInvestments ?? this.hasInvestments,
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

/// User Status Enum
enum UserStatus {
  active,
  inactive,
  suspended;

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }
}
