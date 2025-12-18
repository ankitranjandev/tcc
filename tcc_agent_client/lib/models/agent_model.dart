class AgentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? profilePictureUrl;
  final String status; // active, inactive, busy, pending_verification, verified, rejected
  final String? kycStatus; // PENDING, SUBMITTED, APPROVED, REJECTED
  final String? rejectionReason;
  final AgentBankDetails? bankDetails;
  final String? nationalIdUrl;
  final double walletBalance;
  final double commissionRate; // percentage
  final AgentLocation? location;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? lastActiveAt;
  final String? verificationNotes;

  AgentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.profilePictureUrl,
    required this.status,
    this.kycStatus,
    this.rejectionReason,
    this.bankDetails,
    this.nationalIdUrl,
    required this.walletBalance,
    required this.commissionRate,
    this.location,
    required this.createdAt,
    this.verifiedAt,
    this.lastActiveAt,
    this.verificationNotes,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status == 'active';
  bool get isVerified => status == 'verified' || status == 'active' || status == 'inactive' || status == 'busy';
  bool get isPendingVerification => status == 'pending_verification';
  bool get isRejected => status == 'rejected';

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] ?? json['agent_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? json['phone_number'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      status: json['status'] ?? 'pending_verification',
      kycStatus: json['kyc_status'] ?? json['verification_status'],
      rejectionReason: json['rejection_reason'] ?? json['verification_notes'],
      bankDetails: json['bank_details'] != null
          ? AgentBankDetails.fromJson(json['bank_details'])
          : null,
      nationalIdUrl: json['national_id_url'],
      walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0.0).toDouble(),
      location: json['location'] != null
          ? AgentLocation.fromJson(json['location'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
      verificationNotes: json['verification_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile_number': mobileNumber,
      'profile_picture_url': profilePictureUrl,
      'status': status,
      'kyc_status': kycStatus,
      'rejection_reason': rejectionReason,
      'bank_details': bankDetails?.toJson(),
      'national_id_url': nationalIdUrl,
      'wallet_balance': walletBalance,
      'commission_rate': commissionRate,
      'location': location?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'verification_notes': verificationNotes,
    };
  }

  AgentModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? profilePictureUrl,
    String? status,
    String? kycStatus,
    String? rejectionReason,
    AgentBankDetails? bankDetails,
    String? nationalIdUrl,
    double? walletBalance,
    double? commissionRate,
    AgentLocation? location,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? lastActiveAt,
    String? verificationNotes,
  }) {
    return AgentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      bankDetails: bankDetails ?? this.bankDetails,
      nationalIdUrl: nationalIdUrl ?? this.nationalIdUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      commissionRate: commissionRate ?? this.commissionRate,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }
}

class AgentBankDetails {
  final String bankName;
  final String branchAddress;
  final String ifscCode;
  final String accountHolderName;
  final String? accountNumber; // Encrypted/masked

  AgentBankDetails({
    required this.bankName,
    required this.branchAddress,
    required this.ifscCode,
    required this.accountHolderName,
    this.accountNumber,
  });

  factory AgentBankDetails.fromJson(Map<String, dynamic> json) {
    return AgentBankDetails(
      bankName: json['bank_name'] ?? '',
      branchAddress: json['branch_address'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      accountNumber: json['account_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'branch_address': branchAddress,
      'ifsc_code': ifscCode,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
    };
  }
}

class AgentLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime updatedAt;

  AgentLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.updatedAt,
  });

  factory AgentLocation.fromJson(Map<String, dynamic> json) {
    return AgentLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
