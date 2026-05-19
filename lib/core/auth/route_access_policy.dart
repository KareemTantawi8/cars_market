import '../routes/app_routes.dart';

/// Defines which routes are public vs require an authenticated session.
///
/// Public routes must remain usable without login per App Store guideline 5.1.1(v).
class RouteAccessPolicy {
  RouteAccessPolicy._();

  /// Routes reachable without authentication.
  static const Set<String> publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.home,
    AppRoutes.searchResults,
    AppRoutes.adDetails,
    AppRoutes.vendorProfile,
  };

  /// Routes that require a logged-in user.
  static const Set<String> protectedRoutes = {
    AppRoutes.myAds,
    AppRoutes.createAd,
    AppRoutes.createAdPhotos,
    AppRoutes.editAd,
    AppRoutes.chatList,
    AppRoutes.chatRoom,
    AppRoutes.profile,
    AppRoutes.orders,
    AppRoutes.notifications,
    AppRoutes.mySearchRequests,
    AppRoutes.subscriptionPlans,
    AppRoutes.planDetails,
    AppRoutes.vendorDashboard,
    AppRoutes.vendorIncomingRequests,
    AppRoutes.vendorSupportedBrands,
    AppRoutes.vendorLocationEdit,
    AppRoutes.permissions,
    AppRoutes.garage,
  };

  static bool isPublic(String? routeName) {
    if (routeName == null || routeName.isEmpty) return false;
    return publicRoutes.contains(routeName);
  }

  static bool isProtected(String? routeName) {
    if (routeName == null || routeName.isEmpty) return false;
    return protectedRoutes.contains(routeName);
  }
}
