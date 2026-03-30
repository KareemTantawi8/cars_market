import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../../features/home/data/repositories/search_requests_repository.dart';
import 'storage_service.dart';
import '../../shared/widgets/common/custom_toast.dart';
import 'notification_payload.dart';

Map<String, dynamic>? parseNotificationMeta(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final d = jsonDecode(raw);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  }
  return null;
}

int? notificationRowId(Map<String, dynamic> notification) {
  final id = notification['id'];
  if (id is int) return id;
  if (id is num) return id.toInt();
  return int.tryParse(id?.toString() ?? '');
}

bool notificationTypeOpensChat(String? type) {
  final t = type?.toLowerCase() ?? '';
  return t == 'new_message' ||
      t == 'search_approved' ||
      t == 'search_request_accepted' ||
      t.contains('message') ||
      (t.contains('search') && t.contains('approv'));
}

/// Opens the right screen for an API notification row or a synthetic map (Reverb / local payload).
Future<void> navigateFromNotificationMap(
  BuildContext context,
  Map<String, dynamic> notification, {
  bool showErrorToast = true,
}) async {
  if (kDebugMode) debugPrint('[NavNotif] TAP type=${notification['type']}');
  final nav = Navigator.of(context, rootNavigator: true);
  final type = notification['type']?.toString();
  final meta = parseNotificationMeta(notification['meta']);
  final nestedData = parseNotificationMeta(notification['data']);

  if (type == 'order_pending' || type == 'new_order') {
    final m = meta;
    final orderId = m?['order_id'];
    if (orderId != null) {
      final oid = orderId is int
          ? orderId
          : (orderId is num
              ? orderId.toInt()
              : int.tryParse(orderId.toString()));
      if (oid != null) {
        nav.pushNamed(
          AppRoutes.orders,
          arguments: {
            'orderId': oid,
            'orderTitle': notification['title']?.toString(),
          },
        );
      }
    }
    return;
  }

  if (type == 'search_request' ||
      type == 'search_request_created' ||
      (type?.contains('search_request') == true && !notificationTypeOpensChat(type))) {
    if (StorageService.getUserType() != AppConstants.userTypeVendor) {
      return;
    }
    final id = meta?['search_request_id'] ?? notification['search_request_id'];
    final sid = id is int ? id : int.tryParse(id?.toString() ?? '');
    nav.pushNamed(
      AppRoutes.vendorIncomingRequests,
      arguments: {if (sid != null) 'searchRequestId': sid},
    );
    return;
  }

  if (type == 'search_request_rejected') {
    return;
  }

  if (!notificationTypeOpensChat(type)) {
    return;
  }

  Map<String, dynamic> payload = Map<String, dynamic>.from(notification);
  if (meta != null) payload['meta'] = meta;
  if (nestedData != null) payload.addAll(nestedData);
  var chatId = parseChatIdFromMap(payload);

  if (chatId == null) {
    final srRaw = meta?['search_request_id'] ??
        nestedData?['search_request_id'] ??
        notification['search_request_id'];
    final srId =
        srRaw is int ? srRaw : int.tryParse(srRaw?.toString() ?? '');
    if (srId != null) {
      try {
        final details =
            await SearchRequestsRepository().getSearchRequestDetails(srId);
        chatId = parseChatIdFromMap({'chat': details['chat']}) ??
            parseChatIdFromMap(details);
      } catch (_) {}
    }
  }

  if (chatId == null) {
    if (showErrorToast && context.mounted) {
      CustomToast.showInfo(
        context,
        'تعذر فتح المحادثة. حاول من قائمة المحادثات.',
      );
    }
    return;
  }

  if (!context.mounted) return;
  final vendorName = meta?['vendor_name']?.toString() ??
      meta?['company_name']?.toString() ??
      nestedData?['vendor_name']?.toString() ??
      nestedData?['company_name']?.toString();
  nav.pushNamed(
    AppRoutes.chatRoom,
    arguments: {
      'chatId': chatId.toString(),
      'chatName': vendorName ??
          notification['title']?.toString() ??
          '',
    },
  );
}
