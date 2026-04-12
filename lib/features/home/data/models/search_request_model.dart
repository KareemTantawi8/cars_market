/// Search Request Model
class SearchRequestModel {
  final String? partName;
  final int? brandId;
  final int? modelId;
  final int? yearId;
  final int? governorateId;
  // Display names for UI
  final String? brandName;
  final String? modelName;
  final String? yearName;
  final String? governorateName;

  SearchRequestModel({
    this.partName,
    this.brandId,
    this.modelId,
    this.yearId,
    this.governorateId,
    this.brandName,
    this.modelName,
    this.yearName,
    this.governorateName,
  });

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    // API requires 'part_text' field (even if empty)
    // Always send part_text - use empty string if null
    json['part_text'] = partName?.trim() ?? '';
    
    if (brandId != null) {
      json['brand_id'] = brandId;
    }
    
    if (modelId != null) {
      json['model_id'] = modelId;
    }

    // Prefer catalog id: Laravel often authorizes/validates via year_id on the years table.
    // Sending only `year` (calendar number) led to 403 "This action is unauthorized" on some APIs.
    if (yearId != null) {
      json['year_id'] = yearId;
    } else if (yearName != null && yearName!.isNotEmpty) {
      final parsed = int.tryParse(yearName!.trim());
      if (parsed != null) {
        json['year'] = parsed;
      } else {
        json['year'] = yearName;
      }
    }
    
    if (governorateId != null) {
      json['governorate_id'] = governorateId;
    }

    return json;
  }

  /// Create from JSON
  factory SearchRequestModel.fromJson(Map<String, dynamic> json) {
    return SearchRequestModel(
      partName: json['part_name'] as String?,
      brandId: json['brand_id'] as int?,
      modelId: json['model_id'] as int?,
      yearId: json['year_id'] as int?,
      governorateId: json['governorate_id'] as int?,
      brandName: json['brand_name'] as String?,
      modelName: json['model_name'] as String?,
      yearName: json['year_name'] as String?,
      governorateName: json['governorate_name'] as String?,
    );
  }

  /// Copy with new values
  SearchRequestModel copyWith({
    String? partName,
    int? brandId,
    int? modelId,
    int? yearId,
    int? governorateId,
    String? brandName,
    String? modelName,
    String? yearName,
    String? governorateName,
  }) {
    return SearchRequestModel(
      partName: partName ?? this.partName,
      brandId: brandId ?? this.brandId,
      modelId: modelId ?? this.modelId,
      yearId: yearId ?? this.yearId,
      governorateId: governorateId ?? this.governorateId,
      brandName: brandName ?? this.brandName,
      modelName: modelName ?? this.modelName,
      yearName: yearName ?? this.yearName,
      governorateName: governorateName ?? this.governorateName,
    );
  }
}

