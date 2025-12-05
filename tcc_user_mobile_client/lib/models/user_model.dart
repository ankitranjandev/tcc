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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profilePicture'],
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      kycStatus: json['kycStatus'] ?? 'PENDING',
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
