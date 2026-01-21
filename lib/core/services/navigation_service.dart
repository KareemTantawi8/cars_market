import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../controllers/user_type_controller.dart';

/// Navigation Service for handling user type-based routing
class NavigationService {
  NavigationService._();

  /// Get current user type from storage
  static String? getCurrentUserType() {
    return UserTypeController().currentUserType ?? StorageService.getUserType();
  }

  /// Navigate to appropriate home screen based on user type
  static void navigateToHome(BuildContext context) {
    final controller = UserTypeController();
    final userType = controller.currentUserType ?? getCurrentUserType();
    
    if (userType == AppConstants.userTypeVendor) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.vendorDashboard,
        (route) => false,
      );
    } else {
      // Default to customer home
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  /// Navigate after login based on user type
  static void navigateAfterLogin(BuildContext context, String userType) {
    if (userType == AppConstants.userTypeVendor) {
      // Check if vendor has subscription
      // For now, navigate to dashboard (subscription check will be done later)
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.vendorDashboard,
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  /// Navigate after registration based on user type
  static void navigateAfterRegister(BuildContext context, String userType) {
    if (userType == AppConstants.userTypeVendor) {
      // Navigate to subscription plans for vendors
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.subscriptionPlans,
        (route) => false,
      );
    } else {
      // Navigate to home for customers
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  /// Navigate after subscription purchase
  static void navigateAfterSubscription(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.vendorDashboard,
      (route) => false,
    );
  }

  /// Navigate to logout
  static void navigateToLogout(BuildContext context) {
    // Clear storage
    StorageService.clearAll();
    
    // Navigate to login
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

