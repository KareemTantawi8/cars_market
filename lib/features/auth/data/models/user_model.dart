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
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      type: json['type'] as String,
      status: json['status'] as String?,
      isProtected: json['is_protected'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      roles: json['roles'] as List<dynamic>? ?? [],
      vendor: json['vendor'] != null
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

