/// Application Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'وش سلندر';
  static const String appVersion = '2.4.0';
  static const String appTagline = 'قطع غيار وخدمات في مكان واحد';

  // API Configuration
  static const String baseUrl = 'http://3.88.167.66';
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

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

