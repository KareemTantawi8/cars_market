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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.categories = const [],
  });

  /// Create from JSON
  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      companyName: json['company_name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      website: json['website'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      responseTimeHours: json['response_time_hours'] as int?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      categories: json['categories'] as List<dynamic>? ?? [],
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'categories': categories,
    };
  }
}

