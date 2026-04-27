import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF6D5DF6);
  static const primaryDark = Color(0xFF5446D8);
  static const accentCyan = Color(0xFF22D3EE);
  static const accentGreen = Color(0xFF10B981);
  static const accentPink = Color(0xFFEC4899);
  static const accentOrange = Color(0xFFF59E0B);
  static const accentRose = Color(0xFFF43F5E);

  static const bgLight = Color(0xFFF8F7FC);
  static const bgSoft = Color(0xFFF1F5F9);
  static const cardWhite = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const borderSoft = Color(0xFFE5E7EB);

  static const bgDark = Color(0xFF080B16);
  static const cardDark = Color(0xFF111827);
  static const darkBorder = Color(0xFF243145);

  static const primaryGradient = [primary, primaryDark];
  static const violetCyanGradient = [primary, accentCyan];
  static const growthGradient = [accentGreen, accentCyan];
  static const warmGradient = [accentOrange, accentPink];
  static const surfaceGradient = [Color(0xFFFFFFFF), Color(0xFFF3F4FF)];
}
