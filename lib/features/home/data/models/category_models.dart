/// Brand Model
class BrandModel {
  final int id;
  final String name;
  final String? nameAr;
  final String? logo;

  BrandModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.logo,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['brand_name'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? json['brand_name_ar'] as String?,
      logo: json['logo'] as String? ?? json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'logo': logo,
    };
  }

  /// Get display name (Arabic if available, otherwise English)
  String get displayName => nameAr ?? name;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Car Model (not to confuse with data model)
class CarModelModel {
  final int id;
  final int brandId;
  final String name;
  final String? nameAr;

  CarModelModel({
    required this.id,
    required this.brandId,
    required this.name,
    this.nameAr,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'] as int? ?? 0,
      brandId: json['brand_id'] as int? ?? json['brandId'] as int? ?? 0,
      name: json['name'] as String? ?? json['model_name'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? json['model_name_ar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'name': name,
      'name_ar': nameAr,
    };
  }

  /// Get display name (Arabic if available, otherwise English)
  String get displayName => nameAr ?? name;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarModelModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Year Model
class YearModel {
  final int id;
  final int modelId;
  final String name; // Year as string (e.g., "2023", "2022")
  final String? slug;
  final int? parentId;

  YearModel({
    required this.id,
    required this.modelId,
    required this.name,
    this.slug,
    this.parentId,
  });

  factory YearModel.fromJson(Map<String, dynamic> json) {
    // API returns: {id, name, slug, meta, parent_id}
    // name contains the year as string (e.g., "2023")
    // parent_id is the modelId
    final parentId = json['parent_id'] as int?;
    final modelId = json['model_id'] as int? ?? 
                    json['modelId'] as int? ?? 
                    parentId ?? 0;
    
    return YearModel(
      id: json['id'] as int? ?? 0,
      modelId: modelId,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      parentId: parentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model_id': modelId,
      'name': name,
      if (slug != null) 'slug': slug,
      if (parentId != null) 'parent_id': parentId,
    };
  }

  /// Get display name (the year as string, e.g., "2023")
  String get displayName => name;
  
  /// Get year as integer (parse from name)
  int? get yearInt {
    try {
      return int.parse(name);
    } catch (e) {
      return null;
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Governorate Model
class GovernorateModel {
  final int id;
  final String name;
  final String? nameAr;

  GovernorateModel({
    required this.id,
    required this.name,
    this.nameAr,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    return GovernorateModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['governorate_name'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? json['governorate_name_ar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
    };
  }

  /// Get display name (Arabic if available, otherwise English)
  String get displayName => nameAr ?? name;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GovernorateModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Brands Response
class BrandsResponse {
  final List<BrandModel> brands;

  BrandsResponse({required this.brands});

  factory BrandsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['brands'] ?? json;
    if (data is List) {
      return BrandsResponse(
        brands: data.whereType<Map<String, dynamic>>().map((e) => BrandModel.fromJson(e)).toList(),
      );
    }
    return BrandsResponse(brands: []);
  }
}

/// Models Response
class ModelsResponse {
  final List<CarModelModel> models;

  ModelsResponse({required this.models});

  factory ModelsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['models'] ?? json;
    if (data is List) {
      return ModelsResponse(
        models: data.whereType<Map<String, dynamic>>().map((e) => CarModelModel.fromJson(e)).toList(),
      );
    }
    return ModelsResponse(models: []);
  }
}

/// Years Response
class YearsResponse {
  final List<YearModel> years;
  final Map<String, dynamic>? model;
  final Map<String, dynamic>? brand;

  YearsResponse({
    required this.years,
    this.model,
    this.brand,
  });

  factory YearsResponse.fromJson(Map<String, dynamic> json) {
    // API response structure:
    // {
    //   "data": [{id, name, slug, meta, parent_id}, ...],
    //   "model": {id, name},
    //   "brand": {id, name}
    // }
    final data = json['data'];
    if (data is List) {
      return YearsResponse(
        years: data.whereType<Map<String, dynamic>>().map((e) => YearModel.fromJson(e)).toList(),
        model: json['model'] is Map<String, dynamic> ? json['model'] as Map<String, dynamic> : null,
        brand: json['brand'] is Map<String, dynamic> ? json['brand'] as Map<String, dynamic> : null,
      );
    }
    return YearsResponse(
      years: [],
      model: json['model'] is Map<String, dynamic> ? json['model'] as Map<String, dynamic> : null,
      brand: json['brand'] is Map<String, dynamic> ? json['brand'] as Map<String, dynamic> : null,
    );
  }
}

/// Governorates Response
class GovernoratesResponse {
  final List<GovernorateModel> governorates;

  GovernoratesResponse({required this.governorates});

  factory GovernoratesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['governorates'] ?? json;
    if (data is List) {
      return GovernoratesResponse(
        governorates: data.whereType<Map<String, dynamic>>().map((e) => GovernorateModel.fromJson(e)).toList(),
      );
    }
    return GovernoratesResponse(governorates: []);
  }
}

