import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../navigation/root_navigator.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/constants.dart';
import 'notification_navigation.dart';
import 'notification_payload.dart';
import 'realtime_service.dart';
import 'storage_service.dart';

const String _kPushChannelId = 'wesh_sylinder_messages';
const String _kPushChannelName = 'وش سلندر';

/// Background FCM handler (must be top-level). Data-only messages get a local notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification != null) {
    return;
  }

  final data = Map<String, dynamic>.from(message.data);
  final chatId = parseChatIdFromMap(data);
  var title = data['title']?.toString().trim();
  var body = data['body']?.toString().trim();
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    if (chatId == null) return;
    title = 'وش سلندر';
    body = 'لديك رسالة جديدة';
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(init);

  const channel = AndroidNotificationChannel(
    _kPushChannelId,
    _kPushChannelName,
    importance: Importance.high,
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  if (chatId != null) {
    data['chat_id'] = chatId;
  }
  final payload = jsonEncode(data);
  await plugin.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title ?? 'وش سلندر',
    body ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: payload,
  );
}

/// Push + local notifications; tap uses [navigateFromNotificationMap] (chat, vendor incoming, …).
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = _kPushChannelId;
  static const String channelName = _kPushChannelName;

  /// When user opens the app from a notification but routes are not ready yet.
  static String? pendingChatId;
  static String? pendingChatName;

  /// Vendor: `search_request` notification → incoming requests.
  static String? pendingVendorSearchRequestId;

  static void clearPendingNavigation() {
    pendingChatId = null;
    pendingChatName = null;
    pendingVendorSearchRequestId = null;
  }

  Future<void> initialize() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidPermGranted =
        await androidPlugin?.requestNotificationsPermission();
    if (kDebugMode) debugPrint('[FCM] Android notification permission: $androidPermGranted');

    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(androidChannel);

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _storePendingFromPayload(launchDetails!.notificationResponse?.payload);
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) debugPrint('[FCM] permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          storePendingFromRemoteMessage(message);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            tryNavigateToPendingChat();
          });
        });

        final initial = await _messaging.getInitialMessage().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        if (initial != null) {
          storePendingFromRemoteMessage(initial);
        }
      }
    } catch (_) {
      // Firebase Messaging may fail on simulator or without entitlements
    }

    await _saveFcmToken();
    _messaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    _storePendingFromPayload(response.payload);
    tryNavigateToPendingChat();
  }

  static void _storePendingFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final type = map['type']?.toString();
      if (type == 'search_request') {
        pendingChatId = null;
        pendingChatName = null;
        final sid = _parseSearchRequestIdFromPayloadMap(map);
        if (sid != null) {
          pendingVendorSearchRequestId = sid.toString();
        }
        return;
      }
      final id = parseChatIdFromMap(map);
      if (id == null) return;
      pendingVendorSearchRequestId = null;
      pendingChatId = id.toString();
      pendingChatName =
          map['chatName']?.toString() ?? map['sender_name']?.toString();
      final n = map['notification'];
      if (pendingChatName == null && n is Map && n['title'] != null) {
        pendingChatName = n['title']?.toString();
      }
    } catch (_) {}
  }

  static int? _parseSearchRequestIdFromPayloadMap(Map<String, dynamic> map) {
    final direct = map['search_request_id'];
    if (direct is int) return direct;
    if (direct != null) {
      final p = int.tryParse(direct.toString());
      if (p != null) return p;
    }
    final sr = map['search_request'];
    if (sr is Map && sr['id'] != null) {
      final v = sr['id'];
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    final meta = map['meta'];
    if (meta is Map && meta['search_request_id'] != null) {
      final v = meta['search_request_id'];
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    return null;
  }

  static void storePendingFromRemoteMessage(RemoteMessage message) {
    final map = remoteMessageDataToMap(message);
    if (message.notification?.title != null) {
      map['title'] = message.notification!.title;
    }
    if (message.notification?.body != null) {
      map['body'] = message.notification!.body;
    }
    final type = map['type']?.toString();
    if (type == 'search_request') {
      pendingChatId = null;
      pendingChatName = null;
      final sid = _parseSearchRequestIdFromPayloadMap(map);
      if (sid != null) {
        pendingVendorSearchRequestId = sid.toString();
      }
      return;
    }
    final id = parseChatIdFromMap(map);
    if (id == null) return;
    pendingVendorSearchRequestId = null;
    pendingChatId = id.toString();
  }

  /// Call after splash / login pushed the root route so [rootNavigatorKey] is mounted.
  static void tryNavigateToPendingChat() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      return;
    }

    if (pendingVendorSearchRequestId != null &&
        pendingVendorSearchRequestId!.isNotEmpty &&
        StorageService.getUserType() == AppConstants.userTypeVendor) {
      final sid = int.tryParse(pendingVendorSearchRequestId!);
      pendingVendorSearchRequestId = null;
      unawaited(navigateFromNotificationMap(
        ctx,
        {
          'type': 'search_request',
          if (sid != null) 'meta': {'search_request_id': sid},
        },
        showErrorToast: false,
      ));
      return;
    }
    pendingVendorSearchRequestId = null;

    final id = pendingChatId;
    if (id == null || id.isEmpty) return;
    pendingChatId = null;
    final name = pendingChatName;
    pendingChatName = null;

    final chatIdInt = int.tryParse(id);
    unawaited(navigateFromNotificationMap(
      ctx,
      {
        'type': 'new_message',
        if (name != null) 'title': name,
        if (chatIdInt != null) 'chat': {'id': chatIdInt},
        'chat_id': id,
      },
      showErrorToast: false,
    ));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('[FCM] foreground message: notification=${message.notification?.title}, data=${message.data}');
    }
    // Reverb already shows the notification when connected — skip FCM duplicate.
    if (RealtimeService.instance.isConnected) {
      if (kDebugMode) debugPrint('[FCM] skipping foreground – Reverb is connected');
      return;
    }

    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);

    String? title = notification?.title ?? data['title']?.toString();
    String? body = notification?.body ?? data['body']?.toString();

    if (data['notification'] is Map) {
      final n = data['notification'] as Map;
      title ??= n['title']?.toString();
      body ??= n['body']?.toString();
    }

    title ??= 'وش سلندر';
    body ??= '';

    final payloadMap = <String, dynamic>{...data};
    if (notification != null) {
      if (notification.title != null) payloadMap['title'] = notification.title;
      if (notification.body != null) payloadMap['body'] = notification.body;
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body.isEmpty ? title : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payloadMap),
    );
  }

  /// Reverb `new-message.sent` — system notification while app is open (not on active chat).
  Future<void> showNewMessageFromReverb(Map<String, dynamic> data, {required int? activeChatId}) async {
    final chatId = parseChatIdFromMap(data);
    if (chatId == null) return;
    if (activeChatId != null && chatId == activeChatId) return;

    final n = data['notification'];
    String title = 'رسالة جديدة';
    String body = '';
    if (n is Map<String, dynamic>) {
      title = n['title']?.toString() ?? title;
      body = n['body']?.toString() ?? '';
    }
    if (body.isEmpty && data['message'] is Map) {
      final m = data['message'] as Map;
      body = m['body']?.toString() ?? '';
    }

    final payload = jsonEncode({
      ...data,
      'type': 'new_message',
      'chat_id': chatId,
      'title': title,
      'body': body,
    });

    await _localNotifications.show(
      chatId + 100000,
      title,
      body.isEmpty ? title : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('[Push] local notification (Reverb) chatId=$chatId');
    }
  }

  /// `search-request.accepted` — tap opens chat.
  Future<void> showSearchAcceptedFromReverb(Map<String, dynamic> data) async {
    final chatId = parseChatIdFromMap(data);
    if (chatId == null) return;
    final vendor = data['vendor'];
    final vendorName = vendor is Map ? vendor['company_name']?.toString() : null;
    final title = 'تم قبول طلب البحث';
    final body = vendorName != null && vendorName.isNotEmpty
        ? 'قام $vendorName بقبول طلبك'
        : 'يمكنك بدء المحادثة الآن';

    final payload = jsonEncode({
      'type': 'search_approved',
      'chat_id': chatId,
      'chat': {'id': chatId},
      'title': title,
      'body': body,
      if (vendorName != null) 'chatName': vendorName,
    });

    await _localNotifications.show(
      chatId + 200000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Vendor: `search-request.created` — tray tap opens incoming requests.
  Future<void> showVendorNewSearchFromReverb(Map<String, dynamic> data) async {
    if (StorageService.getUserType() != AppConstants.userTypeVendor) return;

    final sr = data['search_request'];
    Map<String, dynamic>? srMap;
    if (sr is Map<String, dynamic>) {
      srMap = sr;
    } else if (sr is Map) {
      srMap = Map<String, dynamic>.from(sr);
    }
    final rawId = srMap?['id'];
    final searchRequestId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (searchRequestId == null) return;

    final customer = srMap?['customer'];
    final customerName = customer is Map
        ? customer['name']?.toString()
        : null;
    final partText = srMap?['part_text']?.toString() ?? '';

    const title = 'طلب بحث جديد';
    final body = [
      if (customerName != null && customerName.isNotEmpty) customerName,
      if (partText.isNotEmpty) partText,
    ].join(' — ');

    final payload = jsonEncode({
      'type': 'search_request',
      'search_request_id': searchRequestId,
      'search_request': srMap,
      'title': title,
      'body': body.isEmpty ? partText : body,
      'meta': {'search_request_id': searchRequestId},
    });

    await _localNotifications.show(
      searchRequestId + 300000,
      title,
      body.isEmpty ? (partText.isEmpty ? title : partText) : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Re-send stored FCM token after login (the initial send may have been skipped
  /// because there was no auth token yet).
  Future<void> resendFcmToken() async => _saveFcmToken();

  Future<void> _saveFcmToken() async {
    try {
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (kDebugMode) debugPrint('[FCM] token=${token != null ? '${token.substring(0, 20)}…' : 'null'}');
      if (token != null) {
        await StorageService.saveString('fcm_token', token);
        await _sendTokenToServer(token);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] _saveFcmToken error: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = StorageService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        if (kDebugMode) debugPrint('[FCM] skip sending token – no auth token');
        return;
      }
      if (kDebugMode) debugPrint('[FCM] sending token to ${ApiEndpoints.updateFcmToken}');
      final response = await ApiClient().dio.post(
        ApiEndpoints.updateFcmToken,
        data: {'fcm_token': token},
      );
      if (kDebugMode) debugPrint('[FCM] ✅ token sent, status=${response.statusCode}');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] ❌ _sendTokenToServer failed: $e');
    }
  }
}
