/// User Profile Model - Response from /api/v1/auth/me
class UserProfileModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? imageUrl;
  final bool isVerified;
  final String userType; // 'customer' or 'vendor'
  final int loyaltyPoints;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.imageUrl,
    this.isVerified = false,
    required this.userType,
    this.loyaltyPoints = 0,
    this.status,
    this.createdAt,
    this.updatedAt,
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

    // Handle is_protected - from API
    bool isProtected = json['is_protected'] as bool? ?? false;

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

    // Check if user has vendor data
    final vendor = json['vendor'] as Map<String, dynamic>?;
    final isVerified = vendor != null || 
                      (json['is_verified'] as bool? ?? false) ||
                      (json['verified'] as bool? ?? false);

    return UserProfileModel(
      id: id,
      name: name,
      phone: phone,
      email: json['email'] as String?,
      address: json['address'] as String? ?? 
               json['full_address'] as String?,
      imageUrl: json['image_url'] as String? ?? 
                json['image'] as String? ?? 
                json['avatar'] as String? ?? 
                json['profile_picture'] as String?,
      isVerified: isVerified,
      userType: type,
      loyaltyPoints: points,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
      if (imageUrl != null) 'image_url': imageUrl,
      'is_verified': isVerified,
      'type': userType,
      'loyalty_points': loyaltyPoints,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Format phone number for display
  String get formattedPhone {
    // Format: 5678 234 101 20+
    if (phone.length >= 10) {
      final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length >= 10) {
        // Format as: XXXX XXX XXX XX+
        final parts = [
          cleaned.substring(0, 4),
          cleaned.substring(4, 7),
          cleaned.substring(7, 10),
          cleaned.length > 10 ? cleaned.substring(10) : '',
        ];
        return parts.where((p) => p.isNotEmpty).join(' ') + 
               (cleaned.length > 10 ? '+' : '');
      }
    }
    return phone;
  }
}

