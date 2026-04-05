import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../services/realtime_service.dart';
import '../services/push_notification_service.dart';
import '../controllers/user_type_controller.dart';

class NavigationService {
  NavigationService._();

  static String? getCurrentUserType() {
    return UserTypeController().currentUserType ??
        StorageService.getUserType();
  }

  static void navigateToHome(BuildContext context) {
    final userType = getCurrentUserType();

    if (userType == AppConstants.userTypeVendor) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.vendorDashboard,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    }
  }

  static void navigateAfterLogin(BuildContext context, String userType) {
    navigateToHome(context);
  }

  static void navigateAfterRegister(BuildContext context, String userType) {
    if (userType == AppConstants.userTypeVendor) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.subscriptionPlans,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    }
  }

  static void navigateAfterSubscription(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.vendorDashboard,
      (_) => false,
    );
  }

  static void navigateToLogout(BuildContext context) {
    RealtimeService.instance.stop();
    PushNotificationService.instance.unregisterToken();
    StorageService.clearAll();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }
}
