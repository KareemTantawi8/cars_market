/// Supplier Model
class SupplierModel {
  final int id;
  final String name;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final String location;
  final String? distance;
  final List<String> supportedBrands;
  final String? imageUrl;
  final String? phone;
  final String? companyName;
  final String? governorate;

  SupplierModel({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.rating,
    required this.reviewCount,
    required this.location,
    this.distance,
    required this.supportedBrands,
    this.imageUrl,
    this.phone,
    this.companyName,
    this.governorate,
  });

  /// Create from JSON
  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    // Handle different field names from API
    final id = json['id'] as int? ?? json['vendor_id'] as int? ?? 0;
    final name = json['name'] as String? ?? 
                 json['vendor_name'] as String? ?? 
                 json['company_name'] as String? ?? 
                 '';
    
    // Handle brands - could be list of strings or list of objects
    List<String> brands = [];
    final brandsData = json['supported_brands'] ?? json['brands'] ?? json['brand_names'];
    if (brandsData is List) {
      brands = brandsData.map((e) {
        if (e is String) return e;
        if (e is Map) return e['name']?.toString() ?? e['name_ar']?.toString() ?? '';
        return e.toString();
      }).toList();
    }
    
    // Handle location - could be string or object
    String locationStr = '';
    final locationData = json['location'] ?? json['address'] ?? json['governorate'];
    if (locationData is String) {
      locationStr = locationData;
    } else if (locationData is Map) {
      locationStr = locationData['full_address']?.toString() ??
          locationData['address']?.toString() ??
          locationData['city']?.toString() ??
          locationData['name_ar']?.toString() ??
          locationData['governorate_name']?.toString() ??
          locationData['name']?.toString() ??
          '';
    }
    
    return SupplierModel(
      id: id,
      name: name,
      isOnline: json['is_online'] as bool? ?? json['online'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 
              (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 
                   json['reviews_count'] as int? ?? 
                   json['total_reviews'] as int? ?? 0,
      location: locationStr,
      distance: json['distance']?.toString(),
      supportedBrands: brands,
      imageUrl: json['image_url'] as String? ?? 
                json['image'] as String? ?? 
                json['logo'] as String? ?? 
                json['avatar'] as String?,
      phone: json['phone'] as String? ?? json['mobile'] as String?,
      companyName: json['company_name'] as String?,
      governorate: json['governorate'] as String? ?? json['governorate_name'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_online': isOnline,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      if (distance != null) 'distance': distance,
      'supported_brands': supportedBrands,
      if (imageUrl != null) 'image_url': imageUrl,
      if (phone != null) 'phone': phone,
      if (companyName != null) 'company_name': companyName,
      if (governorate != null) 'governorate': governorate,
    };
  }
}

