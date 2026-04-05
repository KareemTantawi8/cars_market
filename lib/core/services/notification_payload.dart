import 'dart:convert';

/// Extracts `chat_id` from notification/realtime payload maps (e.g. Reverb `new-message.sent`).
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

/// Reverb `private-vendor.*` / `search-request.created` → same shape as API notification rows.
Map<String, dynamic> vendorSearchRequestNavigationMap(
  Map<String, dynamic> data,
) {
  final sr = data['search_request'];
  Map<String, dynamic>? srMap;
  if (sr is Map<String, dynamic>) {
    srMap = sr;
  } else if (sr is Map) {
    srMap = Map<String, dynamic>.from(sr);
  }

  final id = srMap?['id'];
  final searchRequestId =
      id is int ? id : int.tryParse(id?.toString() ?? '');

  final customer = srMap?['customer'];
  final customerName =
      customer is Map ? customer['name']?.toString() : null;
  final partText = srMap?['part_text']?.toString() ?? '';

  const title = 'طلب بحث جديد';
  final body = [
    if (customerName != null && customerName.isNotEmpty) customerName,
    if (partText.isNotEmpty) partText,
  ].join(' — ');

  return <String, dynamic>{
    'type': 'search_request',
    'title': title,
    'body': body.isEmpty ? partText : body,
    if (searchRequestId != null)
      'meta': {'search_request_id': searchRequestId},
    if (searchRequestId != null) 'search_request_id': searchRequestId,
    'search_request': srMap,
    ...data,
  };
}

/// Stable positive id for [FlutterLocalNotificationsPlugin.show] / [cancel].
int vendorSearchLocalNotificationId(Map<String, dynamic> navMap) {
  final sid = navMap['search_request_id'];
  if (sid is int && sid > 0) return sid;
  final p = int.tryParse(sid?.toString() ?? '');
  if (p != null && p > 0) return p;
  return navMap.hashCode.abs() % 0x7fffffff;
}
