import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Application Theme Configuration
class AppTheme {
  AppTheme._();

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary:          AppColors.primaryColor,
      secondary:        AppColors.primaryDark,
      surface:          AppColors.surfaceColor,
      background:       AppColors.backgroundColor,
      error:            AppColors.error,
      onPrimary:        Colors.white,
      onSecondary:      Colors.white,
      onSurface:        AppColors.textPrimary,
      onBackground:     AppColors.textPrimary,
      onError:          Colors.white,
    ),

    scaffoldBackgroundColor: AppColors.backgroundColor,

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: AppTextStyles.headingMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.inputLabel.copyWith(color: AppColors.textSecondary),
      errorStyle: AppTextStyles.error,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerColor, thickness: 1, space: 1,
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

    // Text
    textTheme: TextTheme(
      displayLarge:   AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimary),
      displayMedium:  AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
      displaySmall:   AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
      headlineLarge:  AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimary),
      headlineMedium: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
      headlineSmall:  AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
      titleLarge:     AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
      titleMedium:    AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
      titleSmall:     AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      bodyMedium:     AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      bodySmall:      AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      labelLarge:     AppTextStyles.button.copyWith(color: AppColors.textPrimary),
      labelMedium:    AppTextStyles.buttonSmall.copyWith(color: AppColors.textPrimary),
      labelSmall:     AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.surfaceColor,
      selectedItemColor:   AppColors.primaryColor,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 8,
    ),

    // Snack Bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardColor,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // ── Light Theme ───────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary:      AppColors.lightPrimary,
      secondary:    AppColors.lightPrimaryDark,
      surface:      AppColors.lightSurface,
      background:   AppColors.lightBackground,
      error:        AppColors.error,
      onPrimary:    Colors.white,
      onSecondary:  Colors.white,
      onSurface:    AppColors.lightTextPrimary,
      onBackground: AppColors.lightTextPrimary,
      onError:      Colors.white,
    ),

    scaffoldBackgroundColor: AppColors.lightBackground,

    // Cards — white with a soft shadow for depth
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 2,
      shadowColor: const Color(0x1A1565C0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // AppBar — white, dark text/icons
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: AppTextStyles.headingMedium.copyWith(
        color: AppColors.lightTextPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.lightInputBorderFocused, width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle:  AppTextStyles.inputHint.copyWith(color: AppColors.lightTextHint),
      labelStyle: AppTextStyles.inputLabel.copyWith(color: AppColors.lightTextSecondary),
      errorStyle: AppTextStyles.error,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightButtonPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightPrimary,
        side: const BorderSide(color: AppColors.lightPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider, thickness: 1, space: 1,
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.lightTextPrimary, size: 24),

    // Text
    textTheme: TextTheme(
      displayLarge:   AppTextStyles.headingLarge.copyWith(color: AppColors.lightTextPrimary),
      displayMedium:  AppTextStyles.headingMedium.copyWith(color: AppColors.lightTextPrimary),
      displaySmall:   AppTextStyles.headingSmall.copyWith(color: AppColors.lightTextPrimary),
      headlineLarge:  AppTextStyles.headingLarge.copyWith(color: AppColors.lightTextPrimary),
      headlineMedium: AppTextStyles.headingMedium.copyWith(color: AppColors.lightTextPrimary),
      headlineSmall:  AppTextStyles.headingSmall.copyWith(color: AppColors.lightTextPrimary),
      titleLarge:     AppTextStyles.headingMedium.copyWith(color: AppColors.lightTextPrimary),
      titleMedium:    AppTextStyles.headingSmall.copyWith(color: AppColors.lightTextPrimary),
      titleSmall:     AppTextStyles.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
      bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
      bodyMedium:     AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
      bodySmall:      AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      labelLarge:     AppTextStyles.button.copyWith(color: AppColors.lightTextPrimary),
      labelMedium:    AppTextStyles.buttonSmall.copyWith(color: AppColors.lightTextPrimary),
      labelSmall:     AppTextStyles.caption.copyWith(color: AppColors.lightTextSecondary),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.lightSurface,
      selectedItemColor:   AppColors.lightPrimary,
      unselectedItemColor: AppColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: AppTextStyles.headingSmall.copyWith(color: AppColors.lightTextPrimary),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 8,
    ),

    // Snack Bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightTextPrimary,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.lightSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
