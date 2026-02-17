/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

      // Base URL (relative paths, base URL is in AppConstants)
      // API Base: http://3.88.167.66/api/v1
  static const String basePath = '';

  // Authentication
  // POST /api/v1/auth/login
  static const String login = '$basePath/auth/login';
  // POST /api/v1/auth/register
  static const String register = '$basePath/auth/register';
  // POST /api/v1/auth/register-vendor
  static const String registerVendor = '$basePath/auth/register-vendor';
  // POST /api/v1/auth/logout
  static const String logout = '$basePath/auth/logout';
  // POST /api/v1/auth/refresh
  static const String refreshToken = '$basePath/auth/refresh';
  // GET /api/v1/auth/me - Get current user profile
  static const String currentUser = '$basePath/auth/me';

  // User
  // GET /api/v1/user/profile
  static const String userProfile = '$basePath/user/profile';
  // GET /api/v1/users/:id - Get user/vendor profile by ID
  static String userProfileById(int userId) => '$basePath/users/$userId';
  // PUT /api/v1/user/profile
  static const String updateProfile = '$basePath/user/profile';

  // Vendor
  // GET /api/v1/vendors
  static const String vendors = '$basePath/vendors';
  // GET /api/v1/vendors/:id
  static const String vendorProfile = '$basePath/vendors';
  // GET /api/v1/vendors/dashboard
  static const String vendorDashboard = '$basePath/vendors/dashboard';

  // Chat
  // GET /api/v1/chats
  static const String chats = '$basePath/chats';
  // GET /api/v1/chats/:id
  static String chatById(int chatId) => '$basePath/chats/$chatId';
  // GET /api/v1/chats/:id/messages
  static String chatMessages(int chatId) => '$basePath/chats/$chatId/messages';
  // POST /api/v1/chats/:id/messages
  static String sendMessage(int chatId) => '$basePath/chats/$chatId/messages';
  // POST /api/v1/chats/:id/read
  static String markChatAsRead(int chatId) => '$basePath/chats/$chatId/read';

  // Subscription / Plans
  // GET /api/v1/plans - Get all subscription plans
  static const String plans = '$basePath/plans';
  // GET /api/v1/plans/:id - Get plan details
  static String planDetails(int planId) => '$basePath/plans/$planId';
  // POST /api/v1/subscriptions/subscribe
  static const String subscribe = '$basePath/subscriptions/subscribe';

  // Ratings
  // GET /api/v1/ratings
  static const String ratings = '$basePath/ratings';
  // POST /api/v1/ratings
  static const String createRating = '$basePath/ratings';

  // Notifications
  // GET /api/v1/notifications
  static const String notifications = '$basePath/notifications';
  // POST /api/v1/notifications/:id/read
  static String markNotificationAsRead(int notificationId) => '$basePath/notifications/$notificationId/read';
  // POST /api/v1/notifications/read-all
  static const String markAllNotificationsRead = '$basePath/notifications/read-all';

  // Search Requests
  // POST /api/v1/search-requests - Create search request
  static const String searchRequests = '$basePath/search-requests';
  // GET /api/v1/search-requests/my - Get my search requests
  static const String mySearchRequests = '$basePath/search-requests/my';
  // GET /api/v1/search-requests/:id - Get search request details
  static String searchRequestById(int requestId) => '$basePath/search-requests/$requestId';
  // POST /api/v1/search-requests/:id/accept - Accept search request (vendor)
  static String acceptSearchRequest(int requestId) => '$basePath/search-requests/$requestId/accept';
  // POST /api/v1/search-requests/:id/reject - Reject search request (vendor)
  static String rejectSearchRequest(int requestId) => '$basePath/search-requests/$requestId/reject';

  // Vendor
  // GET /api/v1/vendor/search-requests - Get vendor incoming requests
  static const String vendorSearchRequests = '$basePath/vendor/search-requests';
  // POST /api/v1/vendor/online - Toggle vendor online status
  static const String vendorOnline = '$basePath/vendor/online';
  // GET /api/v1/vendors/:id - Get vendor profile
  static String vendorById(int vendorId) => '$basePath/vendors/$vendorId';

  // Auth - Additional endpoints
  // POST /api/v1/auth/forgot-password
  static const String forgotPassword = '$basePath/auth/forgot-password';
  // POST /api/v1/auth/verify-otp
  static const String verifyOtp = '$basePath/auth/verify-otp';
  // POST /api/v1/auth/reset-password
  static const String resetPassword = '$basePath/auth/reset-password';
  // GET /api/v1/auth/tokens - Get active tokens
  static const String authTokens = '$basePath/auth/tokens';
  // DELETE /api/v1/auth/tokens/:id - Revoke token
  static String revokeToken(int tokenId) => '$basePath/auth/tokens/$tokenId';
  // POST /api/v1/auth/logout-all - Logout from all devices
  static const String logoutAll = '$basePath/auth/logout-all';

  // Categories - Brands, Models, Years
  // GET /api/v1/categories/brands - Get all brands
  static const String brands = '$basePath/categories/brands';
  // GET /api/v1/categories/brands/:id/models - Get models for a brand
  static String brandModels(int brandId) => '$basePath/categories/brands/$brandId/models';
  // GET /api/v1/categories/models/:id/years - Get years for a model
  static String modelYears(int modelId) => '$basePath/categories/models/$modelId/years';

  // Governorates
  // GET /api/v1/governorates - Get all governorates
  static const String governorates = '$basePath/governorates';
}

