import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/search_request_model.dart';

/// Search Requests Repository - Handles search request (ad) API calls
class SearchRequestsRepository {
  final ApiClient _apiClient;

  SearchRequestsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📝 SearchRequestsRepository: $message');
    }
  }

  /// Create a new search request (ad)
  /// POST /api/v1/search-requests
  Future<Map<String, dynamic>> createSearchRequest({
    required int brandId,
    required int modelId,
    required int governorateId,
    required String partText,
    String? notes,
  }) async {
    _log('📝 Creating search request');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.searchRequests,
        data: {
          'brand_id': brandId,
          'model_id': modelId,
          'governorate_id': governorateId,
          'part_text': partText,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to create search request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error creating search request: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to create search request'
            : 'Failed to create search request';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get my search requests
  /// GET /api/v1/search-requests/my
  Future<List<Map<String, dynamic>>> getMySearchRequests() async {
    _log('📋 Getting my search requests');
    try {
      final response = await _apiClient.get(ApiEndpoints.mySearchRequests);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'] as List);
        }
        return [];
      } else {
        throw Exception('Failed to get search requests: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting search requests: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to get search requests');
    }
  }

  /// Get search request details
  /// GET /api/v1/search-requests/{id}
  Future<Map<String, dynamic>> getSearchRequestDetails(int requestId) async {
    _log('📄 Getting search request details: $requestId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.searchRequestById(requestId),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is Map<String, dynamic>) return inner;
          return data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to get search request details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting search request details: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Search request not found');
      }
      throw Exception('Failed to get search request details');
    }
  }

  /// Accept search request (vendor only)
  /// POST /api/v1/search-requests/{id}/accept
  Future<Map<String, dynamic>> acceptSearchRequest({
    required int requestId,
    required String comment,
  }) async {
    _log('✅ Accepting search request: $requestId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptSearchRequest(requestId),
        data: {
          'comment': comment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to accept search request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error accepting search request: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to accept search request'
            : 'Failed to accept search request';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Reject search request (vendor only)
  /// POST /api/v1/search-requests/{id}/reject
  Future<Map<String, dynamic>> rejectSearchRequest(int requestId) async {
    _log('❌ Rejecting search request: $requestId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rejectSearchRequest(requestId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to reject search request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error rejecting search request: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to reject search request'
            : 'Failed to reject search request';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

