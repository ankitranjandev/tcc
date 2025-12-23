/// Rate Change History Item Model
class RateChangeHistoryModel {
  final String versionId;
  final String tenureId;
  final String category;
  final String categoryDisplayName;
  final int tenureMonths;
  final int versionNumber;
  final double oldRate;
  final double newRate;
  final String? changeReason;
  final String? changedBy;
  final String? adminName;
  final DateTime effectiveFrom;
  final int usersNotified;
  final int activeInvestments;

  RateChangeHistoryModel({
    required this.versionId,
    required this.tenureId,
    required this.category,
    required this.categoryDisplayName,
    required this.tenureMonths,
    required this.versionNumber,
    required this.oldRate,
    required this.newRate,
    this.changeReason,
    this.changedBy,
    this.adminName,
    required this.effectiveFrom,
    required this.usersNotified,
    required this.activeInvestments,
  });

  factory RateChangeHistoryModel.fromJson(Map<String, dynamic> json) {
    return RateChangeHistoryModel(
      versionId: json['version_id'] as String,
      tenureId: json['tenure_id'] as String,
      category: json['category'] as String,
      categoryDisplayName: json['category_display_name'] as String,
      tenureMonths: json['tenure_months'] as int,
      versionNumber: json['version_number'] as int,
      oldRate: (json['old_rate'] as num).toDouble(),
      newRate: (json['new_rate'] as num).toDouble(),
      changeReason: json['change_reason'] as String?,
      changedBy: json['changed_by'] as String?,
      adminName: json['admin_name'] as String?,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      usersNotified: json['users_notified'] as int,
      activeInvestments: json['active_investments'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version_id': versionId,
      'tenure_id': tenureId,
      'category': category,
      'category_display_name': categoryDisplayName,
      'tenure_months': tenureMonths,
      'version_number': versionNumber,
      'old_rate': oldRate,
      'new_rate': newRate,
      if (changeReason != null) 'change_reason': changeReason,
      if (changedBy != null) 'changed_by': changedBy,
      if (adminName != null) 'admin_name': adminName,
      'effective_from': effectiveFrom.toIso8601String(),
      'users_notified': usersNotified,
      'active_investments': activeInvestments,
    };
  }

  /// Get rate change percentage
  double get rateChangePercentage {
    if (oldRate == 0) return 0;
    return ((newRate - oldRate) / oldRate) * 100;
  }

  /// Get rate change direction
  String get rateChangeDirection {
    if (newRate > oldRate) return 'increased';
    if (newRate < oldRate) return 'decreased';
    return 'unchanged';
  }

  /// Get rate change label
  String get rateChangeLabel {
    final change = rateChangePercentage.abs();
    final direction = rateChangeDirection;
    if (direction == 'unchanged') return 'No change';
    return '$direction by ${change.toStringAsFixed(2)}%';
  }

  /// Get formatted date
  String get formattedDate {
    return '${effectiveFrom.day}/${effectiveFrom.month}/${effectiveFrom.year}';
  }

  /// Get product display name
  String get productDisplayName =>
      '$categoryDisplayName - $tenureMonths months';
}

/// Rate Change Notification Model
class RateChangeNotificationModel {
  final String id;
  final String versionId;
  final String userId;
  final String? notificationId;
  final String category;
  final int tenureMonths;
  final double oldRate;
  final double newRate;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  RateChangeNotificationModel({
    required this.id,
    required this.versionId,
    required this.userId,
    this.notificationId,
    required this.category,
    required this.tenureMonths,
    required this.oldRate,
    required this.newRate,
    required this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory RateChangeNotificationModel.fromJson(Map<String, dynamic> json) {
    return RateChangeNotificationModel(
      id: json['id'] as String,
      versionId: json['version_id'] as String,
      userId: json['user_id'] as String,
      notificationId: json['notification_id'] as String?,
      category: json['category'] as String,
      tenureMonths: json['tenure_months'] as int,
      oldRate: (json['old_rate'] as num).toDouble(),
      newRate: (json['new_rate'] as num).toDouble(),
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version_id': versionId,
      'user_id': userId,
      if (notificationId != null) 'notification_id': notificationId,
      'category': category,
      'tenure_months': tenureMonths,
      'old_rate': oldRate,
      'new_rate': newRate,
      'sent_at': sentAt.toIso8601String(),
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if notification was read
  bool get isRead => readAt != null;

  /// Get status label
  String get statusLabel => isRead ? 'Read' : 'Unread';
}
