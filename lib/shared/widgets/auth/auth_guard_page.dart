import 'package:flutter/material.dart';
import '../../../core/auth/auth_guard.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/auth_session.dart';
import 'guest_feature_gate.dart';

/// Wraps a protected route: guests see a login prompt screen instead of the feature.
class AuthGuardPage extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final IconData icon;

  const AuthGuardPage({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.icon = Icons.lock_outline,
  });

  @override
  State<AuthGuardPage> createState() => _AuthGuardPageState();
}

class _AuthGuardPageState extends State<AuthGuardPage> {
  @override
  Widget build(BuildContext context) {
    if (AuthSession.isLoggedIn) {
      return widget.child;
    }

    return GuestFeatureGate(
      title: widget.title,
      description: widget.description,
      icon: widget.icon,
      onLogin: () => AuthGuard.navigateToLogin(context),
      onRegister: () {
        Navigator.pushNamed(context, AppRoutes.register);
      },
    );
  }
}
