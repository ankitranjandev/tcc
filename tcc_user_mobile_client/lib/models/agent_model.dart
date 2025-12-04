class AgentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String? profilePictureUrl;
  final String bankName;
  final String bankBranchName;
  final String bankBranchAddress;
  final String? ifscCode;
  final double latitude;
  final double longitude;
  final String address;
  final bool isActive;
  final double? rating;
  final int? totalTransactions;
  final double commissionRate;

  AgentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    this.profilePictureUrl,
    required this.bankName,
    required this.bankBranchName,
    required this.bankBranchAddress,
    this.ifscCode,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isActive = true,
    this.rating,
    this.totalTransactions,
    this.commissionRate = 0.0,
  });

  String get fullName => '$firstName $lastName';

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      bankName: json['bankName'] ?? '',
      bankBranchName: json['bankBranchName'] ?? '',
      bankBranchAddress: json['bankBranchAddress'] ?? '',
      ifscCode: json['ifscCode'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      isActive: json['isActive'] ?? true,
      rating: json['rating']?.toDouble(),
      totalTransactions: json['totalTransactions'],
      commissionRate: (json['commissionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'bankName': bankName,
      'bankBranchName': bankBranchName,
      'bankBranchAddress': bankBranchAddress,
      'ifscCode': ifscCode,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'isActive': isActive,
      'rating': rating,
      'totalTransactions': totalTransactions,
      'commissionRate': commissionRate,
    };
  }

  double distanceFrom(double userLat, double userLon) {
    // Simple distance calculation using approximate formula
    const double kmPerDegree = 111.0;

    double latDiff = (latitude - userLat).abs();
    double lonDiff = (longitude - userLon).abs();

    // Approximate distance calculation
    return ((latDiff * latDiff) + (lonDiff * lonDiff)) * kmPerDegree;
  }
}
