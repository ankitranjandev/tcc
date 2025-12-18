/// Agent Model
class AgentModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String location;
  final String? address;
  final String businessName;
  final String businessRegistrationNumber;
  final AgentStatus status;
  final KycStatus verificationStatus;
  final double commissionRate;
  final double totalCommissionEarned;
  final int totalTransactions;
  final double walletBalance;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool hasBankDetails;
  final String? nationalIdUrl;
  final Map<String, dynamic>? bankDetails;

  AgentModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.location,
    this.address,
    required this.businessName,
    required this.businessRegistrationNumber,
    required this.status,
    required this.verificationStatus,
    required this.commissionRate,
    required this.totalCommissionEarned,
    required this.totalTransactions,
    required this.walletBalance,
    required this.isAvailable,
    required this.createdAt,
    this.lastActive,
    required this.hasBankDetails,
    this.nationalIdUrl,
    this.bankDetails,
  });

  String get fullName => '$firstName $lastName';
  String get mobileNumber => phone;
  String get registrationNumber => businessRegistrationNumber;

  /// Create AgentModel from JSON
  factory AgentModel.fromJson(Map<String, dynamic> json) {
    // Parse KYC/Verification status - handle both uppercase and lowercase
    KycStatus parseVerificationStatus(String? status) {
      if (status == null) return KycStatus.pending;
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

    // Parse agent status from active_status boolean
    AgentStatus parseAgentStatus(bool? activeStatus, bool? isActive) {
      final active = activeStatus ?? isActive ?? false;
      return active ? AgentStatus.active : AgentStatus.inactive;
    }

    // Helper to parse numeric values that might be strings
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AgentModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      location: (json['location_address'] ?? json['location'] ?? '') as String,
      address: json['address'] as String?,
      businessName: (json['business_name'] ?? 'N/A') as String,
      businessRegistrationNumber: (json['business_registration_number'] ?? 'N/A') as String,
      status: parseAgentStatus(json['active_status'] as bool?, json['is_active'] as bool?),
      verificationStatus: parseVerificationStatus(json['verification_status'] as String?),
      commissionRate: parseDouble(json['commission_rate']),
      totalCommissionEarned: parseDouble(json['total_commission_earned']),
      totalTransactions: (json['total_transactions_processed'] ?? json['total_transactions']) as int? ?? 0,
      walletBalance: parseDouble(json['wallet_balance']),
      isAvailable: (json['is_available'] ?? json['active_status']) as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActive: (json['last_active'] ?? json['last_login_at']) != null
          ? DateTime.parse((json['last_active'] ?? json['last_login_at']) as String)
          : null,
      hasBankDetails: json['has_bank_details'] as bool? ?? false,
      nationalIdUrl: json['national_id_url'] as String?,
      bankDetails: json['bank_details'] as Map<String, dynamic>?,
    );
  }

  /// Convert AgentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'location': location,
      'address': address,
      'business_name': businessName,
      'business_registration_number': businessRegistrationNumber,
      'status': status.name,
      'verification_status': verificationStatus.name,
      'commission_rate': commissionRate,
      'total_commission_earned': totalCommissionEarned,
      'total_transactions': totalTransactions,
      'wallet_balance': walletBalance,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'has_bank_details': hasBankDetails,
      'national_id_url': nationalIdUrl,
      'bank_details': bankDetails,
    };
  }

  /// Copy with method
  AgentModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    String? address,
    String? businessName,
    String? businessRegistrationNumber,
    AgentStatus? status,
    KycStatus? verificationStatus,
    double? commissionRate,
    double? totalCommissionEarned,
    int? totalTransactions,
    double? walletBalance,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? hasBankDetails,
    String? nationalIdUrl,
    Map<String, dynamic>? bankDetails,
  }) {
    return AgentModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      commissionRate: commissionRate ?? this.commissionRate,
      totalCommissionEarned:
          totalCommissionEarned ?? this.totalCommissionEarned,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      walletBalance: walletBalance ?? this.walletBalance,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      hasBankDetails: hasBankDetails ?? this.hasBankDetails,
      nationalIdUrl: nationalIdUrl ?? this.nationalIdUrl,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}

/// Agent Status Enum
enum AgentStatus {
  active,
  inactive,
  suspended;

  String get displayName {
    switch (this) {
      case AgentStatus.active:
        return 'Active';
      case AgentStatus.inactive:
        return 'Inactive';
      case AgentStatus.suspended:
        return 'Suspended';
    }
  }
}

/// KYC Status Enum (shared with UserModel)
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
