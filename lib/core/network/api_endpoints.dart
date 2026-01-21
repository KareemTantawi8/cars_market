/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = '/api/v1';

  // Authentication
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // User
  static const String userProfile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/profile';

  // Vendor
  static const String vendors = '$baseUrl/vendors';
  static const String vendorProfile = '$baseUrl/vendors';
  static const String vendorDashboard = '$baseUrl/vendors/dashboard';

  // Chat
  static const String chats = '$baseUrl/chats';
  static const String chatMessages = '$baseUrl/chats';
  static const String sendMessage = '$baseUrl/chats/messages';

  // Subscription
  static const String subscriptions = '$baseUrl/subscriptions';
  static const String subscribe = '$baseUrl/subscriptions/subscribe';

  // Ratings
  static const String ratings = '$baseUrl/ratings';
  static const String createRating = '$baseUrl/ratings';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
}

