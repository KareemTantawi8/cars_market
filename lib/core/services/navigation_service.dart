import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../controllers/user_type_controller.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'session_service.dart';

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

  static Future<void> navigateToLogout(BuildContext context) async {
    try {
      await AuthRepository().logout();
    } catch (_) {}
    await SessionService.clearLocalSession();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }
}
