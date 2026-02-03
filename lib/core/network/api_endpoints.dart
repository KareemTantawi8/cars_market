/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (relative paths, base URL is in AppConstants)
  // API Base: http://3.88.167.66/api/v1/
  static const String basePath = '/api/v1';

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
  // GET /api/v1/chats/:id/messages
  static const String chatMessages = '$basePath/chats';
  // POST /api/v1/chats/messages
  static const String sendMessage = '$basePath/chats/messages';

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

  // Search
  // POST /api/v1/search-requests - Search for suppliers
  static const String searchRequests = '$basePath/search-requests';
  // GET /api/v1/response
  static const String searchResponse = '$basePath/response';

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

