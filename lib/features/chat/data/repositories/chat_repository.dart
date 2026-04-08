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

  /// GET /api/v1/chats - Chat inbox (last message, unread count), sorted by most recent. 401 Unauthenticated.
  Future<List<Map<String, dynamic>>> getChats() async {
    _log('📋 Getting chats list');
    try {
      final response = await _apiClient.get(ApiEndpoints.chats);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final raw = data['data'];
          if (raw is List) {
            return raw.whereType<Map<String, dynamic>>().toList();
          }
        }
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
        return [];
      } else {
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting chats: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthenticated.'
              : 'Unauthenticated.';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to get chats');
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static int? _chatRowId(Map<String, dynamic> c) {
    final id = c['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

  /// True when [vendor] map is the ad seller / target vendor.
  /// When [sellerVendorRecordId] is set, only [vendor.id] may match — avoids
  /// attaching to another vendor row that shares the same user account.
  static bool _vendorParticipantMatches(
    Map<String, dynamic> vendor, {
    required int? sellerUserId,
    required int? sellerVendorRecordId,
  }) {
    if (sellerVendorRecordId != null && sellerVendorRecordId > 0) {
      final vid = _asInt(vendor['id']);
      return vid == sellerVendorRecordId;
    }
    if (sellerUserId != null && sellerUserId > 0) {
      final vu = _asInt(vendor['user_id']);
      if (vu == sellerUserId) return true;
      final u = vendor['user'];
      if (u is Map) {
        final uid = _asInt(Map<String, dynamic>.from(u)['id']);
        if (uid == sellerUserId) return true;
      }
    }
    return false;
  }

  /// Resolves inbox chat with the seller. Pass [sellerVendorRecordId] when known (`vendors.id`).
  Future<int?> findChatIdWithSeller({
    int? sellerUserId,
    int? sellerVendorRecordId,
  }) async {
    if ((sellerUserId == null || sellerUserId <= 0) &&
        (sellerVendorRecordId == null || sellerVendorRecordId <= 0)) {
      return null;
    }

    final chats = await getChats();
    for (final c in chats) {
      final vendor = c['vendor'];
      if (vendor is Map) {
        final vm = Map<String, dynamic>.from(vendor);
        if (_vendorParticipantMatches(
          vm,
          sellerUserId: sellerUserId,
          sellerVendorRecordId: sellerVendorRecordId,
        )) {
          return _chatRowId(c);
        }
      }
    }
    return null;
  }

  /// Verifies [chatId] is with the ad seller (vendor row and/or user id).
  Future<bool> verifyChatWithAdSeller(
    int chatId, {
    required int sellerUserId,
    int? sellerVendorRecordId,
  }) async {
    try {
      final raw = await getChatDetails(chatId);
      final vendor = raw['vendor'];
      if (vendor is! Map) return false;
      return _vendorParticipantMatches(
        Map<String, dynamic>.from(vendor),
        sellerUserId: sellerUserId,
        sellerVendorRecordId: sellerVendorRecordId,
      );
    } catch (_) {
      return false;
    }
  }

  /// Resolves inbox thread or creates one, then confirms via [getChatDetails].
  Future<int?> openChatWithAdSeller({
    required int sellerUserId,
    int? sellerVendorRecordId,
  }) async {
    if (sellerUserId <= 0) return null;

    var chatId = await findChatIdWithSeller(
      sellerUserId: sellerUserId,
      sellerVendorRecordId: sellerVendorRecordId,
    );

    if (chatId != null) {
      final ok = await verifyChatWithAdSeller(
        chatId,
        sellerUserId: sellerUserId,
        sellerVendorRecordId: sellerVendorRecordId,
      );
      if (!ok) chatId = null;
    }

    chatId ??= await createChatWithUser(sellerUserId);

    if (chatId == null) return null;

    final verified = await verifyChatWithAdSeller(
      chatId,
      sellerUserId: sellerUserId,
      sellerVendorRecordId: sellerVendorRecordId,
    );
    return verified ? chatId : null;
  }

  /// GET /api/v1/chats/{id} - Chat details with customer, vendor, linked search request. Must be participant. 403 Forbidden.
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
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthenticated.'
              : 'Unauthenticated.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 404) {
          throw Exception('Chat not found');
        }
      }
      throw Exception('Failed to get chat details');
    }
  }

  /// GET /api/v1/chats/{chatId}/messages - List messages (latest first, paginated). Response: { data: [], meta: { current_page, per_page, total, last_page, from, to } }. 403 Forbidden.
  Future<Map<String, dynamic>> getChatMessages({
    required int chatId,
    int page = 1,
    int perPage = 50,
  }) async {
    _log('📨 Getting messages for chat: $chatId, page: $page');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.chatMessages(chatId),
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        if (data is List) return {'data': data, 'meta': {'current_page': 1, 'last_page': 1, 'per_page': perPage, 'total': data.length, 'from': 1, 'to': data.length}};
        return <String, dynamic>{'data': [], 'meta': {'current_page': 1, 'last_page': 1}};
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting messages: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 401) {
          throw Exception('Unauthorized');
        }
      }
      throw Exception('Failed to get messages');
    }
  }

  /// POST /api/v1/chats/{chatId}/messages - Send message. Body: { body }. Response 201: { message, data }. 403 Forbidden, 422 Validation.
  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String body,
  }) async {
    _log('📤 Sending message to chat: $chatId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendMessage(chatId),
        data: {'body': body},
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
      if (e.response != null) {
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 422) {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            final message = errorData['message']?.toString() ?? 'Validation failed';
            final errors = errorData['errors'];
            if (errors != null && errors is Map<String, dynamic>) {
              final parts = <String>[message];
              for (final entry in errors.entries) {
                final v = entry.value;
                final text = v is List && v.isNotEmpty ? v.map((e) => e.toString()).join(', ') : v?.toString() ?? '';
                if (text.isNotEmpty) parts.add('${entry.key}: $text');
              }
              throw Exception(parts.join('\n'));
            }
          }
          throw Exception(errorData['message']?.toString() ?? 'Validation failed');
        }
        if (e.response!.statusCode == 500) {
          final errorData = e.response!.data;
          final errorMessage = errorData is Map<String, dynamic>
              ? errorData['message']?.toString() ?? ''
              : errorData.toString();
          if (errorMessage.contains('Broadcasting') ||
              errorMessage.contains('MessageSent') ||
              errorMessage.contains('Permission denied')) {
            _log('⚠️ Server error (likely logging issue), but message may have been sent');
            throw Exception('تم إرسال الرسالة ولكن حدث خطأ في السيرفر. يرجى التحقق من الرسائل.');
          }
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'فشل في إرسال الرسالة'
            : 'فشل في إرسال الرسالة';
        throw Exception(errorMessage);
      }
      throw Exception('خطأ في الشبكة: ${e.message}');
    }
  }

  /// POST /api/v1/chats - Create/start a new chat with a user. Body: { user_id }.
  /// Returns the new chat id, or null if not supported.
  Future<int?> createChatWithUser(int userId) async {
    _log('🆕 Creating chat with user: $userId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.chats,
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          final chatData = inner is Map<String, dynamic> ? inner : data;
          final id = chatData['id'];
          if (id is int) return id;
          if (id is num) return id.toInt();
          return int.tryParse(id?.toString() ?? '');
        }
      }
      return null;
    } on DioException catch (e) {
      _log('❌ Error creating chat: ${e.message}');
      final code = e.response?.statusCode;
      if (code == 422 || code == 409) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is Map<String, dynamic>) {
            final id = inner['id'];
            if (id is int) return id;
            if (id is num) return id.toInt();
            final p = int.tryParse(id?.toString() ?? '');
            if (p != null) return p;
          }
        }
      }
      return null;
    }
  }

  /// POST /api/v1/chats/{id}/read - Mark all messages in chat as read. Response: { message, read_count }. 403 Forbidden.
  /// Returns read_count if present for UI (e.g. unread badge update).
  Future<int> markChatAsRead(int chatId) async {
    _log('✅ Marking chat as read: $chatId');
    try {
      final response = await _apiClient.post(ApiEndpoints.markChatAsRead(chatId));
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final count = data['read_count'];
        if (count is int) return count;
        if (count is num) return count.toInt();
      }
      return 0;
    } on DioException catch (e) {
      _log('❌ Error marking chat as read: ${e.message}');
      if (e.response?.statusCode == 403) {
        final msg = e.response!.data is Map<String, dynamic>
            ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
            : 'Unauthorized action.';
        throw Exception(msg);
      }
      // Don't throw for other errors; non-critical operation
      return 0;
    }
  }
}

