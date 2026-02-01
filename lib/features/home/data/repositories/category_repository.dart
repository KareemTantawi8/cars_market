import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/category_models.dart';

/// Category Repository - Handles category API calls (brands, models, years, governorates)
class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    // ignore: avoid_print
    print('📦 CategoryRepository: $message');
  }

  /// Get all car brands
  Future<List<BrandModel>> getBrands() async {
    _log('🚗 Fetching brands from: ${ApiEndpoints.brands}');
    try {
      final response = await _apiClient.get(ApiEndpoints.brands);

      _log('✅ Brands response status: ${response.statusCode}');
      _log('📄 Brands response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final brands = data.map((e) => BrandModel.fromJson(e as Map<String, dynamic>)).toList();
          _log('✅ Parsed ${brands.length} brands');
          return brands;
        } else if (data is Map<String, dynamic>) {
          final brands = BrandsResponse.fromJson(data).brands;
          _log('✅ Parsed ${brands.length} brands from map');
          return brands;
        }
        return [];
      } else {
        throw Exception('Failed to load brands: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting brands: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load brands'
            : 'Failed to load brands';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error getting brands: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get models for a specific brand
  Future<List<CarModelModel>> getModelsByBrand(int brandId) async {
    final endpoint = ApiEndpoints.brandModels(brandId);
    _log('🚙 Fetching models for brand $brandId from: $endpoint');
    try {
      final response = await _apiClient.get(endpoint);

      _log('✅ Models response status: ${response.statusCode}');
      _log('📄 Models response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final models = data.map((e) => CarModelModel.fromJson(e as Map<String, dynamic>)).toList();
          _log('✅ Parsed ${models.length} models');
          return models;
        } else if (data is Map<String, dynamic>) {
          final models = ModelsResponse.fromJson(data).models;
          _log('✅ Parsed ${models.length} models from map');
          return models;
        }
        return [];
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting models: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load models'
            : 'Failed to load models';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error getting models: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get years for a specific model
  Future<List<YearModel>> getYearsByModel(int modelId) async {
    final endpoint = ApiEndpoints.modelYears(modelId);
    _log('📅 Fetching years for model $modelId from: $endpoint');
    try {
      final response = await _apiClient.get(endpoint);

      _log('✅ Years response status: ${response.statusCode}');
      _log('📄 Years response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final years = data.map((e) => YearModel.fromJson(e as Map<String, dynamic>)).toList();
          _log('✅ Parsed ${years.length} years');
          return years;
        } else if (data is Map<String, dynamic>) {
          final years = YearsResponse.fromJson(data).years;
          _log('✅ Parsed ${years.length} years from map');
          return years;
        }
        return [];
      } else {
        throw Exception('Failed to load years: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting years: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load years'
            : 'Failed to load years';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error getting years: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get all governorates
  Future<List<GovernorateModel>> getGovernorates() async {
    _log('🏛️ Fetching governorates from: ${ApiEndpoints.governorates}');
    try {
      final response = await _apiClient.get(ApiEndpoints.governorates);

      _log('✅ Governorates response status: ${response.statusCode}');
      _log('📄 Governorates response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final governorates = data.map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>)).toList();
          _log('✅ Parsed ${governorates.length} governorates');
          return governorates;
        } else if (data is Map<String, dynamic>) {
          final governorates = GovernoratesResponse.fromJson(data).governorates;
          _log('✅ Parsed ${governorates.length} governorates from map');
          return governorates;
        }
        return [];
      } else {
        throw Exception('Failed to load governorates: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException getting governorates: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Failed to load governorates'
            : 'Failed to load governorates';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error getting governorates: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}

