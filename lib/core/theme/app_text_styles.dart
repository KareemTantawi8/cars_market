import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application Text Styles
/// All text styles used throughout the app
class AppTextStyles {
  AppTextStyles._();

  // Heading Styles
  static TextStyle get headingLarge => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headingMedium => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingSmall => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Body Styles
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Caption Styles
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  static TextStyle get captionSmall => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
        height: 1.2,
      );

  // Button Styles
  static TextStyle get button => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // Input Styles
  static TextStyle get input => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get inputHint => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
        height: 1.5,
      );

  static TextStyle get inputLabel => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  // Special Styles
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

  // Chat Styles
  static TextStyle get chatMessage => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get chatTimestamp => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
        height: 1.2,
      );
}
