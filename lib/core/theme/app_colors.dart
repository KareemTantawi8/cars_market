import 'package:flutter/material.dart';

/// Application Color Palette
/// Based on the dark theme design shown in the screens
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color primaryDark = Color(0xFF0D47A1); // Dark Blue
  static const Color primaryLight = Color(0xFF64B5F6);

  // Background Colors
  static const Color backgroundColor = Color(0xFF121212); // Dark Background
  static const Color surfaceColor = Color(0xFF1E1E1E); // Dark Surface
  static const Color cardColor = Color(0xFF2C2C2C); // Card Background

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB0B0B0); // Light Gray
  static const Color textHint = Color(0xFF808080); // Gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color error = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color info = Color(0xFF2196F3); // Blue

  // Online/Offline Status
  static const Color online = Color(0xFF4CAF50); // Green
  static const Color offline = Color(0xFF757575); // Gray

  // Rating
  static const Color ratingStar = Color(0xFFFFD700); // Gold

  // Borders
  static const Color borderColor = Color(0xFF3A3A3A);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Input Fields
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF3A3A3A);
  static const Color inputBorderFocused = primaryColor;

  // Button Colors
  static const Color buttonPrimary = primaryColor;
  static const Color buttonSecondary = surfaceColor;
  static const Color buttonDisabled = Color(0xFF424242);

  // Chat Colors
  static const Color chatBubbleUser = primaryColor; // User messages (bright blue)
  static const Color chatBubbleVendor = cardColor; // Vendor messages (dark blue)
  static const Color chatBubbleTextUser = textPrimary;
  static const Color chatBubbleTextVendor = textPrimary;

  // Badge/Notification
  static const Color badgeColor = primaryColor;
  static const Color notificationDot = error;
}

