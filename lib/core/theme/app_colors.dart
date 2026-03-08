import 'package:flutter/material.dart';

/// Application Color Palette
class AppColors {
  AppColors._();

  // ── Dark theme (original) ─────────────────────────────────────────────────

  // Primary
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color primaryDark  = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Backgrounds
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor    = Color(0xFF1E1E1E);
  static const Color cardColor       = Color(0xFF2A2A2A);
  static const Color vendorProfileCard = Color(0xFF1B2032); // Dark blue for vendor profile card

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint      = Color(0xFF757575);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info    = Color(0xFF2196F3);

  // Online/Offline
  static const Color online  = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF757575);

  // Rating & Accent
  static const Color ratingStar  = Color(0xFFFFD700);
  static const Color accentColor = Color(0xFFFFD700);

  // Borders & Dividers
  static const Color borderColor  = Color(0xFF3A3A3A);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Input Fields
  static const Color inputBackground    = Color(0xFF2A2A2A);
  static const Color inputBorder        = Color(0xFF3A3A3A);
  static const Color inputBorderFocused = primaryColor;

  // Buttons
  static const Color buttonPrimary   = primaryColor;
  static const Color buttonSecondary = surfaceColor;
  static const Color buttonDisabled  = Color(0xFF424242);

  // Chat
  static const Color chatBubbleUser        = primaryColor;
  static const Color chatBubbleVendor      = cardColor;
  static const Color chatBubbleTextUser    = textPrimary;
  static const Color chatBubbleTextVendor  = textPrimary;

  // Badge / Notification
  static const Color badgeColor       = primaryColor;
  static const Color notificationDot  = error;

  // ── Light theme – modern, consistent ─────────────────────────────────────
  //
  //  Same blue primary as dark for brand consistency.
  //  A subtle blue-tinted white for backgrounds keeps it fresh.

  static const Color lightPrimary      = Color(0xFF1E88E5);
  static const Color lightPrimaryDark  = Color(0xFF1565C0);
  static const Color lightPrimaryLight = Color(0xFF42A5F5);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF4F6FB); // subtle blue-tint
  static const Color lightSurface    = Color(0xFFFFFFFF); // pure white
  static const Color lightCard       = Color(0xFFFFFFFF); // pure white cards

  // Text
  static const Color lightTextPrimary   = Color(0xFF12172A); // rich near-black
  static const Color lightTextSecondary = Color(0xFF5A6482); // muted slate
  static const Color lightTextHint      = Color(0xFF9BA5C0); // soft gray-blue

  // Borders & Dividers
  static const Color lightBorder  = Color(0xFFDDE3F0);
  static const Color lightDivider = Color(0xFFEBF0FA);

  // Input Fields
  static const Color lightInputBackground    = Color(0xFFEEF1F9);
  static const Color lightInputBorder        = Color(0xFFD6DCF0);
  static const Color lightInputBorderFocused = lightPrimary;

  // Buttons
  static const Color lightButtonPrimary   = lightPrimary;
  static const Color lightButtonSecondary = Color(0xFFEEF1F9);
  static const Color lightButtonDisabled  = Color(0xFFC8CFE4);

  // Chat (light)
  static const Color lightChatBubbleVendor = Color(0xFFF0F4FF);
}
