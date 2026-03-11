/// Application Routes
class AppRoutes {
  AppRoutes._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Home Routes
  static const String home = '/home';
  static const String myAds = '/my-ads';
  static const String createAd = '/create-ad';
  static const String createAdPhotos = '/create-ad-photos';
  static const String editAd = '/edit-ad';
  static const String searchResults = '/search-results';
  static const String adDetails = '/ad-details';
  static const String vendorProfile = '/vendor-profile';

  // Chat Routes
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';

  // Profile Routes
  static const String profile = '/profile';

  // Orders Routes
  static const String orders = '/orders';

  // Garage Routes
  static const String garage = '/garage';

  // Subscription Routes
  static const String subscriptionPlans = '/subscription-plans';
  static const String planDetails = '/plan-details';

  // Vendor Routes
  static const String vendorDashboard = '/vendor-dashboard';
  static const String vendorIncomingRequests = '/vendor-incoming-requests';

  // Notifications Routes
  static const String notifications = '/notifications';

  // Admin / Permissions (requires permissions.view)
  static const String permissions = '/permissions';
}

