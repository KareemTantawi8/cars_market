import 'package:flutter/material.dart';
import '../navigation/root_navigator.dart';
import '../routes/app_routes.dart';
import '../utils/auth_session.dart';
import 'route_access_policy.dart';
import '../../shared/widgets/auth/login_required_dialog.dart';

/// Centralized auth checks for navigation and feature gates.
class AuthGuard {
  AuthGuard._();

  static bool canAccessRoute(String? routeName) {
    if (routeName == null) return false;
    if (RouteAccessPolicy.isPublic(routeName)) return true;
    if (RouteAccessPolicy.isProtected(routeName)) {
      return AuthSession.isLoggedIn;
    }
    // Unknown routes default to public so we do not block deep links accidentally.
    return true;
  }

  /// Shows a friendly prompt; navigates to login only if the user chooses to.
  ///
  /// Returns `true` when the user is authenticated after the flow.
  static Future<bool> requireAuth(
    BuildContext context, {
    String? title,
    String? message,
    String? loginButtonLabel,
  }) async {
    if (AuthSession.isLoggedIn) return true;
    if (!context.mounted) return false;

    final shouldLogin = await LoginRequiredDialog.show(
      context,
      title: title,
      message: message,
      loginButtonLabel: loginButtonLabel,
    );
    if (shouldLogin != true) return false;

    return openLoginScreen(returnToCaller: false);
  }

  /// Opens login via root navigator (safe from dialogs, tabs, and nested routes).
  static Future<bool> openLoginScreen({bool returnToCaller = false}) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return false;

    if (returnToCaller) {
      final result = await navigator.pushNamed<bool>(
        AppRoutes.login,
        arguments: const {'returnToCaller': true},
      );
      return result == true || AuthSession.isLoggedIn;
    }

    await navigator.pushNamed(AppRoutes.login);
    return AuthSession.isLoggedIn;
  }

  /// Pushes the login screen using the root navigator (works from nested tabs).
  static Future<bool> navigateToLogin(
    BuildContext context, {
    bool returnToCaller = false,
  }) async {
    if (rootNavigatorKey.currentState != null) {
      return openLoginScreen(returnToCaller: returnToCaller);
    }
    if (!context.mounted) return false;
    if (returnToCaller) {
      final result = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.login,
        arguments: const {'returnToCaller': true},
      );
      return result == true || AuthSession.isLoggedIn;
    }
    await Navigator.pushNamed(context, AppRoutes.login);
    return AuthSession.isLoggedIn;
  }

  /// Use before `Navigator.pushNamed` to protected destinations from public screens.
  static Future<void> pushProtected(
    BuildContext context,
    String routeName, {
    Object? arguments,
    String? title,
    String? message,
  }) async {
    if (canAccessRoute(routeName)) {
      if (!context.mounted) return;
      await Navigator.pushNamed(context, routeName, arguments: arguments);
      return;
    }

    final authenticated = await requireAuth(
      context,
      title: title,
      message: message,
    );
    if (!authenticated) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null) {
      await navigator.pushNamed(routeName, arguments: arguments);
    } else if (context.mounted) {
      await Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  }
}
