/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (relative paths, base URL is in AppConstants)
  // API Base: http://187.124.35.51/api/v1
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
  // POST /api/v1/profile/images - Upload profile and/or background image (multipart: profile_image, background_image). 200/401/422
  static const String profileImages = '$basePath/profile/images';
  // PUT /api/v1/profile/location - Update vendor GPS location (latitude, longitude). Vendors only.
  static const String profileLocation = '$basePath/profile/location';

  // Vendor
  // GET /api/v1/vendors
  static const String vendors = '$basePath/vendors';
  // GET /api/v1/vendors/:id
  static const String vendorProfile = '$basePath/vendors';
  // GET /api/v1/vendors/dashboard
  static const String vendorDashboard = '$basePath/vendors/dashboard';

  // Chat / Messaging
  // GET /api/v1/chats - Inbox with chats, last message, unread count (response: { data: [] }), 401 Unauthenticated
  static const String chats = '$basePath/chats';
  // GET /api/v1/chats/:id - Single chat details with customer, vendor, linked search request (response: { data: {} }), 403 Forbidden
  static String chatById(int chatId) => '$basePath/chats/$chatId';
  // GET /api/v1/chats/:id/messages - Paginated messages (latest first, 50 per page). Response: { data: [], meta: {} }. 403 Forbidden
  static String chatMessages(int chatId) => '$basePath/chats/$chatId/messages';
  // POST /api/v1/chats/:id/messages - Send message (body: { body }). Response 201: { message, data }. 403 Forbidden, 422 Validation
  static String sendMessage(int chatId) => '$basePath/chats/$chatId/messages';
  // POST /api/v1/chats/:id/read - Mark all messages in chat as read (response: { message, read_count }), 403 Forbidden
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
  // GET /api/v1/notifications - List user notifications, paginated (query: page). Response: { data: [], meta: {} }. 401 Unauthenticated
  static const String notifications = '$basePath/notifications';
  // POST /api/v1/notifications/{notification}/read - Mark single as read. 200/403 Forbidden/404 Not found
  static String markNotificationAsRead(int notificationId) => '$basePath/notifications/$notificationId/read';
  // POST /api/v1/notifications/read-all - Mark all as read. 200/401 Unauthenticated
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
  // POST /api/v1/search-requests/:id/rate - Rate vendor (customer, request owner, once per request). Body: { rating, review }. 201/403/422
  static String rateSearchRequest(int requestId) => '$basePath/search-requests/$requestId/rate';

  // Orders
  // POST /api/v1/orders/:id/accept - Vendor accepts pending order (→ processing, chat created/linked). Response: { message, chat_id, data }. 400 Not pending / 403 Forbidden
  static String orderAccept(int orderId) => '$basePath/orders/$orderId/accept';

  // Vendor
  // GET /api/v1/vendor/search-requests - Get vendor incoming requests
  static const String vendorSearchRequests = '$basePath/vendor/search-requests';
  // POST /api/v1/vendor/online - Toggle vendor online status
  static const String vendorOnline = '$basePath/vendor/online';
  // GET /api/v1/vendors/:id - Get vendor profile (legacy)
  static String vendorById(int vendorId) => '$basePath/vendors/$vendorId';
  // GET /api/v1/vendors/:id/profile - Get vendor profile (governorate, categories, user details). 200/404
  static String vendorProfileById(int vendorId) => '$basePath/vendors/$vendorId/profile';
  // GET /api/v1/vendors/:id/reports - Get vendor performance report. 200/404
  static String vendorReportsById(int vendorId) => '$basePath/vendors/$vendorId/reports';

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

  // Categories - Brands, Models, Years (public)
  // GET /api/v1/categories/brands - List all brands (response: { data: [{ id, name, slug, meta }] })
  static const String brands = '$basePath/categories/brands';
  // GET /api/v1/categories/brands/:brandId/models - List models under a brand (response: { data: [], brand: {} })
  static String brandModels(int brandId) => '$basePath/categories/brands/$brandId/models';
  // GET /api/v1/categories/models/:modelId/years - List years under a model (response: { data: [], model: {}, brand: {} })
  static String modelYears(int modelId) => '$basePath/categories/models/$modelId/years';
  // GET /api/v1/categories/tree - Full category tree (response: { data: [] }), cached 1h
  static const String categoriesTree = '$basePath/categories/tree';
  // Admin categories (require categories.* permissions)
  // GET /api/v1/admin/categories - List all (query: type, parent_id, search, per_page)
  static const String adminCategories = '$basePath/admin/categories';
  // GET /api/v1/admin/categories/:id - Show category
  static String adminCategoryById(int id) => '$basePath/admin/categories/$id';
  // POST /api/v1/admin/categories - Create category
  static const String adminCategoryCreate = '$basePath/admin/categories';
  // PUT /api/v1/admin/categories/:id - Update category
  static String adminCategoryUpdate(int id) => '$basePath/admin/categories/$id';
  // DELETE /api/v1/admin/categories/:id - Delete category
  static String adminCategoryDelete(int id) => '$basePath/admin/categories/$id';

  // Governorates (public)
  // GET /api/v1/governorates - List all active governorates (response: { data: [{ id, name, slug }] }), public
  static const String governorates = '$basePath/governorates';
  // Admin governorates (require governorates.view / create / update / delete)
  // GET /api/v1/admin/governorates - List all paginated (query: search, per_page)
  static const String adminGovernorates = '$basePath/admin/governorates';
  // GET /api/v1/admin/governorates/:id
  static String adminGovernorateById(int id) => '$basePath/admin/governorates/$id';
  // POST /api/v1/admin/governorates
  static const String adminGovernorateCreate = '$basePath/admin/governorates';
  // PUT /api/v1/admin/governorates/:id
  static String adminGovernorateUpdate(int id) => '$basePath/admin/governorates/$id';
  // DELETE /api/v1/admin/governorates/:id
  static String adminGovernorateDelete(int id) => '$basePath/admin/governorates/$id';

  // Ads
  // GET /api/v1/ads - List published ads (query: brand_id, model_id, year_id, condition, search, page, per_page)
  static const String ads = '$basePath/ads';
  // GET /api/v1/ads/:id - View single ad
  static String adById(int id) => '$basePath/ads/$id';
  // POST /api/v1/ads - Create ad (multipart/form-data)
  static const String createAd = '$basePath/ads';
  // PUT /api/v1/ads/:id - Update ad (multipart/form-data)
  static String updateAd(int id) => '$basePath/ads/$id';
  // DELETE /api/v1/ads/:id - Delete ad
  static String deleteAd(int id) => '$basePath/ads/$id';
  // GET /api/v1/my-ads - List current user's ads (query: page, per_page)
  static const String myAds = '$basePath/my-ads';
  // Admin: POST /api/v1/admin/ads/:id/approve
  static String adminApproveAd(int id) => '$basePath/admin/ads/$id/approve';
  // Admin: POST /api/v1/admin/ads/:id/reject
  static String adminRejectAd(int id) => '$basePath/admin/ads/$id/reject';

  // Permissions (require permissions.view / create / update / delete)
  // GET /api/v1/permissions - List paginated (query: search, per_page). 401/403
  static const String permissions = '$basePath/permissions';
  // GET /api/v1/permissions/:id - Show permission. 404
  static String permissionById(int id) => '$basePath/permissions/$id';
  // POST /api/v1/permissions - Create (body: name, slug, description). 201/422
  static const String permissionCreate = '$basePath/permissions';
  // PUT /api/v1/permissions/:id - Update. 200/422
  static String permissionUpdate(int id) => '$basePath/permissions/$id';
  // DELETE /api/v1/permissions/:id - Delete. 200/422 if assigned to roles
  static String permissionDelete(int id) => '$basePath/permissions/$id';
}

