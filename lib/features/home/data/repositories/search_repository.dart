import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/search_request_model.dart';
import '../models/search_response_model.dart';

/// Search Repository - Handles search API calls
class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🔍 SearchRepository: $message');
    }
  }

  /// Search for suppliers based on part specifications
  /// POST /api/v1/search-requests
  Future<SearchResponseModel> searchSuppliers(
    SearchRequestModel request,
  ) async {
    _log('🔎 Searching suppliers at: ${ApiEndpoints.searchRequests}');
    _log('📤 Request data: ${request.toJson()}');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.searchRequests,
        data: request.toJson(),
      );

      _log('✅ Search response status: ${response.statusCode}');
      _log('📄 Search response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle different response formats
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = SearchResponseModel.fromJson(data);
          _log('✅ Parsed ${result.suppliers.length} suppliers');
          return result;
        }
        return SearchResponseModel(suppliers: [], totalCount: 0);
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException searching: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Search failed'
            : 'Search failed';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error searching: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}

