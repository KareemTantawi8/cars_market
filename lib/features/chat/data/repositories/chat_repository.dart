import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Chat Repository - Handles chat API calls
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('💬 ChatRepository: $message');
    }
  }

  /// Get all chats
  /// GET /api/v1/chats
  Future<List<Map<String, dynamic>>> getChats() async {
    _log('📋 Getting chats list');
    try {
      final response = await _apiClient.get(ApiEndpoints.chats);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final raw = data['data'];
          if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
        }
        return [];
      } else {
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting chats: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to get chats');
    }
  }

  /// Get chat details
  /// GET /api/v1/chats/{id}
  Future<Map<String, dynamic>> getChatDetails(int chatId) async {
    _log('📄 Getting chat details: $chatId');
    try {
      final response = await _apiClient.get(ApiEndpoints.chatById(chatId));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is Map<String, dynamic>) return inner;
          return data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to get chat details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting chat details: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Chat not found');
      }
      throw Exception('Failed to get chat details');
    }
  }

  /// Get chat messages (paginated)
  /// GET /api/v1/chats/{id}/messages
  Future<Map<String, dynamic>> getChatMessages({
    required int chatId,
    int page = 1,
  }) async {
    _log('📨 Getting messages for chat: $chatId, page: $page');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.chatMessages(chatId),
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting messages: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to get messages');
    }
  }

  /// Send message
  /// POST /api/v1/chats/{id}/messages
  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String body,
  }) async {
    _log('📤 Sending message to chat: $chatId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendMessage(chatId),
        data: {
          'body': body,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is Map<String, dynamic>) return inner;
          return data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error sending message: ${e.message}');
      
      // Handle 500 errors - sometimes message is created but server has logging issues
      if (e.response?.statusCode == 500) {
        final errorData = e.response!.data;
        
        // Check if the error message contains evidence that the message was created
        // (e.g., "Broadcasting [App\Events\MessageSent]" indicates message was created)
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message']?.toString() ?? ''
            : errorData.toString();
        
        // If error is about log file permissions but message was broadcasted, 
        // the message was likely created successfully
        if (errorMessage.contains('Broadcasting') || 
            errorMessage.contains('MessageSent') ||
            errorMessage.contains('Permission denied')) {
          _log('⚠️ Server error (likely logging issue), but message may have been sent');
          // Try to extract message data from error if available
          // Otherwise, we'll need to reload messages to check
          throw Exception('تم إرسال الرسالة ولكن حدث خطأ في السيرفر. يرجى التحقق من الرسائل.');
        }
      }
      
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'فشل في إرسال الرسالة'
            : 'فشل في إرسال الرسالة';
        throw Exception(errorMessage);
      }
      throw Exception('خطأ في الشبكة: ${e.message}');
    }
  }

  /// Mark chat as read
  /// POST /api/v1/chats/{id}/read
  Future<void> markChatAsRead(int chatId) async {
    _log('✅ Marking chat as read: $chatId');
    try {
      await _apiClient.post(ApiEndpoints.markChatAsRead(chatId));
    } on DioException catch (e) {
      _log('❌ Error marking chat as read: ${e.message}');
      // Don't throw, this is a non-critical operation
    }
  }
}

