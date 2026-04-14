import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation/root_navigator.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import 'notification_payload.dart';
import 'storage_service.dart';

// -----------------------------------------------------------------------------
// Killed / swiped-away app: only FCM can alert. Reverb and GET /notifications
// do not run until the process starts again — reopen "delayed" toasts come from
// syncMissedNotificationsFromApi*, not from a push that fired while dead.
//
// REQUIRED backend payload (FCM HTTP v1) for reliable killed-state delivery on
// BOTH vendor and customer devices, sent to every token from POST /device-tokens:
//
//   {
//     "token": "<fcm_token>",
//     "android": {
//       "priority": "high",
//       "notification": {
//         "title": "...",
//         "body":  "...",
//         "channel_id": "high_importance_channel",
//         "sound": "default"
//       }
//     },
//     "apns": {
//       "headers": { "apns-priority": "10" },
//       "payload": { "aps": { "alert": { "title": "...", "body": "..." }, "sound": "default" } }
//     },
//     "notification": { "title": "...", "body": "..." },
//     "data": {
//       "type": "search_request" | "new-message" | "order" | "order_accepted",
//       "search_request_id": "91",      // when type=search_request
//       "chat_id": "42",                 // when type=new-message
//       "order_id": "17",                // when type=order*
//       "notification_row_id": "97"      // == GET /notifications data[].id (dedupe)
//     }
//   }
//
// Why the `notification` block matters: when it's present, Android/iOS show the
// tray from the OS kernel — works even if the app is fully killed and Dart never
// runs. Data-only messages only display if our background isolate can wake, and
// many OEMs (Xiaomi, Huawei, Samsung, Oppo, Vivo) block that when the app is
// swiped away. Always include BOTH the notification and data blocks.
// -----------------------------------------------------------------------------

// Channel constants shared between foreground and background isolates.
// Must match the channel_id sent by the backend in FCM android.notification.
const _channelId = 'high_importance_channel';
const _channelName = 'وش سلندر';
const _channelDesc = 'إشعارات تطبيق وش سلندر';

/// Android small icon: white silhouette drawable (not @mipmap/ic_launcher).
const _androidNotificationIcon = '@drawable/ic_stat_washslender';

String _stringFromData(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return '';
}

/// When the server sends data-only FCM (no `notification` block), title/body may be missing.
(String, String) _fallbackTitleBodyForDataOnly(
  String type,
  Map<String, dynamic> data,
) {
  switch (type) {
    case 'search_request_created':
    case 'search_request':
    case 'new_request':
    case 'search-request':
    case 'search-request.created':
      final part = _stringFromData(data, const ['part_text', 'partText']);
      if (part.isNotEmpty) {
        return ('طلب بحث جديد', 'العميل يبحث عن: $part');
      }
      return ('طلب بحث جديد', 'افتح التطبيق لعرض الطلب');
    case 'new-message':
    case 'new_message':
    case 'chat':
      return ('رسالة جديدة', 'افتح التطبيق للمحادثة');
    default:
      if (type.isNotEmpty) {
        return (_channelName, 'لديك إشعار جديد');
      }
      return ('', '');
  }
}

/// Same numeric space as API sync tray (`10_000_000 + GET /notifications data[].id`).
int _localTrayIdForFcmData(
  Map<String, dynamic> data, {
  required int messageHash,
}) {
  for (final k in ['notification_row_id', 'api_notification_id']) {
    final v = data[k];
    if (v == null) continue;
    final p = v is int ? v : int.tryParse(v.toString());
    if (p != null && p > 0) return 10_000_000 + p;
  }
  final sid = data['search_request_id'];
  if (sid != null) {
    final p = sid is int ? sid : int.tryParse(sid.toString());
    if (p != null && p > 0) return p;
  }
  return messageHash;
}

/// Top-level handler for background / killed app (see [FirebaseMessaging.onBackgroundMessage]).
///
/// When the FCM payload includes a `notification` block, the OS displays the tray itself
/// (Android system notification, iOS APNs alert) — this is the reliable path for killed apps
/// and we must NOT duplicate it from this isolate.
///
/// For data-only payloads, the OS will not display anything, so this handler creates a local
/// tray. Note: data-only delivery to killed apps is unreliable on many Android OEMs; backend
/// should prefer sending `notification` + `data` together.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only if not already initialized in this isolate.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (e, st) {
      developer.log(
        'Firebase.initializeApp failed: $e\n$st',
        name: 'FCM.bg',
        error: e,
        stackTrace: st,
      );
      return;
    }
  }

  developer.log(
    'messageId=${message.messageId} hasNotif=${message.notification != null} '
    'keys=${message.data.keys.toList()}',
    name: 'FCM.bg',
  );
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
    debugPrint('[FCM] notification: ${message.notification?.title}');
    debugPrint('[FCM] data: ${message.data}');
  }

  final data = message.data;
  final n = message.notification;

  var title = (n?.title ?? '').trim();
  var body = (n?.body ?? '').trim();

  if (title.isEmpty) {
    title = _stringFromData(data, const [
      'title',
      'gcm.notification.title',
      'notification_title',
    ]);
  }
  if (body.isEmpty) {
    body = _stringFromData(data, const [
      'body',
      'gcm.notification.body',
      'message',
      'notification_body',
      'content',
    ]);
  }

  if (title.isEmpty && body.isEmpty) {
    final fb = _fallbackTitleBodyForDataOnly(
      data['type']?.toString() ?? '',
      data,
    );
    title = fb.$1;
    body = fb.$2;
  }

  if (title.isEmpty && body.isEmpty) return;

  // When FCM carries a notification block, the OS already shows the tray
  // (Android system UI / iOS APNs). Skip local duplication on both platforms.
  if (n != null) return;

  final trayId = _localTrayIdForFcmData(message.data, messageHash: message.hashCode);

  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings(_androidNotificationIcon);
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await plugin.initialize(initSettings);

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
        ),
      );

  await plugin.show(
    trayId,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: _androidNotificationIcon,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.max,
  );

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  DateTime? _lastApiNotificationSync;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // onBackgroundMessage is registered from main() immediately after Firebase.initializeApp().

    // iOS: safe to request from isolate startup.
    // Android 13+: FCM's requestPermission needs an attached Activity; calling it
    // from main() before runApp() often yields no dialog and denied banners.
    if (Platform.isIOS) {
      await _requestIosNotificationPermission();
    }

    await _setupLocalNotifications();
    await _handleLocalNotificationColdStart();

    if (Platform.isAndroid) {
      _scheduleAndroidNotificationPermissionAfterFirstFrame();
    }

    _listenForeground();
    _listenNotificationTaps();
    _listenTokenRefresh();
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<void> _requestIosNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('[FCM] iOS permission: ${settings.authorizationStatus}');
    }
  }

  /// Android 13+ POST_NOTIFICATIONS — run after the first frame so
  /// `FlutterFirebaseMessagingPlugin` has a non-null Activity.
  void _scheduleAndroidNotificationPermissionAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _requestAndroidNotificationBannerPermission();
    });
  }

  Future<void> _requestAndroidNotificationBannerPermission() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Explicit Android 13+ runtime permission (shows system dialog when needed).
    final fromPlugin = await android?.requestNotificationsPermission();
    if (kDebugMode) {
      debugPrint('[FCM] Android POST_NOTIFICATIONS (local_notifications): $fromPlugin');
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('[FCM] Android permission (firebase_messaging): ${settings.authorizationStatus}');
    }

    // Request battery optimization exemption so FCM works when app is closed.
    await _requestBatteryOptimizationExemption();
  }

  static const _batteryChannel = MethodChannel('com.washslender.app/battery');

  /// Asks the user to exempt this app from battery optimization.
  /// Without this, many Android OEMs (Xiaomi, Huawei, Samsung, Oppo, etc.)
  /// kill FCM delivery when the app is closed, so no notifications arrive.
  Future<void> _requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      final isIgnoring =
          await _batteryChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
      if (!isIgnoring) {
        if (kDebugMode) debugPrint('[FCM] Requesting battery optimization exemption');
        await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      } else {
        if (kDebugMode) debugPrint('[FCM] Already exempt from battery optimization');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Battery opt request failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Local notifications setup (foreground display on Android/iOS)
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(_androidNotificationIcon);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create the Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // iOS foreground presentation options (handled by firebase_messaging too).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// When the user opens the app from a **local** tray notification (e.g. one
  /// shown by [firebaseMessagingBackgroundHandler] while the app was killed),
  /// [onDidReceiveNotificationResponse] does not run — we must read launch details.
  Future<void> _handleLocalNotificationColdStart() async {
    try {
      final details =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return;
      final response = details.notificationResponse;
      final payload = response?.payload;
      if (payload == null || payload.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (rootNavigatorKey.currentState == null) return;
        if (response == null) return;
        _onLocalNotificationTap(response);
      });
    } catch (e, st) {
      developer.log(
        'getNotificationAppLaunchDetails failed: $e',
        name: 'FCM.launch',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FCM Token management
  // ---------------------------------------------------------------------------

  /// On iOS, the APNS token may not be ready immediately. This waits up to
  /// ~10 seconds for it, polling every second.
  Future<String?> _waitForApnsToken() async {
    if (!Platform.isIOS) return 'not-ios';
    for (int i = 0; i < 10; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) {
        if (kDebugMode) debugPrint('[FCM] APNS token ready after ${i}s');
        return apns;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    if (kDebugMode) debugPrint('[FCM] APNS token never arrived (simulator?)');
    return null;
  }

  /// Returns the current FCM token, or null if unavailable.
  Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
        if (apns == null) return null;
      }
      final token = await _messaging.getToken();
      if (kDebugMode) debugPrint('[FCM] Token: $token');
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  /// Listens for token refreshes (e.g. after APNS arrives late, or token
  /// rotated by Firebase) and automatically re-registers with the backend.
  void _listenTokenRefresh() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) debugPrint('[FCM] Token refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
  }

  /// Gets the FCM token and sends it to the backend via the dedicated
  /// `/device-tokens` endpoint. Called after login, register, and on app
  /// reopen for returning users (splash screen).
  Future<void> registerToken() async {
    final authToken = StorageService.getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      if (kDebugMode) debugPrint('[FCM] registerToken: no auth token, skipping');
      return;
    }

    final fcmToken = await getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      if (kDebugMode) debugPrint('[FCM] registerToken: no FCM token, skipping');
      return;
    }

    await _sendTokenToBackend(fcmToken);
  }

  /// Posts the FCM token to `/api/v1/device-tokens`.
  Future<void> _sendTokenToBackend(String fcmToken) async {
    final authToken = StorageService.getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      if (kDebugMode) debugPrint('[FCM] _sendToken: no auth token');
      return;
    }

    final deviceType = Platform.isIOS ? 'ios' : 'android';
    final url = ApiEndpoints.deviceToken;
    if (kDebugMode) {
      debugPrint('[FCM] ====================================');
      debugPrint('[FCM] POST $url');
      debugPrint('[FCM] token: ${fcmToken.substring(0, 20)}...');
      debugPrint('[FCM] device_type: $deviceType');
      debugPrint('[FCM] Bearer: ${authToken.substring(0, 20)}...');
      debugPrint('[FCM] ====================================');
    }

    try {
      final response = await ApiClient().post(
        url,
        data: {
          'token': fcmToken,
          'device_type': deviceType,
        },
      );
      await StorageService.saveFcmToken(fcmToken);
      if (kDebugMode) {
        debugPrint('[FCM] ✅ Token registered! Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] ❌ registerToken FAILED: $e');
      }
    }
  }

  /// Clears the locally stored FCM token on logout.
  Future<void> unregisterToken() async {
    await StorageService.removeFcmToken();
    if (kDebugMode) debugPrint('[FCM] Token cleared locally');
  }

  /// Reverb `search-request.created` — **always** post a tray notification.
  ///
  /// Android often delivers the WebSocket event only after the isolate unpauses; then
  /// [AppLifecycleState] is already [resumed], so a "background-only" check never ran.
  /// Foreground: [InAppNotificationService.showVendorNewSearchRequest] cancels this id and
  /// shows the overlay instead.
  Future<void> showVendorSearchReverbTray(Map<String, dynamic> data) async {
    final map = vendorSearchRequestNavigationMap(data);
    final rawTitle = map['title']?.toString().trim() ?? '';
    final title = rawTitle.isNotEmpty ? rawTitle : 'طلب بحث جديد';
    var body = map['body']?.toString().trim() ?? '';
    if (body.isEmpty) {
      body = 'افتح التطبيق لعرض الطلب';
    }

    final notificationId = vendorSearchLocalNotificationId(map);
    final lifecycle = WidgetsBinding.instance.lifecycleState;

    developer.log(
      'Reverb tray id=$notificationId lifecycle=$lifecycle',
      name: 'FCM.reverb',
    );

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            icon: _androidNotificationIcon,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(map),
      );
    } catch (e, st) {
      developer.log(
        'show failed: $e',
        name: 'FCM.reverb',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Reverb `new-message.sent` → show a tray so the recipient sees it when the
  /// app is open but not on the chat screen. Caller is responsible for skipping
  /// when [RealtimeService.activeChatId] matches the incoming chat id.
  Future<void> showChatMessageReverbTray(Map<String, dynamic> data) async {
    final chatId = parseChatIdFromMap(data);

    String? senderName;
    String? preview;

    final notif = data['notification'];
    if (notif is Map) {
      senderName ??= notif['title']?.toString().trim();
      preview ??= notif['body']?.toString().trim();
    }
    final msg = data['message'];
    if (msg is Map) {
      preview ??= msg['body']?.toString().trim();
      final sender = msg['sender'];
      if (sender is Map) {
        senderName ??= sender['name']?.toString().trim();
      }
    }
    senderName ??= data['sender_name']?.toString().trim();
    preview ??= data['body']?.toString().trim();

    final title = (senderName != null && senderName.isNotEmpty)
        ? senderName
        : 'رسالة جديدة';
    final body = (preview != null && preview.isNotEmpty)
        ? preview
        : 'افتح التطبيق للمحادثة';

    final notificationId = (chatId != null && chatId > 0)
        ? 20_000_000 + chatId
        : data.hashCode.abs() % 0x7fffffff;

    final payload = <String, dynamic>{
      'type': 'new-message',
      if (chatId != null) 'chat_id': chatId,
      'chat_name': senderName ?? '',
      'sender_name': senderName ?? '',
    };

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            icon: _androidNotificationIcon,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(payload),
      );
    } catch (e, st) {
      developer.log(
        'chat tray failed: $e',
        name: 'FCM.reverb',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cancelVendorSearchLocalNotification(int id) async {
    if (id <= 0) return;
    try {
      await _localNotifications.cancel(id);
    } catch (_) {}
  }

  /// One-time after login / cold start: record current newest API id — no tray spam for backlog.
  Future<void> establishNotificationSyncBaseline() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;
    if (StorageService.isNotificationApiBaselineDone()) return;

    try {
      final list = await _fetchNotificationsListPage1();
      var maxId = 0;
      for (final row in list) {
        final id = _parseNotificationRowId(row['id']);
        if (id != null && id > maxId) maxId = id;
      }
      await StorageService.saveLastNotifiedNotificationApiId(maxId);
      await StorageService.setNotificationApiBaselineDone();
      developer.log('baseline maxId=$maxId count=${list.length}', name: 'FCM.apiSync');
    } catch (e, st) {
      developer.log(
        'baseline failed: $e',
        name: 'FCM.apiSync',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// After app resume or dashboard open (throttled). Applies to both vendor and customer.
  Future<void> syncMissedNotificationsFromApiOnResume() {
    return _syncMissedNotificationsFromApi(bypassThrottle: false);
  }

  /// When Reverb disconnects — same REST pull, **no** 2s throttle so background drops still notify.
  Future<void> syncMissedNotificationsFromApiOnDisconnect() {
    return _syncMissedNotificationsFromApi(bypassThrottle: true);
  }

  Future<void> _syncMissedNotificationsFromApi({
    required bool bypassThrottle,
  }) async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    final now = DateTime.now();
    if (!bypassThrottle) {
      if (_lastApiNotificationSync != null &&
          now.difference(_lastApiNotificationSync!) <
              const Duration(seconds: 2)) {
        return;
      }
    }
    _lastApiNotificationSync = now;

    if (!StorageService.isNotificationApiBaselineDone()) {
      await establishNotificationSyncBaseline();
    }

    final cutoff = StorageService.getLastNotifiedNotificationApiId();

    try {
      final list = await _fetchNotificationsListPage1();
      var newWatermark = cutoff;

      for (final row in list) {
        final id = _parseNotificationRowId(row['id']);
        if (id == null) continue;
        if (id <= cutoff) break;

        newWatermark = newWatermark > id ? newWatermark : id;

        if (!_isUnreadNotificationRow(row)) continue;
        final type = row['type']?.toString() ?? '';

        final payload = Map<String, dynamic>.from(row);
        String defaultTitle;
        switch (type) {
          case 'search_request':
            payload['type'] = 'search_request';
            final srId = _searchRequestIdFromApiNotificationRow(row);
            if (srId != null) payload['search_request_id'] = srId;
            defaultTitle = 'طلب بحث جديد';
          case 'new_message':
          case 'new-message':
          case 'chat':
            payload['type'] = 'new-message';
            final chatId = _scalarIdFromRow(row, const ['chat_id']);
            if (chatId != null) payload['chat_id'] = chatId;
            defaultTitle = 'رسالة جديدة';
          case 'order':
          case 'order_accepted':
            payload['type'] = type;
            final orderId = _scalarIdFromRow(row, const ['order_id']);
            if (orderId != null) payload['order_id'] = orderId;
            defaultTitle = 'تحديث الطلب';
          default:
            continue;
        }

        final rawTitle = row['title']?.toString().trim() ?? '';
        final title = rawTitle.isNotEmpty ? rawTitle : defaultTitle;
        var body = row['body']?.toString().trim() ?? '';
        if (body.isEmpty) body = 'افتح التطبيق للمزيد';

        final trayId = 10_000_000 + id;
        await _localNotifications.show(
          trayId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.max,
              priority: Priority.max,
              icon: _androidNotificationIcon,
              playSound: true,
              enableVibration: true,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(payload),
        );
        developer.log(
          'API tray rowId=$id type=$type '
          'reason=${bypassThrottle ? "disconnect" : "resume"}',
          name: 'FCM.apiSync',
        );
      }

      if (newWatermark > cutoff) {
        await StorageService.saveLastNotifiedNotificationApiId(newWatermark);
      }
    } catch (e, st) {
      developer.log(
        'sync failed: $e',
        name: 'FCM.apiSync',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotificationsListPage1() async {
    final res = await ApiClient().get(
      ApiEndpoints.notifications,
      queryParameters: {'page': 1},
    );
    if (res.statusCode != 200) return [];
    final data = res.data;
    if (data is! Map) return [];
    final raw = data['data'];
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  int? _parseNotificationRowId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  bool _isUnreadNotificationRow(Map<String, dynamic> row) {
    final v = row['is_read'];
    if (v == false) return true;
    if (v == true) return false;
    if (v == null) return true;
    if (v == 0) return true;
    return false;
  }

  int? _scalarIdFromRow(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null) {
        if (v is int) return v;
        final p = int.tryParse(v.toString());
        if (p != null) return p;
      }
    }
    final meta = row['meta'];
    if (meta is Map) {
      for (final k in keys) {
        final v = meta[k];
        if (v != null) {
          if (v is int) return v;
          final p = int.tryParse(v.toString());
          if (p != null) return p;
        }
      }
    }
    return null;
  }

  int? _searchRequestIdFromApiNotificationRow(Map<String, dynamic> row) {
    final direct = row['search_request_id'];
    if (direct != null) {
      if (direct is int) return direct;
      return int.tryParse(direct.toString());
    }
    final meta = row['meta'];
    if (meta is Map) {
      final v = meta['search_request_id'];
      if (v != null) {
        if (v is int) return v;
        return int.tryParse(v.toString());
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Foreground messages
  // ---------------------------------------------------------------------------

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM] Foreground message: ${message.messageId}');
        debugPrint('[FCM] notification: ${message.notification?.title}');
        debugPrint('[FCM] data: ${message.data}');
      }
      _showLocalNotification(message);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // iOS auto-presents the alert in foreground when a notification block is
    // present (see setForegroundNotificationPresentationOptions). Skip local
    // show to avoid duplicates. Android never auto-displays in foreground, so
    // we always show a local tray there.
    if (Platform.isIOS && notification != null) return;

    final title = notification?.title ?? data['title'] ?? AppConstants.appName;
    final body = notification?.body ?? data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: _androidNotificationIcon,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification taps (all states)
  // ---------------------------------------------------------------------------

  void _listenNotificationTaps() {
    // Tap on notification while app is in background (but not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was launched from a terminated state by tapping a notification.
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        // Small delay so navigation context is ready.
        Future.delayed(
          const Duration(milliseconds: 800),
          () => _handleNotificationTap(message),
        );
      }
    });
  }

  /// Tap from a local notification (foreground).
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (_) {}
  }

  /// Tap from FCM system notification (background/terminated).
  void _handleNotificationTap(RemoteMessage message) {
    final data = <String, dynamic>{...message.data};
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    _navigateFromPayload(data);
  }

  // ---------------------------------------------------------------------------
  // Navigation routing based on notification payload
  // ---------------------------------------------------------------------------

  void _navigateFromPayload(Map<String, dynamic> data) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type']?.toString() ?? '';
    if (kDebugMode) debugPrint('[FCM] Navigate: type=$type data=$data');

    if (isAdNotificationPayloadType(type)) {
      final adId = parseAdIdFromMap(data);
      if (adId != null) {
        navigator.pushNamed(
          AppRoutes.adDetails,
          arguments: {'adId': adId.toString()},
        );
        return;
      }
      navigator.pushNamed(AppRoutes.notifications);
      return;
    }

    switch (type) {
      case 'new-message':
      case 'new_message':
      case 'chat':
        final chatId = parseChatIdFromMap(data);
        if (chatId != null) {
          navigator.pushNamed(
            AppRoutes.chatRoom,
            arguments: {
              'chatId': chatId.toString(),
              'chatName': data['sender_name'] ?? data['chat_name'] ?? '',
            },
          );
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }

      case 'new_request':
      case 'search-request':
      case 'search_request':
      case 'search_request_created':
      case 'search-request.created':
        final srId = data['search_request_id'] ??
            data['request_id'] ??
            data['searchRequestId'];
        navigator.pushNamed(
          AppRoutes.vendorIncomingRequests,
          arguments: {'searchRequestId': srId},
        );

      case 'search_approved':
      case 'search-request.accepted':
      case 'search_request_accepted':
        navigator.pushNamed(AppRoutes.mySearchRequests);

      case 'order':
      case 'order_accepted':
        final orderId = data['order_id'] ?? data['orderId'];
        navigator.pushNamed(AppRoutes.orders, arguments: {'orderId': orderId});

      default:
        navigator.pushNamed(AppRoutes.notifications);
    }
  }
}
