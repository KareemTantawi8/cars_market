/// Vendor Model
class VendorModel {
  final int id;
  final int userId;
  final String companyName;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? website;
  final double averageRating;
  final int? responseTimeHours;
  final bool isVerified;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<dynamic> categories;

  VendorModel({
    required this.id,
    required this.userId,
    required this.companyName,
    this.description,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.website,
    this.averageRating = 0.0,
    this.responseTimeHours,
    this.isVerified = false,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.categories = const [],
  });

  /// Create from JSON (API may omit or return null for id, user_id, dates)
  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] != null ? (json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id'].toString()) ?? 0) : 0;
    final userId = json['user_id'] != null ? (json['user_id'] is num ? (json['user_id'] as num).toInt() : int.tryParse(json['user_id'].toString()) ?? 0) : 0;
    final companyName = json['company_name']?.toString() ?? json['company_name_ar']?.toString() ?? '';
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.tryParse(json['created_at'].toString());
      } catch (_) {}
    }
    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.tryParse(json['updated_at'].toString());
      } catch (_) {}
    }
    final now = DateTime.now();
    return VendorModel(
      id: id,
      userId: userId,
      companyName: companyName,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      website: json['website'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      responseTimeHours: json['response_time_hours'] != null ? (json['response_time_hours'] is num ? (json['response_time_hours'] as num).toInt() : int.tryParse(json['response_time_hours'].toString())) : null,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      categories: json['categories'] is List ? json['categories'] as List<dynamic> : [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'website': website,
      'average_rating': averageRating,
      'response_time_hours': responseTimeHours,
      'is_verified': isVerified,
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'categories': categories,
    };
  }
}

