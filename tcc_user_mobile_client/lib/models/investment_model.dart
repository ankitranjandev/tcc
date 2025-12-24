class InvestmentModel {
  final String id;
  final String name;
  final String category;
  final double amount;
  final double roi;
  final int period; // in months
  final double expectedReturn;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.roi,
    required this.period,
    required this.expectedReturn,
    required this.startDate,
    required this.endDate,
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? startDate;

  int get daysLeft => endDate.difference(DateTime.now()).inDays;
  double get progress => DateTime.now().difference(startDate).inDays /
                          endDate.difference(startDate).inDays;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['title'] as String? ?? 'Investment',
      category: json['category'] as String? ?? json['categoryName'] as String? ?? 'General',
      amount: (json['amount'] as num).toDouble(),
      roi: (json['roi'] as num?)?.toDouble() ?? (json['returnRate'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as int? ?? json['tenureMonths'] as int? ?? 12,
      expectedReturn: (json['expectedReturn'] as num?)?.toDouble() ??
                      (json['totalReturn'] as num?)?.toDouble() ??
                      (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String? ?? json['createdAt'] as String),
      endDate: DateTime.parse(json['endDate'] as String? ?? json['maturityDate'] as String),
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'roi': roi,
      'period': period,
      'expectedReturn': expectedReturn,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class InvestmentProduct {
  final String id;
  final String name;
  final String unit;
  final double price;
  final double roi;
  final int minPeriod;
  final String description;
  final String category;

  InvestmentProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.roi,
    required this.minPeriod,
    required this.description,
    required this.category,
  });
}

/// Investment Opportunity Model (from API)
class InvestmentOpportunity {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentOpportunity({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentOpportunity.fromJson(Map<String, dynamic> json) {
    return InvestmentOpportunity(
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  int get soldUnits => totalUnits - availableUnits;
  double get soldPercentage => totalUnits > 0 ? (soldUnits / totalUnits) * 100 : 0;
  bool get hasUnitsAvailable => availableUnits > 0;

  String get categoryDisplayName {
    switch (categoryName.toUpperCase()) {
      case 'AGRICULTURE':
        return 'Agriculture';
      case 'EDUCATION':
        return 'Education';
      case 'MINERALS':
        return 'Minerals';
      default:
        return categoryName;
    }
  }
}
