import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? Colors.white : AppColors.textPrimary;
    final secondary = isDark ? Colors.white70 : AppColors.textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: primary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: secondary,
      ),
    );
  }
}
