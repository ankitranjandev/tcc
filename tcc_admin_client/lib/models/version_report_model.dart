/// Version Statistics Model
class VersionStatisticsModel {
  final String versionId;
  final int versionNumber;
  final double returnPercentage;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final bool isCurrent;
  final int investmentCount;
  final double totalAmount;
  final int activeCount;

  VersionStatisticsModel({
    required this.versionId,
    required this.versionNumber,
    required this.returnPercentage,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.isCurrent,
    required this.investmentCount,
    required this.totalAmount,
    required this.activeCount,
  });

  factory VersionStatisticsModel.fromJson(Map<String, dynamic> json) {
    return VersionStatisticsModel(
      versionId: json['version_id'] as String,
      versionNumber: json['version_number'] as int,
      returnPercentage: (json['return_percentage'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveUntil: json['effective_until'] != null
          ? DateTime.parse(json['effective_until'] as String)
          : null,
      isCurrent: json['is_current'] as bool,
      investmentCount: json['investment_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      activeCount: json['active_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version_id': versionId,
      'version_number': versionNumber,
      'return_percentage': returnPercentage,
      'effective_from': effectiveFrom.toIso8601String(),
      if (effectiveUntil != null)
        'effective_until': effectiveUntil!.toIso8601String(),
      'is_current': isCurrent,
      'investment_count': investmentCount,
      'total_amount': totalAmount,
      'active_count': activeCount,
    };
  }

  /// Get average investment amount
  double get averageAmount {
    if (investmentCount == 0) return 0;
    return totalAmount / investmentCount;
  }

  /// Get percentage of active investments
  double get activePercentage {
    if (investmentCount == 0) return 0;
    return (activeCount / investmentCount) * 100;
  }

  /// Get status label
  String get statusLabel => isCurrent ? 'Current' : 'Historical';
}

/// Version Report Summary Model
class VersionReportSummaryModel {
  final int totalVersions;
  final int totalInvestments;
  final double totalAmount;
  final double currentRate;

  VersionReportSummaryModel({
    required this.totalVersions,
    required this.totalInvestments,
    required this.totalAmount,
    required this.currentRate,
  });

  factory VersionReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return VersionReportSummaryModel(
      totalVersions: json['total_versions'] as int,
      totalInvestments: json['total_investments'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currentRate: (json['current_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_versions': totalVersions,
      'total_investments': totalInvestments,
      'total_amount': totalAmount,
      'current_rate': currentRate,
    };
  }

  /// Get average investment amount
  double get averageAmount {
    if (totalInvestments == 0) return 0;
    return totalAmount / totalInvestments;
  }
}

/// Version Report Model
class VersionReportModel {
  final String tenureId;
  final String category;
  final int tenureMonths;
  final List<VersionStatisticsModel> versions;
  final VersionReportSummaryModel summary;

  VersionReportModel({
    required this.tenureId,
    required this.category,
    required this.tenureMonths,
    required this.versions,
    required this.summary,
  });

  factory VersionReportModel.fromJson(Map<String, dynamic> json) {
    return VersionReportModel(
      tenureId: json['tenure_id'] as String,
      category: json['category'] as String,
      tenureMonths: json['tenure_months'] as int,
      versions: (json['versions'] as List)
          .map((v) =>
              VersionStatisticsModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      summary: VersionReportSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenure_id': tenureId,
      'category': category,
      'tenure_months': tenureMonths,
      'versions': versions.map((v) => v.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }

  /// Get current version
  VersionStatisticsModel? get currentVersion {
    try {
      return versions.firstWhere((v) => v.isCurrent);
    } catch (e) {
      return null;
    }
  }

  /// Get historical versions
  List<VersionStatisticsModel> get historicalVersions {
    return versions.where((v) => !v.isCurrent).toList();
  }

  /// Get product display name
  String get productDisplayName => '$category - $tenureMonths months';

  /// Calculate total rate changes
  int get totalRateChanges => versions.length > 1 ? versions.length - 1 : 0;

  /// Get version adoption rate (current version vs all)
  double get currentVersionAdoptionRate {
    if (summary.totalInvestments == 0) return 0;
    final currentVersion = this.currentVersion;
    if (currentVersion == null) return 0;
    return (currentVersion.investmentCount / summary.totalInvestments) * 100;
  }
}
