import 'package:flutter/material.dart';

/// CampusTwin color palette — single source of truth.
/// Import this file wherever you need colors, instead of redefining them.
class AppColors {
  AppColors._(); // no instances

  static const background = Color(0xFF0A0A12);
  static const card = Color(0xFF15151F);
  static const inputFill = Color(0xFF1C1C28);
  static const border = Color(0xFF2A2A38);
  static const purple = Color(0xFF6C5CE7);
  static const purpleLight = Color(0xFF8B7CF6);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9A9AAE);
  static const mockBanner = Color(0xFF2A1F0A);
  static const mockBannerText = Color(0xFFE5A93C);
}

/// App-wide ThemeData. Use AppTheme.darkTheme in MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        primary: AppColors.purple,
        surface: AppColors.card,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.inputFill,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}