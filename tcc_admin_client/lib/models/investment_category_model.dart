import 'product_version_model.dart';

/// Investment Category Model
class InvestmentCategoryModel {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final List<String> subCategories;
  final String? iconUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.subCategories,
    this.iconUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentCategoryModel.fromJson(Map<String, dynamic> json) {
    return InvestmentCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      subCategories: json['sub_categories'] != null
          ? List<String>.from(json['sub_categories'] as List)
          : [],
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      if (description != null) 'description': description,
      'sub_categories': subCategories,
      if (iconUrl != null) 'icon_url': iconUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if category has sub-categories
  bool get hasSubCategories => subCategories.isNotEmpty;

  /// Get status label
  String get statusLabel => isActive ? 'Active' : 'Inactive';
}

/// Category with Versions Model
class InvestmentCategoryWithVersionsModel {
  final InvestmentCategoryModel category;
  final List<TenureWithVersionHistoryModel> tenures;

  InvestmentCategoryWithVersionsModel({
    required this.category,
    required this.tenures,
  });

  factory InvestmentCategoryWithVersionsModel.fromJson(
      Map<String, dynamic> json) {
    return InvestmentCategoryWithVersionsModel(
      category: InvestmentCategoryModel.fromJson(
          json['category'] as Map<String, dynamic>),
      tenures: (json['tenures'] as List)
          .map((t) => TenureWithVersionHistoryModel.fromJson(
              t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toJson(),
      'tenures': tenures.map((t) => t.toJson()).toList(),
    };
  }

  /// Get total investment count across all tenures
  int get totalInvestments =>
      tenures.fold(0, (sum, t) => sum + t.investmentCount);

  /// Get total amount across all tenures
  double get totalAmount => tenures.fold(0.0, (sum, t) => sum + t.totalAmount);

  /// Get number of tenures
  int get tenureCount => tenures.length;
}

/// Investment Unit Model
class InvestmentUnitModel {
  final String id;
  final String category;
  final String unitName;
  final double unitPrice;
  final String? description;
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentUnitModel({
    required this.id,
    required this.category,
    required this.unitName,
    required this.unitPrice,
    this.description,
    this.iconUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentUnitModel.fromJson(Map<String, dynamic> json) {
    return InvestmentUnitModel(
      id: json['id'] as String,
      category: json['category'] as String,
      unitName: json['unit_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      displayOrder: json['display_order'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'unit_name': unitName,
      'unit_price': unitPrice,
      if (description != null) 'description': description,
      if (iconUrl != null) 'icon_url': iconUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted price
  String get formattedPrice => 'TCC ${unitPrice.toStringAsFixed(2)}';

  /// Get status label
  String get statusLabel => isActive ? 'Active' : 'Inactive';
}
