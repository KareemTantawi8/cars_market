import 'vendor_profile_data.dart';

/// User Profile Model - Response from /api/v1/auth/me
class UserProfileModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  /// User governorate (from `governorate` on auth/me or PUT /profile/address response).
  final int? governorateId;
  final String? governorateName;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final bool isVerified;
  final String userType; // 'customer' or 'vendor'
  final int loyaltyPoints;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VendorProfileData? vendor;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.governorateId,
    this.governorateName,
    this.imageUrl,
    this.backgroundImageUrl,
    this.isVerified = false,
    required this.userType,
    this.loyaltyPoints = 0,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.vendor,
  });

  /// Create from JSON
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names
    final id = json['id'] as int? ?? json['user_id'] as int? ?? 0;
    final name = json['name'] as String? ?? 
                 json['user_name'] as String? ?? 
                 json['full_name'] as String? ?? '';
    final phone = json['phone'] as String? ?? 
                  json['phone_number'] as String? ?? 
                  json['mobile'] as String? ?? '';
    
    // Handle loyalty points - could be in different locations
    int points = 0;
    if (json['loyalty_points'] != null) {
      points = (json['loyalty_points'] as num?)?.toInt() ?? 0;
    } else if (json['points'] != null) {
      points = (json['points'] as num?)?.toInt() ?? 0;
    } else if (json['loyalty'] != null && json['loyalty'] is Map) {
      points = (json['loyalty']['points'] as num?)?.toInt() ?? 
               (json['loyalty']['balance'] as num?)?.toInt() ?? 0;
    }

    // Handle user type - from API: "type": "customer" or "vendor"
    String type = json['type'] as String? ?? 
                  json['user_type'] as String? ?? 
                  json['role'] as String? ?? 'customer';

    // Handle status - from API: "status": "active"
    String? status = json['status'] as String?;

    // Handle dates
    DateTime? createdAt, updatedAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (e) {
        createdAt = null;
      }
    }
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } catch (e) {
        updatedAt = null;
      }
    }

    // Parse vendor data (auth/me response structure)
    VendorProfileData? vendorData;
    final vendorJson = json['vendor'];
    if (vendorJson is Map<String, dynamic>) {
      try {
        vendorData = VendorProfileData.fromJson(vendorJson);
      } catch (_) {
        vendorData = null;
      }
    }

    int? governorateId;
    String? governorateName;
    final govTop = json['governorate'];
    if (govTop is Map) {
      final gm = Map<String, dynamic>.from(govTop);
      governorateId = (gm['id'] as num?)?.toInt();
      governorateName =
          gm['name']?.toString() ?? gm['name_ar']?.toString();
    } else if (vendorData?.governorate != null) {
      governorateId = vendorData!.governorate!.id;
      governorateName = vendorData.governorate!.name;
    }

    // isVerified from vendor.is_verified or user-level fields
    final isVerified = vendorData?.isVerified ?? 
                      (json['is_verified'] as bool? ?? false) ||
                      (json['verified'] as bool? ?? false);

    // Address: user address, or vendor address + city
    String? addressValue = json['address'] as String? ?? 
                           json['full_address'] as String?;
    if (addressValue == null && vendorData != null) {
      final parts = [
        vendorData.address,
        vendorData.city,
        vendorData.governorate?.name,
      ].whereType<String>().where((s) => s.isNotEmpty);
      addressValue = parts.isNotEmpty ? parts.join('، ') : null;
    }

    // imageUrl: auth/me uses profile_image_url
    final imageUrlValue = json['profile_image_url'] as String? ??
        json['image_url'] as String? ??
        json['image'] as String? ??
        json['avatar'] as String? ??
        json['profile_picture'] as String?;

    return UserProfileModel(
      id: id,
      name: name,
      phone: phone,
      email: json['email'] as String?,
      address: addressValue,
      governorateId: governorateId,
      governorateName: governorateName,
      imageUrl: imageUrlValue,
      backgroundImageUrl: json['background_image_url'] as String?,
      isVerified: isVerified,
      userType: type,
      loyaltyPoints: points,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      vendor: vendorData,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (governorateId != null) 'governorate_id': governorateId,
      if (governorateName != null) 'governorate_name': governorateName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (backgroundImageUrl != null) 'background_image_url': backgroundImageUrl,
      'is_verified': isVerified,
      'type': userType,
      'loyalty_points': loyaltyPoints,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Format phone number for display (LTR, international format)
  String get formattedPhone {
    if (phone.isEmpty) return phone;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Already has + prefix — return as-is
    if (cleaned.startsWith('+')) return cleaned;
    // Treat as Egyptian number: prepend +
    return '+$cleaned';
  }
}

