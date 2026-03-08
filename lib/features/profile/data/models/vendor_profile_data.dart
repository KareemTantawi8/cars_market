/// Vendor Profile Data - Parsed from auth/me vendor object
/// API may omit user_id, created_at, updated_at in auth/me response
class VendorProfileData {
  final int id;
  final String companyName;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? website;
  final String? phone;
  final GovernorateInfo? governorate;
  final String? googleMapsUrl;
  final List<BrandInfo> brands;
  final double averageRating;
  final int ratingsCount;
  final int? responseTimeHours;
  final String? responseTimeHuman;
  final bool isVerified;
  final bool isOnline;

  VendorProfileData({
    required this.id,
    required this.companyName,
    this.description,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.website,
    this.phone,
    this.governorate,
    this.googleMapsUrl,
    this.brands = const [],
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.responseTimeHours,
    this.responseTimeHuman,
    this.isVerified = false,
    this.isOnline = false,
  });

  factory VendorProfileData.fromJson(Map<String, dynamic> json) {
    List<BrandInfo> brandsList = [];
    final rawBrands = json['brands'];
    if (rawBrands is List) {
      for (final b in rawBrands) {
        try {
          if (b is Map<String, dynamic>) {
            brandsList.add(BrandInfo.fromJson(b));
          }
        } catch (_) {}
      }
    }

    GovernorateInfo? gov;
    final rawGov = json['governorate'];
    if (rawGov is Map<String, dynamic>) {
      try {
        gov = GovernorateInfo.fromJson(rawGov);
      } catch (_) {
        gov = null;
      }
    }

    return VendorProfileData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyName: json['company_name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      governorate: gov,
      googleMapsUrl: json['google_maps_url'] as String?,
      brands: brandsList,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (json['ratings_count'] as num?)?.toInt() ?? 0,
      responseTimeHours: json['response_time_hours'] as int?,
      responseTimeHuman: json['response_time_human'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

class GovernorateInfo {
  final int id;
  final String name;
  final String? slug;

  GovernorateInfo({required this.id, required this.name, this.slug});

  factory GovernorateInfo.fromJson(Map<String, dynamic> json) {
    return GovernorateInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
    );
  }
}

class BrandInfo {
  final int id;
  final String name;
  final String? slug;

  BrandInfo({required this.id, required this.name, this.slug});

  factory BrandInfo.fromJson(Map<String, dynamic> json) {
    return BrandInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
    );
  }
}
