import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Warm Beige / Sage Green palette (matching reference)
  static const background = Color(0xFFF5F0E8); // Warm linen
  static const foreground = Color(0xFF3D3929); // Dark olive-brown

  static const card = Color(0xFFFDFAF3); // Off-white cream
  static const cardForeground = Color(0xFF5A5344); // Medium brown

  static const surface = card; // Alias for existing codebase
  static const green = Color(0xFF22C55E); // Keep for online dots

  static const primary = Color(0xFF6B8F71); // Sage green
  static const primaryForeground = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFEDE8DC); // Beige
  static const secondaryForeground = Color(0xFF8A7F6E); // Warm grey

  static const muted = Color(0xFFD5CDBE); // Light taupe
  static const mutedForeground = Color(0xFF9C9483); // Warm muted

  static const accent = Color(0xFF6B8F71); // Same sage green
  static const accentForeground = Color(0xFFFFFFFF);

  static const border = Color(0xFFD5CDBE); // Taupe border
  static const destruct = Color(0xFFC75050); // Warm red
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.dmSansTextTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: baseTextTheme,
    fontFamily: GoogleFonts.dmSans().fontFamily,
    colorScheme: const ColorScheme.light(
      surface: AppColors.card,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      onSurface: AppColors.foreground,
      outline: AppColors.border,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destruct,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.foreground),
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontWeight: FontWeight.bold,
      ),
      hintStyle: const TextStyle(color: AppColors.mutedForeground),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
