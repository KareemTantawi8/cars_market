import 'package:flutter/material.dart';

/// String Extensions
extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not empty
  bool get isNotNullOrEmpty => !isEmpty;

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Navigate to screen
  Future<T?> navigateTo<T>(Widget screen) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate and replace
  Future<T?> navigateToAndReplace<T>(Widget screen) {
    return Navigator.of(this).pushReplacement<T, void>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate and remove until
  Future<T?> navigateToAndRemoveUntil<T>(Widget screen) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Pop current screen
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
}

