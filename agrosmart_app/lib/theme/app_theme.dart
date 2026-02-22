import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette (matches React dashboard exactly) ──
  static const Color bgDark = Color(0xFF0b1220);
  static const Color cardBg = Color(0xFF071024);
  static const Color cardBg2 = Color(0xFF0d1a2e);
  static const Color glassBorder = Color(0x14FFFFFF);

  static const Color accent1 = Color(0xFF06b6d4); // Cyan
  static const Color accent2 = Color(0xFF10b981); // Emerald
  static const Color accent3 = Color(0xFF60a5fa); // Blue
  static const Color accent4 = Color(0xFF38bdf8); // Sky blue
  static const Color accent5 = Color(0xFF22d3ee); // Light cyan

  static const Color textPrimary = Color(0xFFdbeff6);
  static const Color textSecondary = Color(0xFFa9c8d6);
  static const Color textMuted = Color(0xFF8aa6b8);
  static const Color heading = Color(0xFFe6fbff);

  static const Color success = Color(0xFF10b981);
  static const Color warning = Color(0xFFf59e0b);
  static const Color danger = Color(0xFFef4444);
  static const Color info = Color(0xFF38bdf8);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06b6d4), Color(0xFF10b981)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0b1220), Color(0xFF060d1a)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0d1a2e), Color(0xFF071024)],
  );

  // ── Glass card decoration ──
  static BoxDecoration glassDeco({
    Color borderColor = const Color(0x14FFFFFF),
    double radius = 16,
    List<Color>? gradientColors,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          gradientColors ?? [const Color(0xFF0d1a2e), const Color(0xFF071024)],
    ),
    border: Border.all(color: borderColor, width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF06b6d4).withOpacity(0.06),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ],
  );

  // ── Theme Data ──
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      surface: cardBg,
      primary: accent1,
      secondary: accent2,
      tertiary: accent3,
      error: danger,
      onSurface: textPrimary,
      onPrimary: bgDark,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: heading,
        fontWeight: FontWeight.w700,
        fontSize: 32,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: heading,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        color: heading,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 14),
      bodyMedium: GoogleFonts.spaceGrotesk(color: textSecondary, fontSize: 13),
      bodySmall: GoogleFonts.spaceGrotesk(color: textMuted, fontSize: 11),
      labelSmall: GoogleFonts.spaceMono(color: textMuted, fontSize: 10),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF060d1a),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: heading,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      iconTheme: const IconThemeData(color: accent4),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF060d1a),
      selectedItemColor: accent1,
      unselectedItemColor: textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    dividerColor: glassBorder,
    cardColor: cardBg,
    iconTheme: const IconThemeData(color: accent4, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0d1a2e),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent1, width: 1.5),
      ),
      labelStyle: GoogleFonts.spaceGrotesk(color: textMuted, fontSize: 13),
      hintStyle: GoogleFonts.spaceGrotesk(color: textMuted, fontSize: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent1,
        foregroundColor: bgDark,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accent1,
      thumbColor: accent1,
      inactiveTrackColor: Color(0x33FFFFFF),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent1,
      linearTrackColor: Color(0x1FFFFFFF),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF0d1a2e),
      labelStyle: GoogleFonts.spaceGrotesk(color: textSecondary, fontSize: 12),
      side: const BorderSide(color: Color(0x1FFFFFFF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // ── Sensor color mapping ──
  static Color sensorColor(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return const Color(0xFFfb7185);
      case 'humidity':
        return accent3;
      case 'soilmoisture':
      case 'soil_moisture':
        return accent2;
      case 'lightlevel':
      case 'light_level':
        return const Color(0xFFfbbf24);
      case 'pump':
        return accent1;
      default:
        return accent4;
    }
  }
}
