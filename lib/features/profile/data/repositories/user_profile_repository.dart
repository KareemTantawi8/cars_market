import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_profile_model.dart';

/// User Profile Repository - Handles user profile API calls
class UserProfileRepository {
  final ApiClient _apiClient;

  UserProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('👤 UserProfileRepository: $message');
    }
  }

  /// Get current user profile
  /// GET /api/v1/auth/me
  /// Requires Authorization header with Bearer token
  Future<UserProfileModel> getCurrentUserProfile() async {
    _log('📋 Fetching current user profile from: ${ApiEndpoints.currentUser}');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.currentUser,
      );

      _log('✅ User profile response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // The API returns data in a nested structure: { "user": {...}, "permissions": [...], ... }
          // Extract the user object from the response
          final userData = data['user'] as Map<String, dynamic>? ?? data;
          final result = UserProfileModel.fromJson(userData);
          _log('✅ Parsed user profile: ${result.name} (ID: ${result.id}), vendor: ${result.vendor != null}');
          return result;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching user profile: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401) {
          throw Exception('غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى');
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب بيانات المستخدم'
            : 'فشل في جلب بيانات المستخدم';
        throw Exception(errorMessage);
      } else {
        throw Exception('خطأ في الشبكة: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error fetching user profile: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

