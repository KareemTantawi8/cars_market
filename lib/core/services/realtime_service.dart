
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../utils/constants.dart';
import 'notification_payload.dart';
import 'push_notification_service.dart';
import 'storage_service.dart';

/// Laravel Reverb (Pusher protocol): connects after login, subscribes to role channels,
/// and exposes hooks for chat + vendor feed.
class RealtimeService with WidgetsBindingObserver {
  RealtimeService._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final RealtimeService instance = RealtimeService._();

  ReverbClient? _client;
  bool _starting = false;
  Timer? _disconnectApiSyncTimer;

  bool get isConnected =>
      _client != null && _client!.connectionState == ConnectionState.connected;

  int? activeChatId;

  void Function(Map<String, dynamic> data)? onCustomerSearchAccepted;
  void Function(Map<String, dynamic> data)? onCustomerNewMessage;

  void Function(Map<String, dynamic> data)? onVendorFeedCard;
  void Function(Map<String, dynamic> data)? onVendorFeedExpired;
  void Function(Map<String, dynamic> data)? onVendorSearchRequestCreated;
  void Function(Map<String, dynamic> data)? onVendorSearchRejected;
  void Function(Map<String, dynamic> data)? onVendorNewMessage;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final token = StorageService.getAuthToken();
      if (token != null && token.isNotEmpty && !isConnected && !_starting) {
        if (kDebugMode) {
          debugPrint('[Realtime] app resumed -> reconnecting');
        }
        unawaited(start());
      }
      // Reverb disconnects in background — catch missed notification rows from REST.
      unawaited(
        PushNotificationService.instance
            .syncMissedNotificationsFromApiOnResume(),
      );
    }
  }

  Future<void> start() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    if (_client?.connectionState == ConnectionState.connected) return;
    if (_starting) return;
    _starting = true;

    try {
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
          if (kDebugMode) debugPrint('[Realtime] connecting...');
        },
        onConnected: (socketId) {
          if (kDebugMode) debugPrint('[Realtime] connected socket=$socketId');
          if (!ready.isCompleted) ready.complete();
          _subscribeForRole();
        },
        onDisconnected: () {
          if (kDebugMode) debugPrint('[Realtime] disconnected');
          _scheduleNotificationSyncOnDisconnect();
        },
        onError: (e) {
          if (kDebugMode) debugPrint('[Realtime] error: $e');
        },
      );

      await _client!.connect();
      await ready.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          if (kDebugMode) debugPrint('[Realtime] connection timeout');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] start failed: $e');
    } finally {
      _starting = false;
    }
  }

  void _scheduleNotificationSyncOnDisconnect() {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    _disconnectApiSyncTimer?.cancel();
    _disconnectApiSyncTimer = Timer(const Duration(milliseconds: 450), () {
      _disconnectApiSyncTimer = null;
      if (kDebugMode) {
        debugPrint('[Realtime] disconnect debounce → API notification sync');
      }
      unawaited(
        PushNotificationService.instance
            .syncMissedNotificationsFromApiOnDisconnect(),
      );
    });
  }

  void stop() {
    _disconnectApiSyncTimer?.cancel();
    _disconnectApiSyncTimer = null;
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
    if (c == null || c.socketId == null) return;

    final userType = StorageService.getUserType();
    final raw = StorageService.getUserData();
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final userId = json['id'];
    final uid = userId is int ? userId : int.tryParse(userId?.toString() ?? '');
    if (uid == null) return;

    if (userType == AppConstants.userTypeVendor) {
      final vendor = json['vendor'];
      Map<String, dynamic>? vmap;
      if (vendor is Map<String, dynamic>) vmap = vendor;
      final vendorId = vmap?['id'];
      final vid = vendorId is int
          ? vendorId
          : int.tryParse(vendorId?.toString() ?? '');
      if (vid != null && vid > 0) {
        _bindVendorChannels(c, vendorId: vid);
      }
      _bindVendorUserChannel(c, userId: uid);
    } else {
      _bindCustomerUserChannel(c, userId: uid);
    }
  }

  void _bindCustomerUserChannel(ReverbClient c, {required int userId}) {
    try {
      final ch = c.subscribeToPrivateChannel('private-user.$userId');

      ch.bind('search-request.accepted', (_, data) {
        final map = coerceMap(data);
        if (onCustomerSearchAccepted != null) {
          onCustomerSearchAccepted!.call(map);
        }
      });

      ch.bind('new-message.sent', (_, data) {
        final map = coerceMap(data);
        if (_isForActiveChat(map)) return;
        unawaited(
          PushNotificationService.instance.showChatMessageReverbTray(map),
        );
        if (onCustomerNewMessage != null) {
          onCustomerNewMessage!.call(map);
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] customer auth failed: $e');
    }
  }

  void _bindVendorChannels(ReverbClient c, {required int vendorId}) {
    try {
      final notify = c.subscribeToPrivateChannel('private-vendor.$vendorId');
      notify.bind('search-request.created', (_, data) {
        final map = coerceMap(data);
        unawaited(_deliverVendorSearchCreated(map));
      });
      notify.bind('search-request.rejected', (_, data) {
        onVendorSearchRejected?.call(coerceMap(data));
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] vendor notify auth failed: $e');
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
      if (kDebugMode) debugPrint('[Realtime] vendor feed auth failed: $e');
    }
  }

  void _bindVendorUserChannel(ReverbClient c, {required int userId}) {
    try {
      final ch = c.subscribeToPrivateChannel('private-user.$userId');
      ch.bind('new-message.sent', (_, data) {
        final map = coerceMap(data);
        if (_isForActiveChat(map)) return;
        unawaited(
          PushNotificationService.instance.showChatMessageReverbTray(map),
        );
        if (onVendorNewMessage != null) {
          onVendorNewMessage!.call(map);
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] vendor user auth failed: $e');
    }
  }

  void subscribeChat(
    int chatId, {
    required void Function(Map<String, dynamic> data) onMessage,
    void Function(Map<String, dynamic> data)? onUserStatusChanged,
  }) {
    final c = _client;
    if (c == null || c.socketId == null) return;

    final name = 'private-chat.$chatId';
    c.unsubscribeFromChannel(name);

    try {
      final ch = c.subscribeToPrivateChannel(name);
      ch.bind('message.sent', (_, data) {
        onMessage(coerceMap(data));
      });
      if (onUserStatusChanged != null) {
        for (final event in const [
          'UserStatusChanged',
          'App\\Events\\UserStatusChanged',
          '.UserStatusChanged',
        ]) {
          ch.bind(event, (_, data) {
            onUserStatusChanged(coerceMap(data));
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] chat auth failed: $e');
    }
  }

  void unsubscribeChat(int chatId) {
    _client?.unsubscribeFromChannel('private-chat.$chatId');
  }

  bool _isForActiveChat(Map<String, dynamic> map) {
    final active = activeChatId;
    if (active == null) return false;
    final cid = parseChatIdFromMap(map);
    return cid != null && cid == active;
  }

  static Map<String, dynamic> coerceMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  /// Tray first (always), then UI callback (overlay when resumed, or cubit refresh).
  Future<void> _deliverVendorSearchCreated(Map<String, dynamic> map) async {
    try {
      await PushNotificationService.instance.showVendorSearchReverbTray(map);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Realtime] vendor search tray failed: $e\n$st');
      }
    }
    onVendorSearchRequestCreated?.call(map);
  }
}

