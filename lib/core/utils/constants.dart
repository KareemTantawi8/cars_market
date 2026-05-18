/// Application Constants
///
/// Release builds should pass production values via `--dart-define`, for example:
/// `flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com/api/v1`
///
/// Optional defines: `STORAGE_BASE_URL`, `REVERB_APP_KEY`, `REVERB_USE_TLS` (true/false).
class AppConstants {
  AppConstants._();

  // App Info (keep [appVersion] in sync with `version:` in pubspec.yaml)
  static const String appName = 'وش سلندر';
  static const String appVersion = '1.0.0-alpha2';
  static const String appTagline = 'قطع غيار وخدمات في مكان واحد';

  /// Public support page (must match App Store Connect Support URL).
  static const String supportUrl = 'https://w4cylinder.tech/';

  // API Configuration — override per environment with dart-define
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://w4cylinder.tech/api/v1',
  );

  static const String _storageBaseUrlOverride = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: '',
  );

  /// Base URL for storage (e.g. ad images). Paths from API are relative (e.g. "ads/img.jpg").
  static String get storageBaseUrl {
    if (_storageBaseUrlOverride.isNotEmpty) {
      return _storageBaseUrlOverride;
    }
    return '$apiOrigin/storage';
  }
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  /// HTTP origin without `/api/v1` (e.g. broadcasting auth: `{apiOrigin}/broadcasting/auth`).
  static String get apiOrigin {
    final u = baseUrl.trim();
    const suffix = '/api/v1';
    if (u.endsWith(suffix)) {
      return u.substring(0, u.length - suffix.length);
    }
    return u;
  }

  static String get broadcastingAuthUrl => '$apiOrigin/api/broadcasting/auth';

  // Laravel Reverb — match server `.env` (`REVERB_APP_KEY`, `REVERB_PORT`, etc.)
  /// WebSocket host (defaults to API host).
  static String get reverbHost => Uri.parse(apiOrigin).host;
  static const int reverbPort = 8080;

  /// Public Reverb app key (same as server `REVERB_APP_KEY`); override per deployment if needed.
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'juc1rbrua6fd6qlcubm0',
  );

  static const String _reverbUseTlsEnv = String.fromEnvironment(
    'REVERB_USE_TLS',
    defaultValue: 'true',
  );

  static bool get reverbUseTls => _reverbUseTlsEnv.toLowerCase() == 'true';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String abilitiesKey = 'abilities'; // e.g. ['ads.update'] for admin
  static const String themeModeKey = 'theme_mode'; // 'light', 'dark', 'system'
  static const String fcmTokenKey = 'fcm_token';
  /// Max API `notifications.data[].id` already surfaced via local tray (vendor API sync).
  static const String lastNotifiedNotificationApiIdKey =
      'last_notified_notification_api_id';
  /// True after first GET /notifications baseline (vendor) so `id==0` is valid watermark.
  static const String notificationApiBaselineDoneKey =
      'notification_api_baseline_done';

  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeVendor = 'vendor';

  // Pagination
  static const int defaultPageSize = 20;

  // Chat
  static const int maxMessageLength = 1000;
  static const int chatRefreshInterval = 5000; // 5 seconds

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Subscription
  static const String subscriptionMonthly = 'monthly';
  static const String subscriptionAnnual = 'annual';

  // Localization
  static const String defaultLocale = 'ar_EG';
  static const String defaultLanguage = 'ar';

  // Error Messages (Arabic)
  static const String errorNetwork = 'لا يوجد اتصال بالإنترنت';
  static const String errorGeneric = 'حدث خطأ، يرجى المحاولة مرة أخرى';
  static const String errorUnauthorized = 'غير مصرح لك بالوصول';
  static const String errorNotFound = 'غير موجود';
  static const String errorServer = 'خطأ في الخادم، يرجى المحاولة لاحقاً';

  // Success Messages (Arabic)
  static const String successLogin = 'تم تسجيل الدخول بنجاح';
  static const String successRegister = 'تم إنشاء الحساب بنجاح';
  static const String successLogout = 'تم تسجيل الخروج بنجاح';
  static const String successMessageSent = 'تم إرسال الرسالة بنجاح';
}

