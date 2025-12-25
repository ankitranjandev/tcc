import 'dart:developer' as developer;

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profilePicture;
  final double walletBalance;
  final String kycStatus;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profilePicture,
    required this.walletBalance,
    this.kycStatus = 'PENDING',
  });

  String get fullName => '$firstName $lastName';
  
  // KYC Status helpers
  bool get isKycApproved => kycStatus.toUpperCase() == 'APPROVED';
  bool get isKycPending => kycStatus.toUpperCase() == 'PENDING';
  bool get isKycRejected => kycStatus.toUpperCase() == 'REJECTED';
  bool get isKycInProgress {
    final status = kycStatus.toUpperCase();
    return status == 'PENDING' ||
           status == 'PROCESSING' ||
           status == 'IN_PROGRESS' ||
           status == 'SUBMITTED';
  }
  bool get canMakeTransactions => isKycApproved;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    developer.log('🧑 UserModel.fromJson: Parsing user data', name: 'UserModel');
    developer.log('🧑 UserModel.fromJson: JSON keys: ${json.keys.toList()}', name: 'UserModel');

    // Log all profile picture related fields
    developer.log('🧑 UserModel.fromJson: profile_picture_url = ${json['profile_picture_url']}', name: 'UserModel');
    developer.log('🧑 UserModel.fromJson: profilePicture = ${json['profilePicture']}', name: 'UserModel');
    developer.log('🧑 UserModel.fromJson: profile_picture = ${json['profile_picture']}', name: 'UserModel');

    final profilePictureValue = json['profile_picture_url'] ?? json['profilePicture'] ?? json['profile_picture'];
    developer.log('🧑 UserModel.fromJson: Final profilePicture value: $profilePictureValue', name: 'UserModel');

    return UserModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: profilePictureValue,
      walletBalance: _parseDouble(json['walletBalance'] ?? json['wallet_balance']),
      kycStatus: json['kyc_status'] ?? json['kycStatus'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'walletBalance': walletBalance,
      'kycStatus': kycStatus,
    };
  }

  factory UserModel.mock() {
    return UserModel(
      id: '1',
      firstName: 'Andrew',
      lastName: 'Johnson',
      email: 'andrew.johnson@example.com',
      phone: '+232 78 123 4567',
      walletBalance: 34000.00,
      kycStatus: 'APPROVED',
    );
  }
}
