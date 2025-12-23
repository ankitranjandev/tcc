/// Product Version Model
/// Represents a version of an investment product with rate history
class ProductVersionModel {
  final String id;
  final String tenureId;
  final int versionNumber;
  final double returnPercentage;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final bool isCurrent;
  final String? changeReason;
  final String? changedBy;
  final String? adminName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVersionModel({
    required this.id,
    required this.tenureId,
    required this.versionNumber,
    required this.returnPercentage,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.isCurrent,
    this.changeReason,
    this.changedBy,
    this.adminName,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVersionModel.fromJson(Map<String, dynamic> json) {
    return ProductVersionModel(
      id: json['id'] as String,
      tenureId: json['tenure_id'] as String,
      versionNumber: json['version_number'] as int,
      returnPercentage: (json['return_percentage'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveUntil: json['effective_until'] != null
          ? DateTime.parse(json['effective_until'] as String)
          : null,
      isCurrent: json['is_current'] as bool,
      changeReason: json['change_reason'] as String?,
      changedBy: json['changed_by'] as String?,
      adminName: json['admin_name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenure_id': tenureId,
      'version_number': versionNumber,
      'return_percentage': returnPercentage,
      'effective_from': effectiveFrom.toIso8601String(),
      if (effectiveUntil != null)
        'effective_until': effectiveUntil!.toIso8601String(),
      'is_current': isCurrent,
      if (changeReason != null) 'change_reason': changeReason,
      if (changedBy != null) 'changed_by': changedBy,
      if (adminName != null) 'admin_name': adminName,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get duration this version was active
  Duration? get activeDuration {
    if (effectiveUntil == null) {
      return DateTime.now().difference(effectiveFrom);
    }
    return effectiveUntil!.difference(effectiveFrom);
  }

  /// Get status label
  String get statusLabel => isCurrent ? 'Current' : 'Historical';

  /// Get formatted date range
  String get dateRange {
    final startDate = _formatDate(effectiveFrom);
    if (effectiveUntil == null) {
      return '$startDate - Present';
    }
    final endDate = _formatDate(effectiveUntil!);
    return '$startDate - $endDate';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Investment Tenure Model
class InvestmentTenureModel {
  final String id;
  final String categoryId;
  final int durationMonths;
  final double returnPercentage;
  final String? agreementTemplateUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentTenureModel({
    required this.id,
    required this.categoryId,
    required this.durationMonths,
    required this.returnPercentage,
    this.agreementTemplateUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentTenureModel.fromJson(Map<String, dynamic> json) {
    return InvestmentTenureModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      durationMonths: json['duration_months'] as int,
      returnPercentage: (json['return_percentage'] as num).toDouble(),
      agreementTemplateUrl: json['agreement_template_url'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'duration_months': durationMonths,
      'return_percentage': returnPercentage,
      if (agreementTemplateUrl != null)
        'agreement_template_url': agreementTemplateUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get display label
  String get displayLabel => '$durationMonths months @ $returnPercentage%';
}

/// Tenure with Version History Model
class TenureWithVersionHistoryModel {
  final InvestmentTenureModel tenure;
  final ProductVersionModel currentVersion;
  final List<ProductVersionModel> versionHistory;
  final int investmentCount;
  final double totalAmount;

  TenureWithVersionHistoryModel({
    required this.tenure,
    required this.currentVersion,
    required this.versionHistory,
    required this.investmentCount,
    required this.totalAmount,
  });

  factory TenureWithVersionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TenureWithVersionHistoryModel(
      tenure: InvestmentTenureModel.fromJson(
          json['tenure'] as Map<String, dynamic>),
      currentVersion: ProductVersionModel.fromJson(
          json['current_version'] as Map<String, dynamic>),
      versionHistory: (json['version_history'] as List)
          .map((v) => ProductVersionModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      investmentCount: json['investment_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenure': tenure.toJson(),
      'current_version': currentVersion.toJson(),
      'version_history': versionHistory.map((v) => v.toJson()).toList(),
      'investment_count': investmentCount,
      'total_amount': totalAmount,
    };
  }

  /// Get number of versions
  int get versionCount => versionHistory.length;

  /// Check if has multiple versions
  bool get hasMultipleVersions => versionHistory.length > 1;
}
