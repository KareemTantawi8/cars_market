import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Extracts `chat_id` from FCM `data`, local-notification JSON, or Reverb `new-message.sent` payload.
int? parseChatIdFromMap(Map<String, dynamic> data) {
  final direct = data['chat_id'] ?? data['chatId'];
  if (direct != null) {
    if (direct is int) return direct;
    return int.tryParse(direct.toString());
  }

  dynamic meta = data['meta'];
  if (meta is String && meta.isNotEmpty) {
    try {
      final m = jsonDecode(meta);
      if (m is Map) {
        meta = m;
      }
    } catch (_) {}
  }
  if (meta is Map) {
    final id = meta['chat_id'];
    if (id != null) {
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
  }

  final notification = data['notification'];
  if (notification is Map<String, dynamic>) {
    final inner = notification['meta'];
    if (inner is Map) {
      final id = inner['chat_id'];
      if (id != null) {
        if (id is int) return id;
        return int.tryParse(id.toString());
      }
    }
  }

  final chat = data['chat'];
  if (chat is Map) {
    final id = chat['id'];
    if (id != null) {
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
  }

  final message = data['message'];
  if (message is Map) {
    final id = message['chat_id'];
    if (id != null) {
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
  }

  dynamic nested = data['data'];
  if (nested is String && nested.isNotEmpty) {
    try {
      nested = jsonDecode(nested);
    } catch (_) {}
  }
  if (nested is Map) {
    final id = nested['chat_id'] ?? nested['chatId'];
    if (id != null) {
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
    final nestedMeta = nested['meta'];
    if (nestedMeta is Map) {
      final id2 = nestedMeta['chat_id'];
      if (id2 != null) {
        if (id2 is int) return id2;
        return int.tryParse(id2.toString());
      }
    }
  }

  return null;
}

Map<String, dynamic> remoteMessageDataToMap(RemoteMessage message) {
  return Map<String, dynamic>.from(message.data);
}
