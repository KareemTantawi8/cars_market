/// Vendor Profile Model
class VendorProfileModel {
  final int id;
  final String name;
  final String? description;
  final bool isVerified;
  final bool isOpen;
  final String? openUntil;
  final int? responseTimeMinutes;
  final String? responseTimeHuman;
  final double rating;
  final int ratingCount;
  final List<String> supportedBrands;
  final List<String> availableServices;
  final String? phone;
  /// رقم المحل / التواصل (قد يختلف عن رقم الحساب)
  final String? shopPhone;
  final String? whatsapp;
  final String? address;
  final String? governorate;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String? imageUrl;
  final String? backgroundImageUrl;

  VendorProfileModel copyWith({
    bool? isOpen,
    String? openUntil,
  }) {
    return VendorProfileModel(
      id: id,
      name: name,
      description: description,
      isVerified: isVerified,
      isOpen: isOpen ?? this.isOpen,
      openUntil: openUntil ?? this.openUntil,
      responseTimeMinutes: responseTimeMinutes,
      responseTimeHuman: responseTimeHuman,
      rating: rating,
      ratingCount: ratingCount,
      supportedBrands: supportedBrands,
      availableServices: availableServices,
      phone: phone,
      shopPhone: shopPhone,
      whatsapp: whatsapp,
      address: address,
      governorate: governorate,
      latitude: latitude,
      longitude: longitude,
      googleMapsUrl: googleMapsUrl,
      imageUrl: imageUrl,
      backgroundImageUrl: backgroundImageUrl,
    );
  }

  VendorProfileModel({
    required this.id,
    required this.name,
    this.description,
    this.isVerified = false,
    this.isOpen = false,
    this.openUntil,
    this.responseTimeMinutes,
    this.responseTimeHuman,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.supportedBrands,
    required this.availableServices,
    this.phone,
    this.shopPhone,
    this.whatsapp,
    this.address,
    this.governorate,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.imageUrl,
    this.backgroundImageUrl,
  });

  /// Parse governorate - can be String or object {id, name, slug}
  static String? _parseGovernorate(dynamic gov) {
    if (gov is String) return gov;
    if (gov is Map && gov['name'] != null) return gov['name'].toString();
    return null;
  }

  /// Create from JSON
  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    // Handle supported brands
    List<String> brands = [];
    final brandsData = json['supported_brands'] ?? 
                       json['brands'] ?? 
                       json['brand_names'] ?? 
                       json['car_brands'];
    if (brandsData is List) {
      brands = brandsData.map((e) {
        if (e is String) return e;
        if (e is Map) return e['name']?.toString() ?? 
                         e['name_ar']?.toString() ?? 
                         e['brand_name']?.toString() ?? '';
        return e.toString();
      }).toList();
    }

    // Handle available services
    List<String> services = [];
    final servicesData = json['available_services'] ?? 
                         json['services'] ?? 
                         json['service_names'];
    if (servicesData is List) {
      services = servicesData.map((e) {
        if (e is String) return e;
        if (e is Map) return e['name']?.toString() ?? 
                         e['name_ar']?.toString() ?? 
                         e['service_name']?.toString() ?? '';
        return e.toString();
      }).toList();
    }

    // Handle location coordinates
    double? lat, lng;
    final locationData = json['location'] ?? json['coordinates'];
    if (locationData is Map) {
      lat = (locationData['latitude'] as num?)?.toDouble() ?? 
            (locationData['lat'] as num?)?.toDouble();
      lng = (locationData['longitude'] as num?)?.toDouble() ?? 
            (locationData['lng'] as num?)?.toDouble() ?? 
            (locationData['lon'] as num?)?.toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? 
            (json['lat'] as num?)?.toDouble();
      lng = (json['longitude'] as num?)?.toDouble() ?? 
            (json['lng'] as num?)?.toDouble() ?? 
            (json['lon'] as num?)?.toDouble();
    }

    // Handle address
    String? addressStr;
    final addressData = json['address'] ?? json['full_address'];
    if (addressData is String) {
      addressStr = addressData;
    } else if (addressData is Map) {
      addressStr = addressData['full_address']?.toString() ?? 
                   addressData['address']?.toString();
    }

    // Handle response time
    int? responseTime;
    final responseTimeData = json['response_time'] ?? 
                             json['response_time_minutes'] ?? 
                             json['avg_response_time'];
    if (responseTimeData is int) {
      responseTime = responseTimeData;
    } else if (responseTimeData is String) {
      responseTime = int.tryParse(responseTimeData);
    }

    return VendorProfileModel(
      id: json['id'] as int? ?? 
          json['user_id'] as int? ?? 
          json['vendor_id'] as int? ?? 0,
      name: json['name'] as String? ?? 
            json['vendor_name'] as String? ?? 
            json['company_name'] as String? ?? '',
      description: json['description'] as String? ?? 
                   json['bio'] as String? ?? 
                   json['about'] as String?,
      isVerified: json['is_verified'] as bool? ?? 
                  json['verified'] as bool? ?? 
                  json['is_certified'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? 
              json['open'] as bool? ?? 
              json['is_online'] as bool? ??
              (json['status']?.toString() == 'open'),
      openUntil: json['open_until'] as String? ?? 
                 json['closing_time'] as String?,
      responseTimeMinutes: responseTime,
      responseTimeHuman: json['response_time_human'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 
             (json['average_rating'] as num?)?.toDouble() ?? 
             (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 
                   (json['ratings_count'] as num?)?.toInt() ??
                   (json['reviews_count'] as num?)?.toInt() ?? 
                   (json['total_reviews'] as num?)?.toInt() ?? 
                   (json['review_count'] as num?)?.toInt() ?? 0,
      supportedBrands: brands,
      availableServices: services,
      phone: json['phone'] as String? ??
             json['mobile'] as String? ??
             json['phone_number'] as String?,
      shopPhone: json['shop_phone'] as String? ??
                 json['shop_mobile'] as String?,
      whatsapp: json['whatsapp'] as String? ??
                json['whatsapp_number'] as String? ?? 
                json['phone'], // Fallback to phone if whatsapp not available
      address: addressStr,
      governorate: _parseGovernorate(json['governorate']) ?? 
                   json['governorate_name'] as String?,
      latitude: lat,
      longitude: lng,
      googleMapsUrl: json['google_maps_url'] as String? ??
          json['google_maps_link'] as String?,
      imageUrl: json['image_url'] as String? ?? 
                json['image'] as String? ?? 
                json['logo'] as String? ?? 
                json['avatar'] as String?,
      backgroundImageUrl: json['background_image_url'] as String? ?? 
                          json['background_image'] as String? ?? 
                          json['cover_image'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'is_verified': isVerified,
      'is_open': isOpen,
      if (openUntil != null) 'open_until': openUntil,
      if (responseTimeMinutes != null) 'response_time_minutes': responseTimeMinutes,
      'rating': rating,
      'rating_count': ratingCount,
      'supported_brands': supportedBrands,
      'available_services': availableServices,
      if (phone != null) 'phone': phone,
      if (shopPhone != null) 'shop_phone': shopPhone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (address != null) 'address': address,
      if (governorate != null) 'governorate': governorate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (googleMapsUrl != null) 'google_maps_url': googleMapsUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (backgroundImageUrl != null) 'background_image_url': backgroundImageUrl,
    };
  }
}

