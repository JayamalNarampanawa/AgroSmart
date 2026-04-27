import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accentCyan,
      tertiary: AppColors.accentPink,
      surface: AppColors.cardWhite,
      surfaceContainerHighest: AppColors.bgSoft,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      error: AppColors.accentRose,
    ),
    textTheme: AppTextStyles.textTheme(Brightness.light),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      prefixIconColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary.withValues(alpha: 0.10),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.14)),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
      labelStyle: GoogleFonts.inter(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.primary, size: 24),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accentCyan,
      tertiary: AppColors.accentPink,
      surface: AppColors.cardDark,
      surfaceContainerHighest: Color(0xFF172033),
      onPrimary: Colors.white,
      onSurface: Colors.white,
      error: AppColors.accentRose,
    ),
    textTheme: AppTextStyles.textTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.4),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: AppColors.accentCyan,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    iconTheme: const IconThemeData(color: AppColors.accentCyan, size: 24),
    useMaterial3: true,
  );
}
