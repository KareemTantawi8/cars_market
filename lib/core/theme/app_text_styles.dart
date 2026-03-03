import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application Text Styles
///
/// Colors are intentionally omitted from most styles so they inherit the
/// correct value from the active theme's [TextTheme] / [DefaultTextStyle].
/// Only semantic-status styles (error, success, link) keep explicit colors.
class AppTextStyles {
  AppTextStyles._();

  // ── Heading ───────────────────────────────────────────────────────────────

  static TextStyle get headingLarge => const TextStyle(
    fontSize: 32, fontWeight: FontWeight.bold, height: 1.2,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontSize: 24, fontWeight: FontWeight.bold, height: 1.3,
  );

  static TextStyle get headingSmall => const TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
  );

  // ── Body ──────────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.normal, height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal, height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.normal, height: 1.4,
  );

  // ── Caption ───────────────────────────────────────────────────────────────

  static TextStyle get caption => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.normal, height: 1.3,
  );

  static TextStyle get captionSmall => const TextStyle(
    fontSize: 10, fontWeight: FontWeight.normal, height: 1.2,
  );

  // ── Button ────────────────────────────────────────────────────────────────

  static TextStyle get button => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.2,
  );

  static TextStyle get buttonSmall => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.2,
  );

  // ── Input ─────────────────────────────────────────────────────────────────

  static TextStyle get input => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal, height: 1.5,
  );

  /// Hint text style – color applied per-theme in inputDecorationTheme.
  static TextStyle get inputHint => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal, height: 1.5,
  );

  /// Label text style – color applied per-theme in inputDecorationTheme.
  static TextStyle get inputLabel => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, height: 1.3,
  );

  // ── Semantic (keep explicit colors) ──────────────────────────────────────

  static TextStyle get link => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    decoration: TextDecoration.underline,
    height: 1.3,
  );

  static TextStyle get error => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.3,
  );

  static TextStyle get success => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.3,
  );

  // ── Chat ──────────────────────────────────────────────────────────────────

  static TextStyle get chatMessage => const TextStyle(
    fontSize: 15, fontWeight: FontWeight.normal, height: 1.4,
  );

  static TextStyle get chatTimestamp => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.normal, height: 1.2,
  );
}
