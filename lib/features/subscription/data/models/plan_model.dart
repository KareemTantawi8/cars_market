/// Subscription Plan Model
class PlanModel {
  final int id;
  final String name;
  final String nameEn;
  final String? description;
  final double monthlyPrice;
  final double? annualPrice;
  final List<String> features;
  final bool isPopular;
  final String? badge;
  final int? maxParts;
  final bool unlimitedParts;
  final bool priorityInSearch;
  final String? supportType;
  final bool hasAnalytics;

  PlanModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.description,
    required this.monthlyPrice,
    this.annualPrice,
    required this.features,
    this.isPopular = false,
    this.badge,
    this.maxParts,
    this.unlimitedParts = false,
    this.priorityInSearch = false,
    this.supportType,
    this.hasAnalytics = false,
  });

  /// Create from JSON
  factory PlanModel.fromJson(Map<String, dynamic> json) {
    // Handle features - can be List<String> or List<Map>
    List<String> featuresList = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        final featuresData = json['features'] as List;
        featuresList = featuresData.map((feature) {
          if (feature is String) {
            return feature;
          } else if (feature is Map && feature['name'] != null) {
            return feature['name'] as String;
          } else if (feature is Map && feature['description'] != null) {
            return feature['description'] as String;
          }
          return feature.toString();
        }).toList();
      }
    }

    return PlanModel(
      id: json['id'] as int? ?? json['plan_id'] as int? ?? 0,
      name: json['name'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String? ?? '',
      description: json['description'] as String? ?? json['description_ar'] as String?,
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 
                    (json['monthlyPrice'] as num?)?.toDouble() ?? 
                    (json['price'] as num?)?.toDouble() ?? 0.0,
      annualPrice: (json['annual_price'] as num?)?.toDouble() ?? 
                   (json['annualPrice'] as num?)?.toDouble(),
      features: featuresList,
      isPopular: json['is_popular'] as bool? ?? 
                 json['isPopular'] as bool? ?? 
                 json['popular'] as bool? ?? false,
      badge: json['badge'] as String?,
      maxParts: json['max_parts'] as int? ?? json['maxParts'] as int?,
      unlimitedParts: json['unlimited_parts'] as bool? ?? 
                      json['unlimitedParts'] as bool? ?? false,
      priorityInSearch: json['priority_in_search'] as bool? ?? 
                        json['priorityInSearch'] as bool? ?? false,
      supportType: json['support_type'] as String? ?? json['supportType'] as String?,
      hasAnalytics: json['has_analytics'] as bool? ?? 
                    json['hasAnalytics'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      if (description != null) 'description': description,
      'monthly_price': monthlyPrice,
      if (annualPrice != null) 'annual_price': annualPrice,
      'features': features,
      'is_popular': isPopular,
      if (badge != null) 'badge': badge,
      if (maxParts != null) 'max_parts': maxParts,
      'unlimited_parts': unlimitedParts,
      'priority_in_search': priorityInSearch,
      if (supportType != null) 'support_type': supportType,
      'has_analytics': hasAnalytics,
    };
  }
}

/// Plans Response Model
class PlansResponseModel {
  final List<PlanModel> plans;
  final String? message;

  PlansResponseModel({
    required this.plans,
    this.message,
  });

  /// Create from JSON
  factory PlansResponseModel.fromJson(Map<String, dynamic> json) {
    List<dynamic>? plansData;
    
    // Handle different API response formats
    if (json['data'] != null) {
      if (json['data'] is List) {
        plansData = json['data'] as List<dynamic>;
      } else if (json['data'] is Map && json['data']['plans'] != null) {
        plansData = json['data']['plans'] as List<dynamic>;
      }
    } else if (json['plans'] != null) {
      plansData = json['plans'] as List<dynamic>;
    }
    
    return PlansResponseModel(
      plans: plansData
              ?.map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'plans': plans.map((e) => e.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

/// Plan Details Response Model
class PlanDetailsResponseModel {
  final PlanModel plan;
  final String? message;

  PlanDetailsResponseModel({
    required this.plan,
    this.message,
  });

  /// Create from JSON
  factory PlanDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? planData;
    
    if (json['data'] != null) {
      planData = json['data'] is Map 
          ? json['data'] as Map<String, dynamic>
          : null;
    } else if (json['plan'] != null) {
      planData = json['plan'] as Map<String, dynamic>;
    } else {
      // Assume the whole JSON is the plan
      planData = json;
    }
    
    return PlanDetailsResponseModel(
      plan: PlanModel.fromJson(planData ?? {}),
      message: json['message'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'plan': plan.toJson(),
      if (message != null) 'message': message,
    };
  }
}

