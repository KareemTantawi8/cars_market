import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Notifications Repository - Handles notifications API calls
class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🔔 NotificationsRepository: $message');
    }
  }

  /// Get notifications (paginated)
  /// GET /api/v1/notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    _log('📋 Getting notifications, page: $page');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting notifications: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to get notifications');
    }
  }

  /// Mark notification as read
  /// POST /api/v1/notifications/{id}/read
  Future<void> markAsRead(int notificationId) async {
    _log('✅ Marking notification as read: $notificationId');
    try {
      await _apiClient.post(
        ApiEndpoints.markNotificationAsRead(notificationId),
      );
    } on DioException catch (e) {
      _log('❌ Error marking notification as read: ${e.message}');
      // Don't throw, this is a non-critical operation
    }
  }

  /// Mark all notifications as read
  /// POST /api/v1/notifications/read-all
  Future<void> markAllAsRead() async {
    _log('✅ Marking all notifications as read');
    try {
      await _apiClient.post(ApiEndpoints.markAllNotificationsRead);
    } on DioException catch (e) {
      _log('❌ Error marking all notifications as read: ${e.message}');
      throw Exception('Failed to mark all notifications as read');
    }
  }
}

