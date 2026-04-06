/// API response models for Ads endpoints

/// Parse int from JSON (API may return int or string)
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}

/// Parse optional int (null if missing)
int? _parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

/// Parse bool from JSON (API may return bool, int 0/1, or string)
bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

/// Builds a human-readable place line from JSON. Never uses the seller's personal name.
String? parseAdLocationLabel(Map<String, dynamic> json) {
  final parts = <String>[];
  void add(dynamic v) {
    if (v == null) return;
    final s = v.toString().trim();
    if (s.isEmpty) return;
    if (!parts.contains(s)) parts.add(s);
  }

  add(json['address']);
  add(json['full_address']);
  add(json['street_address']);
  add(json['city']);
  add(json['city_name']);

  final gov = json['governorate'];
  if (gov is String) add(gov);
  if (gov is Map) {
    final m = Map<String, dynamic>.from(gov);
    add(m['name_ar'] ?? m['name']);
  }

  final loc = json['location'];
  if (loc is String) add(loc);
  if (loc is Map) {
    final m = Map<String, dynamic>.from(loc);
    add(m['full_address'] ?? m['address']);
    add(m['city']);
    add(m['name_ar'] ?? m['governorate_name']);
    if (parts.isEmpty) add(m['name']);
  }

  if (parts.isEmpty) return null;
  return parts.join('، ');
}

class AdUserModel {
  final int id;
  final String? name;
  final String? phone;

  /// `vendors.id` when present — use for chat/profile APIs, distinct from [id] (user account id).
  final int? vendorRecordId;

  AdUserModel({
    required this.id,
    this.name,
    this.phone,
    this.vendorRecordId,
  });

  factory AdUserModel.fromJson(Map<String, dynamic> json) {
    int? vendorRecordId = _parseIntOrNull(json['vendor_id']);
    final nested = json['vendor'];
    if (nested is Map<String, dynamic>) {
      vendorRecordId ??= _parseIntOrNull(nested['id']);
    }
    return AdUserModel(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
      phone: json['phone']?.toString(),
      vendorRecordId: vendorRecordId,
    );
  }
}

class AdBrandModel {
  final int id;
  final String? name;

  AdBrandModel({required this.id, this.name});

  factory AdBrandModel.fromJson(Map<String, dynamic> json) {
    return AdBrandModel(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
    );
  }
}

class AdCarModelRef {
  final int id;
  final String? name;

  AdCarModelRef({required this.id, this.name});

  factory AdCarModelRef.fromJson(Map<String, dynamic> json) {
    return AdCarModelRef(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
    );
  }
}

class AdYearModel {
  final int id;
  final String? name;

  AdYearModel({required this.id, this.name});

  factory AdYearModel.fromJson(Map<String, dynamic> json) {
    return AdYearModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString(),
    );
  }
}

/// Single ad as returned by GET /ads, GET /ads/:id, POST /ads, GET /my-ads
class AdModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final int brandId;
  final int? modelId;
  final int? yearId;
  final String condition; // 'new' | 'used'
  final double? price;
  final bool isNegotiable;
  final bool isPhoneVisible;
  final List<String> images;
  final String status; // e.g. 'approved', 'pending', 'rejected'
  final String? rejectionReason;
  final bool isActive;
  final String? expiresAt;
  final String? createdAt;
  final String? updatedAt;
  final int? viewsCount;
  final AdUserModel? user;
  final AdBrandModel? brand;
  final AdCarModelRef? carModel;
  final AdYearModel? year;
  /// Address / city / governorate for display (not the seller's name).
  final String? locationLabel;

  AdModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.brandId,
    this.modelId,
    this.yearId,
    required this.condition,
    this.price,
    this.isNegotiable = false,
    this.isPhoneVisible = true,
    this.images = const [],
    this.status = 'pending',
    this.rejectionReason,
    this.isActive = true,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.viewsCount,
    this.user,
    this.brand,
    this.carModel,
    this.year,
    this.locationLabel,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    List<String> imagesList = [];
    if (imagesRaw is List) {
      for (final e in imagesRaw) {
        if (e == null) continue;
        if (e is String && e.isNotEmpty) {
          imagesList.add(e);
        } else if (e is Map<String, dynamic>) {
          final path = e['path'] as String? ?? e['url'] as String? ?? e['full_url'] as String? ?? e['image'] as String?;
          if (path != null && path.isNotEmpty) imagesList.add(path);
        }
      }
    }
    final priceRaw = json['price'];
    double? price;
    if (priceRaw != null) {
      if (priceRaw is num) price = priceRaw.toDouble();
      if (priceRaw is String) price = double.tryParse(priceRaw);
    }
    final carModelJson = json['carModel'] ?? json['car_model'];
    return AdModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      title: json['title']?.toString() ?? '',
      description: json['description'] as String?,
      brandId: _parseInt(json['brand_id']),
      modelId: json['model_id'] != null ? _parseInt(json['model_id']) : null,
      yearId: json['year_id'] != null ? _parseInt(json['year_id']) : null,
      condition: json['condition']?.toString() ?? 'used',
      price: price,
      isNegotiable: _parseBool(json['is_negotiable']),
      isPhoneVisible: _parseBool(json['is_phone_visible']),
      images: imagesList,
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      isActive: _parseBool(json['is_active']),
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      viewsCount: _parseIntOrNull(json['views_count'] ?? json['views']),
      user: json['user'] is Map<String, dynamic>
          ? AdUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      brand: json['brand'] is Map<String, dynamic>
          ? AdBrandModel.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      carModel: carModelJson is Map<String, dynamic>
          ? AdCarModelRef.fromJson(carModelJson)
          : null,
      year: json['year'] is Map<String, dynamic>
          ? AdYearModel.fromJson(json['year'] as Map<String, dynamic>)
          : null,
      locationLabel: parseAdLocationLabel(json),
    );
  }

  /// Price formatted for display (e.g. "4,500 ج.م")
  String get priceFormatted {
    if (price == null) return '0 ج.م';
    final p = price!.round();
    if (p >= 1000) {
      return '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}${p % 1000 == 0 ? ',000' : ''} ج.م';
    }
    return '$p ج.م';
  }

  /// Condition label in Arabic
  String get conditionLabel => condition == 'new' ? 'جديد' : 'مستعمل';

  /// Normalized status for filtering (backend may send approved/active/published or pending/under_review)
  String get statusNormalized {
    final s = status.toLowerCase();
    if (s == 'approved' || s == 'active' || s == 'published') return 'approved';
    if (s == 'pending' || s == 'under_review' || s == 'in_review' || s == 'under review') return 'pending';
    if (s == 'rejected') return 'rejected';
    return s;
  }

  /// Status label in Arabic
  String get statusLabel {
    switch (statusNormalized) {
      case 'approved':
        return 'نشط';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  /// First image URL (full URL if relative)
  String? get firstImageUrl =>
      images.isNotEmpty ? images.first : null;

  /// Views text for display: "120 مشاهدة" or "-- مشاهدة"
  String get viewsFormatted =>
      viewsCount != null && viewsCount! >= 0
          ? '$viewsCount مشاهدة'
          : '-- مشاهدة';
}

/// Paginated response for GET /ads and GET /my-ads
class PaginatedAdsResponse {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int from;
  final int to;
  final List<AdModel> data;

  PaginatedAdsResponse({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.from,
    required this.to,
    required this.data,
  });

  factory PaginatedAdsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final dataList = raw is List ? raw : <dynamic>[];
    return PaginatedAdsResponse(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      from: (json['from'] as num?)?.toInt() ?? 0,
      to: (json['to'] as num?)?.toInt() ?? 0,
      data: dataList
          .whereType<Map<String, dynamic>>()
          .map((e) => AdModel.fromJson(e))
          .toList(),
    );
  }

  bool get hasMore => currentPage < lastPage;
}
