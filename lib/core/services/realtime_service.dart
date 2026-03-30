import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../utils/constants.dart';
import 'push_notification_service.dart';
import 'storage_service.dart';

/// Laravel Reverb (Pusher protocol): connects after login, subscribes to role channels,
/// and exposes hooks for chat + vendor feed. See backend realtime / broadcasting docs.
class RealtimeService with WidgetsBindingObserver {
  RealtimeService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final RealtimeService instance = RealtimeService._();

  ReverbClient? _client;
  bool _starting = false;

  bool get isConnected =>
      _client != null && _client!.connectionState == ConnectionState.connected;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final token = StorageService.getAuthToken();
      if (token != null && token.isNotEmpty && !isConnected && !_starting) {
        if (kDebugMode) debugPrint('[Realtime] app resumed → reconnecting');
        unawaited(start());
      }
    }
  }

  /// When non-null, `new-message.sent` should not surface as a global snack (user is in that chat).
  int? activeChatId;

  // —— Customer UI hooks (set from HomeScreen) ——
  void Function(Map<String, dynamic> data)? onCustomerSearchAccepted;
  void Function(Map<String, dynamic> data)? onCustomerNewMessage;

  // —— Vendor incoming-requests UI (set from VendorIncomingRequestsScreen) ——
  void Function(Map<String, dynamic> data)? onVendorFeedCard;
  void Function(Map<String, dynamic> data)? onVendorFeedExpired;
  void Function(Map<String, dynamic> data)? onVendorSearchRequestCreated;
  void Function(Map<String, dynamic> data)? onVendorSearchRejected;

  // —— Vendor personal (new messages on private-user.{userId}) ——
  void Function(Map<String, dynamic> data)? onVendorNewMessage;

  Future<void> start() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    if (_client?.connectionState == ConnectionState.connected) {
      return;
    }

    if (_starting) return;
    _starting = true;

    try {
      // Singleton must be cleared so a new session picks up the latest Sanctum token.
      // ignore: invalid_use_of_visible_for_testing_member
      ReverbClient.resetInstance();
      final ready = Completer<void>();
      _client = ReverbClient.instance(
        host: AppConstants.reverbHost,
        port: AppConstants.reverbPort,
        appKey: AppConstants.reverbAppKey,
        useTLS: AppConstants.reverbUseTls,
        authEndpoint: AppConstants.broadcastingAuthUrl,
        authorizer: (String _, String _) async => {
          'Authorization': 'Bearer $token',
        },
        onConnecting: () {
          if (kDebugMode) {
            debugPrint('[Realtime] connecting…');
          }
        },
        onConnected: (socketId) {
          if (kDebugMode) {
            debugPrint('[Realtime] connected socket=$socketId');
          }
          if (!ready.isCompleted) ready.complete();
          _subscribeForRole();
        },
        onDisconnected: () {
          if (kDebugMode) {
            debugPrint('[Realtime] disconnected');
          }
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('[Realtime] error: $e');
          }
        },
      );

      await _client!.connect();
      await ready.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[Realtime] connection_established timeout');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Realtime] start failed: $e');
      }
    } finally {
      _starting = false;
    }
  }

  /// Tear down websocket (e.g. logout).
  void stop() {
    activeChatId = null;
    onCustomerSearchAccepted = null;
    onCustomerNewMessage = null;
    onVendorFeedCard = null;
    onVendorFeedExpired = null;
    onVendorSearchRequestCreated = null;
    onVendorSearchRejected = null;
    onVendorNewMessage = null;
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      ReverbClient.resetInstance();
    } catch (_) {}
    _client = null;
  }

  void _subscribeForRole() {
    final c = _client;
    if (c == null || c.socketId == null) {
      if (kDebugMode)
        debugPrint('[Realtime] _subscribeForRole: no client/socketId');
      return;
    }

    final userType = StorageService.getUserType();
    final raw = StorageService.getUserData();
    if (raw == null || raw.isEmpty) {
      if (kDebugMode)
        debugPrint('[Realtime] _subscribeForRole: no userData stored');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      if (kDebugMode)
        debugPrint('[Realtime] _subscribeForRole: invalid userData JSON');
      return;
    }

    final userId = json['id'];
    final uid = userId is int ? userId : int.tryParse(userId?.toString() ?? '');
    if (uid == null) {
      if (kDebugMode)
        debugPrint('[Realtime] _subscribeForRole: no userId in userData');
      return;
    }

    if (kDebugMode) debugPrint('[Realtime] role=$userType uid=$uid');

    if (userType == AppConstants.userTypeVendor) {
      final vendor = json['vendor'];
      Map<String, dynamic>? vmap;
      if (vendor is Map<String, dynamic>) vmap = vendor;
      final vendorId = vmap?['id'];
      final vid = vendorId is int
          ? vendorId
          : int.tryParse(vendorId?.toString() ?? '');
      if (kDebugMode)
        debugPrint('[Realtime] vendor object: $vendor → vid=$vid');
      if (vid != null && vid > 0) {
        _bindVendorChannels(c, vendorId: vid);
      } else {
        if (kDebugMode)
          debugPrint('[Realtime] ⚠ no vendorId → skipping vendor channels');
      }
      _bindVendorUserChannel(c, userId: uid);
    } else {
      if (kDebugMode)
        debugPrint('[Realtime] subscribing customer private-user.$uid');
      _bindCustomerUserChannel(c, userId: uid);
    }
  }

  void _bindCustomerUserChannel(ReverbClient c, {required int userId}) {
    try {
      final ch = c.subscribeToPrivateChannel('private-user.$userId');

      ch.bind('search-request.accepted', (_, data) {
        if (kDebugMode)
          debugPrint('[Realtime] ✅ EVENT search-request.accepted received');
        final map = coerceMap(data);
        if (onCustomerSearchAccepted != null) {
          onCustomerSearchAccepted!.call(map);
        } else {
          unawaited(
            PushNotificationService().showSearchAcceptedFromReverb(map),
          );
        }
      });

      ch.bind('new-message.sent', (_, data) {
        if (kDebugMode)
          debugPrint('[Realtime] ✅ EVENT new-message.sent received');
        final map = coerceMap(data);
        final notification = map['notification'];
        if (notification is Map<String, dynamic>) {
          final m = notification['meta'];
          if (m is Map && m['chat_id'] != null) {
            final cid = m['chat_id'] is int
                ? m['chat_id'] as int
                : int.tryParse(m['chat_id'].toString());
            if (cid != null && cid == activeChatId) return;
          }
        }
        if (onCustomerNewMessage != null) {
          onCustomerNewMessage!.call(map);
        } else {
          unawaited(
            PushNotificationService().showNewMessageFromReverb(
              map,
              activeChatId: activeChatId,
            ),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] customer channel auth failed: $e');
    }
  }

  void _bindVendorChannels(ReverbClient c, {required int vendorId}) {
    try {
      final notify = c.subscribeToPrivateChannel('private-vendor.$vendorId');
      if (kDebugMode)
        debugPrint('[Realtime] subscribed to private-vendor.$vendorId');
      notify.bind('search-request.created', (_, data) {
        if (kDebugMode)
          debugPrint('[Realtime] ✅ EVENT search-request.created received');
        final map = coerceMap(data);
        if (onVendorSearchRequestCreated != null) {
          onVendorSearchRequestCreated!.call(map);
        } else {
          unawaited(
            PushNotificationService().showVendorNewSearchFromReverb(map),
          );
        }
      });
      notify.bind('search-request.rejected', (_, data) {
        if (kDebugMode)
          debugPrint('[Realtime] ✅ EVENT search-request.rejected received');
        onVendorSearchRejected?.call(coerceMap(data));
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Realtime] vendor notify channel auth failed: $e');
    }

    try {
      final feed = c.subscribeToPrivateChannel(
        'private-vendor.$vendorId.requests',
      );
      feed.bind('search-request.feed-card', (_, data) {
        onVendorFeedCard?.call(coerceMap(data));
      });
      feed.bind('search-request.expired', (_, data) {
        onVendorFeedExpired?.call(coerceMap(data));
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Realtime] vendor feed channel auth failed: $e');
    }
  }

  /// Vendor personal channel: `new-message.sent` on `private-user.{userId}`.
  void _bindVendorUserChannel(ReverbClient c, {required int userId}) {
    try {
      final ch = c.subscribeToPrivateChannel('private-user.$userId');

      ch.bind('new-message.sent', (_, data) {
        final map = coerceMap(data);
        final notification = map['notification'];
        if (notification is Map<String, dynamic>) {
          final m = notification['meta'];
          if (m is Map && m['chat_id'] != null) {
            final cid = m['chat_id'] is int
                ? m['chat_id'] as int
                : int.tryParse(m['chat_id'].toString());
            if (cid != null && cid == activeChatId) return;
          }
        }
        if (onVendorNewMessage != null) {
          onVendorNewMessage!.call(map);
        } else {
          unawaited(
            PushNotificationService().showNewMessageFromReverb(
              map,
              activeChatId: activeChatId,
            ),
          );
        }
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Realtime] vendor user channel auth failed: $e');
    }
  }

  /// Chat room: live [message.sent] events on `private-chat.{chatId}`.
  void subscribeChat(
    int chatId, {
    required void Function(Map<String, dynamic> data) onMessage,
  }) {
    final c = _client;
    if (c == null || c.socketId == null) return;

    final name = 'private-chat.$chatId';
    c.unsubscribeFromChannel(name);

    try {
      final ch = c.subscribeToPrivateChannel(name);
      ch.bind('message.sent', (String _, dynamic data) {
        onMessage(coerceMap(data));
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] chat channel auth failed: $e');
    }
  }

  void unsubscribeChat(int chatId) {
    _client?.unsubscribeFromChannel('private-chat.$chatId');
  }

  static Map<String, dynamic> coerceMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final d = jsonDecode(data);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return {};
  }
}
