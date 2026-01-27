/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (relative paths, base URL is in AppConstants)
  static const String basePath = '/api/v1';

  // Authentication
  static const String login = '$basePath/auth/login';
  static const String register = '$basePath/auth/register';
  static const String registerVendor = '$basePath/auth/register-vendor';
  static const String logout = '$basePath/auth/logout';
  static const String refreshToken = '$basePath/auth/refresh';

  // User
  static const String userProfile = '$basePath/user/profile';
  static const String updateProfile = '$basePath/user/profile';

  // Vendor
  static const String vendors = '$basePath/vendors';
  static const String vendorProfile = '$basePath/vendors';
  static const String vendorDashboard = '$basePath/vendors/dashboard';

  // Chat
  static const String chats = '$basePath/chats';
  static const String chatMessages = '$basePath/chats';
  static const String sendMessage = '$basePath/chats/messages';

  // Subscription
  static const String subscriptions = '$basePath/subscriptions';
  static const String subscribe = '$basePath/subscriptions/subscribe';

  // Ratings
  static const String ratings = '$basePath/ratings';
  static const String createRating = '$basePath/ratings';

  // Notifications
  static const String notifications = '$basePath/notifications';
}

