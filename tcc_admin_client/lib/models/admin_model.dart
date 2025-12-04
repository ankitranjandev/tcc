/// Admin User Model
class AdminModel {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? createdBy;

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
    this.createdBy,
  });

  /// Create AdminModel from JSON
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    // Handle name field - backend may return first_name/last_name or name
    String name;
    if (json['name'] != null) {
      name = json['name'] as String;
    } else if (json['first_name'] != null || json['last_name'] != null) {
      final firstName = json['first_name'] as String? ?? '';
      final lastName = json['last_name'] as String? ?? '';
      name = '$firstName $lastName'.trim();
      if (name.isEmpty) name = 'Unknown';
    } else {
      name = 'Unknown';
    }

    // Parse role - handle both string and enum formats
    AdminRole role;
    final roleValue = json['role'];
    if (roleValue == 'super_admin' || roleValue == 'SUPER_ADMIN') {
      role = AdminRole.superAdmin;
    } else if (roleValue == 'admin' || roleValue == 'ADMIN') {
      role = AdminRole.admin;
    } else {
      role = AdminRole.admin; // default
    }

    return AdminModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: name,
      role: role,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
    );
  }

  /// Convert AdminModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  /// Check if admin has specific permission
  bool hasPermission(String permission) {
    if (role == AdminRole.superAdmin) return true;
    return permissions.contains(permission);
  }

  /// Check if admin can manage users
  bool get canManageUsers => hasPermission('users.manage');

  /// Check if admin can manage agents
  bool get canManageAgents => hasPermission('agents.manage');

  /// Check if admin can manage transactions
  bool get canManageTransactions => hasPermission('transactions.manage');

  /// Check if admin can manage investments
  bool get canManageInvestments => hasPermission('investments.manage');

  /// Check if admin can manage system settings
  bool get canManageSettings => hasPermission('settings.manage');

  /// Check if admin can view reports
  bool get canViewReports => hasPermission('reports.view');

  /// Copy with method
  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? createdBy,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Admin Role Enum
enum AdminRole {
  admin,
  superAdmin;

  String get displayName {
    switch (this) {
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.superAdmin:
        return 'Super Admin';
    }
  }
}
