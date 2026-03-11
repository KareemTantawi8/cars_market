import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/category_models.dart';

/// Category Repository - Handles category API calls (brands, models, years, governorates)
class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📦 CategoryRepository: $message');
    }
  }

  /// GET /api/v1/categories/brands - List all brands (API: { data: [{ id, name, slug, meta }] })
  Future<List<BrandModel>> getBrands() async {
    _log('🚗 Fetching brands from: ${ApiEndpoints.brands}');
    try {
      final response = await _apiClient.get(ApiEndpoints.brands);
      _log('✅ Brands response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final brands = BrandsResponse.fromJson(data).brands;
          _log('✅ Parsed ${brands.length} brands');
          return brands;
        }
        if (data is List) {
          final brands = data.whereType<Map<String, dynamic>>().map((e) => BrandModel.fromJson(e)).toList();
          _log('✅ Parsed ${brands.length} brands (raw list)');
          return brands;
        }
        return [];
      } else {
        throw Exception('Failed to load brands: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting brands: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load brands'
            : 'Failed to load brands';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error getting brands: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// GET /api/v1/categories/brands/{brandId}/models - List models under a brand (API: { data: [], brand: {} })
  Future<List<CarModelModel>> getModelsByBrand(int brandId) async {
    final endpoint = ApiEndpoints.brandModels(brandId);
    _log('🚙 Fetching models for brand $brandId from: $endpoint');
    try {
      final response = await _apiClient.get(endpoint);
      _log('✅ Models response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final models = ModelsResponse.fromJson(data).models;
          _log('✅ Parsed ${models.length} models');
          return models;
        }
        if (data is List) {
          final models = data.whereType<Map<String, dynamic>>().map((e) => CarModelModel.fromJson(e)).toList();
          _log('✅ Parsed ${models.length} models (raw list)');
          return models;
        }
        return [];
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting models: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 400) {
          throw Exception('Invalid brand category');
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load models'
            : 'Failed to load models';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error getting models: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// GET /api/v1/categories/models/{modelId}/years - List years under a model (API: { data: [], model: {}, brand: {} })
  Future<List<YearModel>> getYearsByModel(int modelId) async {
    final endpoint = ApiEndpoints.modelYears(modelId);
    _log('📅 Fetching years for model $modelId from: $endpoint');
    try {
      final response = await _apiClient.get(endpoint);
      _log('✅ Years response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final years = YearsResponse.fromJson(data).years;
          _log('✅ Parsed ${years.length} years');
          return years;
        }
        if (data is List) {
          final years = data.whereType<Map<String, dynamic>>().map((e) => YearModel.fromJson(e)).toList();
          _log('✅ Parsed ${years.length} years (raw list)');
          return years;
        }
        return [];
      } else {
        throw Exception('Failed to load years: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting years: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 400) {
          throw Exception('Invalid model category');
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load years'
            : 'Failed to load years';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error getting years: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// GET /api/v1/categories/tree - Full category tree (API: { data: [] }, cached 1h)
  Future<List<dynamic>> getCategoryTree() async {
    _log('🌳 Fetching category tree from: ${ApiEndpoints.categoriesTree}');
    try {
      final response = await _apiClient.get(ApiEndpoints.categoriesTree);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          return data['data'] as List<dynamic>;
        }
        if (data is List) return data;
        return [];
      } else {
        throw Exception('Failed to load category tree: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting category tree: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load category tree'
            : 'Failed to load category tree';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error getting category tree: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// GET /api/v1/governorates - List all active governorates (API: { data: [{ id, name, slug }] }), public
  Future<List<GovernorateModel>> getGovernorates() async {
    _log('🏛️ Fetching governorates from: ${ApiEndpoints.governorates}');
    try {
      final response = await _apiClient.get(ApiEndpoints.governorates);
      _log('✅ Governorates response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final governorates = GovernoratesResponse.fromJson(data).governorates;
          _log('✅ Parsed ${governorates.length} governorates');
          return governorates;
        }
        if (data is List) {
          final governorates = data.whereType<Map<String, dynamic>>().map((e) => GovernorateModel.fromJson(e)).toList();
          _log('✅ Parsed ${governorates.length} governorates (raw list)');
          return governorates;
        }
        return [];
      } else {
        throw Exception('Failed to load governorates: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting governorates: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load governorates'
            : 'Failed to load governorates';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error getting governorates: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ---------- Admin governorates (require governorates.view / create / update / delete) ----------

  /// GET /api/v1/admin/governorates - List all paginated (query: search, per_page)
  Future<Map<String, dynamic>> getAdminGovernorates({
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.adminGovernorates, queryParameters: query);
    if (response.statusCode != 200) throw Exception('Failed to load admin governorates: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid admin governorates response');
    return data;
  }

  /// GET /api/v1/admin/governorates/{id} - Show a governorate
  Future<Map<String, dynamic>> getAdminGovernorate(int id) async {
    final response = await _apiClient.get(ApiEndpoints.adminGovernorateById(id));
    if (response.statusCode != 200) throw Exception('Failed to load governorate: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid governorate response');
    return data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
  }

  /// POST /api/v1/admin/governorates - Create (body: name, slug?, is_active?)
  Future<Map<String, dynamic>> createAdminGovernorate(Map<String, dynamic> body) async {
    final response = await _apiClient.post(ApiEndpoints.adminGovernorateCreate, data: body);
    if (response.statusCode != 201) throw Exception('Failed to create governorate: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid create governorate response');
    return data;
  }

  /// PUT /api/v1/admin/governorates/{id} - Update (body: name?, slug?, is_active?)
  Future<Map<String, dynamic>> updateAdminGovernorate(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.put(ApiEndpoints.adminGovernorateUpdate(id), data: body);
    if (response.statusCode != 200) throw Exception('Failed to update governorate: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid update governorate response');
    return data;
  }

  /// DELETE /api/v1/admin/governorates/{id} - Delete (422 if associated vendors exist)
  Future<void> deleteAdminGovernorate(int id) async {
    final response = await _apiClient.delete(ApiEndpoints.adminGovernorateDelete(id));
    if (response.statusCode != 200) throw Exception('Failed to delete governorate: ${response.statusCode}');
  }

  // ---------- Admin categories (require categories.view / create / update / delete) ----------

  /// GET /api/v1/admin/categories - List all categories (paginated, optional type, parent_id, search)
  Future<Map<String, dynamic>> getAdminCategories({
    String? type,
    int? parentId,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (parentId != null) query['parent_id'] = parentId;
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.adminCategories, queryParameters: query);
    if (response.statusCode != 200) throw Exception('Failed to load admin categories: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid admin categories response');
    return data;
  }

  /// GET /api/v1/admin/categories/{id} - Show a category
  Future<Map<String, dynamic>> getAdminCategory(int id) async {
    final response = await _apiClient.get(ApiEndpoints.adminCategoryById(id));
    if (response.statusCode != 200) throw Exception('Failed to load category: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid category response');
    return data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
  }

  /// POST /api/v1/admin/categories - Create a category
  Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> body) async {
    final response = await _apiClient.post(ApiEndpoints.adminCategoryCreate, data: body);
    if (response.statusCode != 201) throw Exception('Failed to create category: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid create category response');
    return data;
  }

  /// PUT /api/v1/admin/categories/{id} - Update a category
  Future<Map<String, dynamic>> updateAdminCategory(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.put(ApiEndpoints.adminCategoryUpdate(id), data: body);
    if (response.statusCode != 200) throw Exception('Failed to update category: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid update category response');
    return data;
  }

  /// DELETE /api/v1/admin/categories/{id} - Delete a category
  Future<void> deleteAdminCategory(int id) async {
    final response = await _apiClient.delete(ApiEndpoints.adminCategoryDelete(id));
    if (response.statusCode != 200) throw Exception('Failed to delete category: ${response.statusCode}');
  }
}

