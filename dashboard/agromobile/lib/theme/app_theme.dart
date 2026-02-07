import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050A14),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF22D3EE),
      secondary: Color(0xFF10B981),
      surface: Color(0xFF0B1220),
      surfaceContainerHighest: Color(0xFF101827),
      onPrimary: Color(0xFF041018),
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFFDBEFF6),
      displayColor: const Color(0xFFE6FBFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Color(0xFFE6FBFF),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF0B1220).withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    useMaterial3: true,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7FAFC),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
      onPrimary: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    useMaterial3: true,
  );
}
