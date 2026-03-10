import 'supplier_model.dart';

/// Search Response Model
class SearchResponseModel {
  final List<SupplierModel> suppliers;
  final int totalCount;
  final String? message;

  SearchResponseModel({
    required this.suppliers,
    required this.totalCount,
    this.message,
  });

  /// Create from JSON
  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    List<dynamic>? suppliersData;
    
    // Try different possible keys for suppliers data
    if (json['data'] != null) {
      if (json['data'] is List) {
        suppliersData = json['data'] as List<dynamic>;
      } else if (json['data'] is Map && json['data']['suppliers'] != null) {
        suppliersData = json['data']['suppliers'] as List<dynamic>;
      }
    } else if (json['suppliers'] != null) {
      suppliersData = json['suppliers'] as List<dynamic>;
    } else if (json['vendors'] != null) {
      suppliersData = json['vendors'] as List<dynamic>;
    }
    
    return SearchResponseModel(
      suppliers: suppliersData
              ?.whereType<Map<String, dynamic>>()
              .map((e) => SupplierModel.fromJson(e))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 
                  json['total'] as int? ?? 
                  json['count'] as int? ?? 
                  (suppliersData?.length ?? 0),
      message: json['message'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'suppliers': suppliers.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      if (message != null) 'message': message,
    };
  }
}

