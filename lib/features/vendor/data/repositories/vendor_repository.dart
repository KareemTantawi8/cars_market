import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Vendor Repository - Handles vendor-specific API calls
class VendorRepository {
  final ApiClient _apiClient;

  VendorRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🏪 VendorRepository: $message');
    }
  }

  /// Get vendor incoming search requests
  /// GET /api/v1/vendor/search-requests
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    _log('📥 Getting incoming search requests');
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorSearchRequests);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'] as List);
        }
        return [];
      } else {
        throw Exception('Failed to get incoming requests: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting incoming requests: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('You must be a vendor');
      }
      throw Exception('Failed to get incoming requests');
    }
  }

  /// Toggle vendor online status
  /// POST /api/v1/vendor/online
  Future<Map<String, dynamic>> toggleOnline() async {
    _log('🔄 Toggling online status');
    try {
      final response = await _apiClient.post(ApiEndpoints.vendorOnline);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to toggle online status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error toggling online status: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to toggle online status'
            : 'Failed to toggle online status';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

