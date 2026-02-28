import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F0F17);
  static const surface = Color(0xFF1A1A2E);
  static const card = Color(0xFF1E1E32);
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF8B5CF6);
  static const border = Color(0xFF2D2D44);
  static const foreground = Color(0xFFF1F5F9);
  static const mutedForeground = Color(0xFF64748B);
  static const secondary = Color(0xFF1E1E32);
  static const secondaryForeground = Color(0xFFCBD5E1);
  static const green = Color(0xFF22C55E);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      onSurface: AppColors.foreground,
      outline: AppColors.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.foreground),
      bodyMedium: TextStyle(color: AppColors.foreground),
      bodySmall: TextStyle(color: AppColors.mutedForeground),
      labelSmall: TextStyle(color: AppColors.mutedForeground),
    ),
  );
}
