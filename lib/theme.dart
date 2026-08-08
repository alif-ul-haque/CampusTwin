import 'package:flutter/material.dart';

/// CampusTwin color palette — single source of truth.
/// Import this file wherever you need colors, instead of redefining them.
class AppColors {
  AppColors._(); // no instances

  static const background = Color(0xFFF4F7FC);
  static const card = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFF7FAFF);
  static const border = Color(0xFFD6DFEA);
  static const purple = Color(0xFF4F46E5);
  static const purpleLight = Color(0xFF06B6D4);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF64748B);
}

/// Runtime palette that adapts to the active theme brightness.
/// Use these in widgets instead of hardcoding light/dark colors.
class AppPalette {
  AppPalette._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkCard = Color(0xFF111B2E);
  static const Color darkInputFill = Color(0xFF16233B);
  static const Color darkBorder = Color(0xFF25334D);
  static const Color darkTextPrimary = Color(0xFFE8EEF8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static Color background(BuildContext c) =>
      isDark(c) ? darkBackground : AppColors.background;
  static Color card(BuildContext c) => isDark(c) ? darkCard : AppColors.card;
  static Color inputFill(BuildContext c) =>
      isDark(c) ? darkInputFill : AppColors.inputFill;
  static Color border(BuildContext c) => isDark(c) ? darkBorder : AppColors.border;
  static Color textPrimary(BuildContext c) =>
      isDark(c) ? darkTextPrimary : AppColors.textPrimary;
  static Color textSecondary(BuildContext c) =>
      isDark(c) ? darkTextSecondary : AppColors.textSecondary;
}

/// App-wide ThemeData. Use AppTheme.lightTheme / darkTheme in MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
        primary: AppColors.purple,
        surface: AppColors.card,
        secondary: AppColors.purpleLight,
      ),
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.purple.withValues(alpha: 0.18),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          elevation: 0,
          shadowColor: const Color(0x12000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: const Color(0x120F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        primary: const Color(0xFF818CF8),
        secondary: const Color(0xFF22D3EE),
        surface: AppPalette.darkCard,
      ),
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppPalette.darkTextPrimary),
        bodyMedium: TextStyle(color: AppPalette.darkTextPrimary),
        titleLarge: TextStyle(
          color: AppPalette.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkInputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        hintStyle: const TextStyle(
          color: AppPalette.darkTextSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.purple.withValues(alpha: 0.18),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppPalette.darkCard,
          foregroundColor: AppPalette.darkTextPrimary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppPalette.darkBorder),
          elevation: 0,
          shadowColor: const Color(0x12000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF818CF8),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: AppPalette.darkTextSecondary),
      dividerTheme: const DividerThemeData(color: AppPalette.darkBorder),
      cardTheme: CardThemeData(
        color: AppPalette.darkCard,
        elevation: 0,
        shadowColor: const Color(0x16000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppPalette.darkBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.darkTextPrimary,
        contentTextStyle: const TextStyle(color: AppPalette.darkBackground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}