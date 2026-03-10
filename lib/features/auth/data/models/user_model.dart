import 'vendor_model.dart';

/// User Model
class UserModel {
  final int id;
  final String name;
  final String phone;
  final String type;
  final String? status;
  final bool isProtected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<dynamic> roles;
  final VendorModel? vendor;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.status,
    required this.isProtected,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.roles,
    this.vendor,
  });

  /// Create from JSON
  /// Register/auth responses may omit created_at, updated_at, roles
  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }
    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } catch (_) {}
    }
    final now = DateTime.now();
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone']?.toString() ?? '',
      type: json['type'] as String? ?? 'customer',
      status: json['status'] as String?,
      isProtected: json['is_protected'] as bool? ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
      roles: json['roles'] as List<dynamic>? ?? [],
      vendor: json['vendor'] != null && json['vendor'] is Map<String, dynamic>
          ? VendorModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'status': status,
      'is_protected': isProtected,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'roles': roles,
      if (vendor != null) 'vendor': vendor!.toJson(),
    };
  }
}

