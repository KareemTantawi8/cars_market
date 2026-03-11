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

  /// GET /api/v1/notifications - List user notifications (most recent first). Response: { data: [{ id, type, title, body, read_at, created_at }], meta: {} }. 401 Unauthenticated.
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
        if (data is List) return {'data': data, 'meta': {'current_page': 1, 'last_page': 1, 'total': data.length, 'per_page': 20, 'from': 1, 'to': data.length}};
        return <String, dynamic>{'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0}};
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting notifications: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthenticated.'
              : 'Unauthenticated.';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to get notifications');
    }
  }

  /// POST /api/v1/notifications/{notification}/read - Mark single as read. 200/403 Forbidden/404 Not found.
  Future<void> markAsRead(int notificationId) async {
    _log('✅ Marking notification as read: $notificationId');
    try {
      await _apiClient.post(
        ApiEndpoints.markNotificationAsRead(notificationId),
      );
    } on DioException catch (e) {
      _log('❌ Error marking notification as read: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 404) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Resource not found.'
              : 'Resource not found.';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to mark notification as read');
    }
  }

  /// POST /api/v1/notifications/read-all - Mark all unread as read. 200/401 Unauthenticated.
  Future<void> markAllAsRead() async {
    _log('✅ Marking all notifications as read');
    try {
      await _apiClient.post(ApiEndpoints.markAllNotificationsRead);
    } on DioException catch (e) {
      _log('❌ Error marking all notifications as read: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthenticated.'
              : 'Unauthenticated.';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to mark all notifications as read');
    }
  }
}

