/// Investment Opportunity Model
/// Represents an investment opportunity created by admin
class InvestmentOpportunityModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final double minInvestment;
  final double maxInvestment;
  final int tenureMonths;
  final double returnRate;
  final int totalUnits;
  final int availableUnits;
  final String? imageUrl;
  final bool isActive;
  final int displayOrder;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentOpportunityModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.minInvestment,
    required this.maxInvestment,
    required this.tenureMonths,
    required this.returnRate,
    required this.totalUnits,
    required this.availableUnits,
    this.imageUrl,
    required this.isActive,
    required this.displayOrder,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentOpportunityModel.fromJson(Map<String, dynamic> json) {
    return InvestmentOpportunityModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      minInvestment: (json['minInvestment'] as num).toDouble(),
      maxInvestment: (json['maxInvestment'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      returnRate: (json['returnRate'] as num).toDouble(),
      totalUnits: json['totalUnits'] as int,
      availableUnits: json['availableUnits'] as int,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'title': title,
      'description': description,
      'minInvestment': minInvestment,
      'maxInvestment': maxInvestment,
      'tenureMonths': tenureMonths,
      'returnRate': returnRate,
      'totalUnits': totalUnits,
      'availableUnits': availableUnits,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  int get soldUnits => totalUnits - availableUnits;

  double get soldPercentage => totalUnits > 0 ? (soldUnits / totalUnits) * 100 : 0;

  bool get isHidden => !isActive;

  bool get isVisible => isActive;

  String get statusText => isActive ? 'Active' : 'Hidden';

  String get categoryDisplayName {
    switch (categoryName) {
      case 'AGRICULTURE':
        return 'Agriculture';
      case 'EDUCATION':
        return 'Education';
      default:
        return categoryName;
    }
  }
}
