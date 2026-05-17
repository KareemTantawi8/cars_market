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

  int? _extractChatIdFromPayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;
    final inner = payload['data'];
    final chatData = inner is Map<String, dynamic> ? inner : payload;
    final id = chatData['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
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
              ? (e.response!.data as Map<String, dynamic>)['message']
                        ?.toString() ??
                    'Unauthenticated.'
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

  static int? _chatAdId(Map<String, dynamic> c) {
    final direct = _asInt(c['ad_id']);
    if (direct != null && direct > 0) return direct;
    final ad = _asMap(c['ad']);
    if (ad != null) {
      final nested = _asInt(ad['id']);
      if (nested != null && nested > 0) return nested;
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static Map<String, dynamic>? _participantFromChatEnvelope(
    Map<String, dynamic> c,
  ) {
    final participant = _asMap(c['participant']);
    if (participant != null) return participant;
    return null;
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

  /// True when unified [participant] map matches seller account and/or vendor row.
  static bool _participantMatchesSeller(
    Map<String, dynamic> participant, {
    required int? sellerUserId,
    required int? sellerVendorRecordId,
  }) {
    if (sellerVendorRecordId != null && sellerVendorRecordId > 0) {
      for (final raw in [
        participant['vendor_id'],
        participant['seller_vendor_id'],
        participant['vendorId'],
      ]) {
        if (_asInt(raw) == sellerVendorRecordId) return true;
      }
      final vendor = participant['vendor'];
      if (vendor is Map) {
        if (_asInt(Map<String, dynamic>.from(vendor)['id']) ==
            sellerVendorRecordId) {
          return true;
        }
      }
      final role =
          participant['type']?.toString().toLowerCase() ??
          participant['role']?.toString().toLowerCase() ??
          '';
      final looksLikeVendor =
          role.contains('vendor') || participant['company_name'] != null;
      if (looksLikeVendor &&
          _asInt(participant['id']) == sellerVendorRecordId) {
        return true;
      }
    }

    if (sellerUserId != null && sellerUserId > 0) {
      for (final raw in [
        participant['user_id'],
        participant['account_id'],
        participant['owner_id'],
        participant['id'],
      ]) {
        if (_asInt(raw) == sellerUserId) return true;
      }
      final user = participant['user'];
      if (user is Map) {
        if (_asInt(Map<String, dynamic>.from(user)['id']) == sellerUserId) {
          return true;
        }
      }
    }

    return false;
  }

  /// True when [participant] is the given user account (customer or vendor user).
  static bool _participantMatchesUserAccount(
    Map<String, dynamic> participant, {
    required int userId,
  }) {
    if (userId <= 0) return false;
    for (final raw in [
      participant['user_id'],
      participant['account_id'],
      participant['owner_id'],
    ]) {
      if (_asInt(raw) == userId) return true;
    }
    final user = participant['user'];
    if (user is Map) {
      if (_asInt(Map<String, dynamic>.from(user)['id']) == userId) {
        return true;
      }
    }
    final role =
        participant['type']?.toString().toLowerCase() ??
        participant['role']?.toString().toLowerCase() ??
        '';
    final looksLikeVendor =
        role.contains('vendor') || participant['company_name'] != null;
    if (!looksLikeVendor && _asInt(participant['id']) == userId) {
      return true;
    }
    return false;
  }

  static bool _legacyPartyMatchesUser(Map<String, dynamic> party, int userId) {
    if (userId <= 0) return false;
    if (_asInt(party['user_id']) == userId) return true;
    final user = party['user'];
    if (user is Map && _asInt(Map<String, dynamic>.from(user)['id']) == userId) {
      return true;
    }
    final role = party['type']?.toString().toLowerCase() ?? '';
    if (!role.contains('vendor') &&
        party['company_name'] == null &&
        _asInt(party['id']) == userId) {
      return true;
    }
    return false;
  }

  /// Inbox thread with a user account (customer↔vendor or vendor↔customer).
  Future<int?> findChatIdWithUser(int otherUserId) async {
    if (otherUserId <= 0) return null;
    final chats = await getChats();
    for (final c in chats) {
      final cid = _chatRowId(c);
      if (cid == null || cid <= 0) continue;

      final participant = _participantFromChatEnvelope(c);
      if (participant != null &&
          _participantMatchesUserAccount(participant, userId: otherUserId)) {
        return cid;
      }

      for (final key in ['customer', 'vendor', 'user', 'buyer', 'client']) {
        final raw = c[key];
        if (raw is Map &&
            _legacyPartyMatchesUser(Map<String, dynamic>.from(raw), otherUserId)) {
          return cid;
        }
      }
    }
    return null;
  }

  /// Resolves inbox thread or creates one with [otherUserId].
  Future<int?> openChatWithUser(int otherUserId) async {
    if (otherUserId <= 0) return null;
    var chatId = await findChatIdWithUser(otherUserId);
    chatId ??= await createChatWithUser(otherUserId);
    chatId ??= await findChatIdWithUser(otherUserId);
    return chatId;
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
      final participant = _participantFromChatEnvelope(c);
      if (participant != null &&
          _participantMatchesSeller(
            participant,
            sellerUserId: sellerUserId,
            sellerVendorRecordId: sellerVendorRecordId,
          )) {
        return _chatRowId(c);
      }
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
      final participant = _participantFromChatEnvelope(raw);
      if (participant != null &&
          _participantMatchesSeller(
            participant,
            sellerUserId: sellerUserId,
            sellerVendorRecordId: sellerVendorRecordId,
          )) {
        return true;
      }
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

  /// Looks for an inbox chat linked to [adId] via chat `ad.id`/`ad_id`.
  Future<int?> findChatIdForAd(int adId) async {
    if (adId <= 0) return null;
    final chats = await getChats();
    for (final c in chats) {
      final cid = _chatRowId(c);
      if (cid == null || cid <= 0) continue;
      if (_chatAdId(c) == adId) return cid;
    }
    return null;
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
              ? (e.response!.data as Map<String, dynamic>)['message']
                        ?.toString() ??
                    'Unauthenticated.'
              : 'Unauthenticated.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']
                        ?.toString() ??
                    'Unauthorized action.'
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
        if (data is List)
          return {
            'data': data,
            'meta': {
              'current_page': 1,
              'last_page': 1,
              'per_page': perPage,
              'total': data.length,
              'from': 1,
              'to': data.length,
            },
          };
        return <String, dynamic>{
          'data': [],
          'meta': {'current_page': 1, 'last_page': 1},
        };
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error getting messages: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']
                        ?.toString() ??
                    'Unauthorized action.'
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
              ? (e.response!.data as Map<String, dynamic>)['message']
                        ?.toString() ??
                    'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 422) {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            final message =
                errorData['message']?.toString() ?? 'Validation failed';
            final errors = errorData['errors'];
            if (errors != null && errors is Map<String, dynamic>) {
              final parts = <String>[message];
              for (final entry in errors.entries) {
                final v = entry.value;
                final text = v is List && v.isNotEmpty
                    ? v.map((e) => e.toString()).join(', ')
                    : v?.toString() ?? '';
                if (text.isNotEmpty) parts.add('${entry.key}: $text');
              }
              throw Exception(parts.join('\n'));
            }
          }
          throw Exception(
            errorData['message']?.toString() ?? 'Validation failed',
          );
        }
        if (e.response!.statusCode == 500) {
          final errorData = e.response!.data;
          final errorMessage = errorData is Map<String, dynamic>
              ? errorData['message']?.toString() ?? ''
              : errorData.toString();
          if (errorMessage.contains('Broadcasting') ||
              errorMessage.contains('MessageSent') ||
              errorMessage.contains('Permission denied')) {
            _log(
              '⚠️ Server error (likely logging issue), but message may have been sent',
            );
            throw Exception(
              'تم إرسال الرسالة ولكن حدث خطأ في السيرفر. يرجى التحقق من الرسائل.',
            );
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

  /// POST /api/v1/ads/{adId}/chats - Start or resume chat with the ad owner.
  /// Returns the chat id on success, or null on failure.
  Future<int?> startChatForAd(int adId) async {
    _log('💬 Starting chat for ad: $adId');
    final routeCandidates = <String>[
      ApiEndpoints.startChatForAd(adId),
      ApiEndpoints.startChatForAdLegacy(adId),
    ];

    for (final route in routeCandidates) {
      try {
        final response = await _apiClient.post(
          route,
          data: <String, dynamic>{},
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return _extractChatIdFromPayload(response.data);
        }
      } on DioException catch (e) {
        _log('❌ Error starting chat for ad on $route: ${e.message}');
        final code = e.response?.statusCode;
        final body = e.response?.data;
        final msg = body is Map<String, dynamic>
            ? body['message']?.toString()
            : null;

        // Try next known route variant if this one does not exist.
        if (code == 404) continue;

        if (code == 401) throw Exception(msg ?? 'Unauthenticated.');
        if (code == 403) throw Exception(msg ?? 'Unauthorized action.');
        if (code == 422) throw Exception(msg ?? 'تعذّر بدء المحادثة');
        if (msg != null && msg.isNotEmpty) throw Exception(msg);
        throw Exception('تعذّر بدء المحادثة');
      }
    }

    // Last compatibility fallback: some deployments create chat via /chats + ad_id.
    _log('⚠️ ad chat endpoints unavailable, trying /chats with ad_id');
    return _startChatForAdViaChatsEndpoint(adId);
  }

  Future<int?> _startChatForAdViaChatsEndpoint(int adId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.chats,
        data: {'ad_id': adId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _extractChatIdFromPayload(response.data);
      }
      return null;
    } on DioException catch (e) {
      _log('❌ /chats ad_id fallback failed: ${e.message}');
      final code = e.response?.statusCode;
      final data = e.response?.data;
      if (code == 422 || code == 409) {
        return _extractChatIdFromPayload(data);
      }
      return null;
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
        return _extractChatIdFromPayload(response.data);
      }
      return null;
    } on DioException catch (e) {
      _log('❌ Error creating chat: ${e.message}');
      final code = e.response?.statusCode;
      if (code == 422 || code == 409) {
        final fromBody = _extractChatIdFromPayload(e.response?.data);
        if (fromBody != null) return fromBody;
        return findChatIdWithUser(userId);
      }
      return null;
    }
  }

  /// POST /api/v1/chats/{id}/read - Mark all messages in chat as read. Response: { message, read_count }. 403 Forbidden.
  /// Returns read_count if present for UI (e.g. unread badge update).
  Future<int> markChatAsRead(int chatId) async {
    _log('✅ Marking chat as read: $chatId');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.markChatAsRead(chatId),
      );
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
            ? (e.response!.data as Map<String, dynamic>)['message']
                      ?.toString() ??
                  'Unauthorized action.'
            : 'Unauthorized action.';
        throw Exception(msg);
      }
      // Don't throw for other errors; non-critical operation
      return 0;
    }
  }
}
