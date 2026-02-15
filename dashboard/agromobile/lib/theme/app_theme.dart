import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050A14), // Deep space blue/black
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FFC2), // Neon Mint
      secondary: Color(0xFF00E5FF), // Neon Cyan
      tertiary: Color(0xFFD500F9), // Neon Purple
      surface: Color(0xFF0B1221), // Dark glass container
      surfaceContainerHighest: Color(0xFF16233A),
      onPrimary: Color(0xFF003328),
      onSurface: Color(0xFFE0F7FA),
      error: Color(0xFFFF5252),
    ),
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: const Color(0xFFE0F7FA),
      displayColor: const Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFF00FFC2),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF16233A).withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00FFC2), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIconColor: const Color(0xFF00FFC2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FFC2),
        foregroundColor: const Color(0xFF003328),
        elevation: 8,
        shadowColor: const Color(0xFF00FFC2).withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF111C2E).withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      margin: const EdgeInsets.all(8),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF00FFC2),
      size: 24,
    ),
    useMaterial3: true,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00C853),
      secondary: Color(0xFF00B0FF),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Color(0xFF102027),
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    useMaterial3: true,
  );
}
