import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // RTM Brand — the real accent used across the app is a warm orange/coral.
  // Use these tokens instead of hardcoding hex in screens.
  // ---------------------------------------------------------------------------
  static const Color accent = Color(0xFFFF5722); // Deep orange (brand)
  static const Color accentLight = Color(0xFFFF7043);
  static const Color accentBright = Color(0xFFFF8A65);
  static const Color accentDark = Color(0xFFE64A19);
  static const Color heart = Color(0xFFE91E63); // Pink used in match moments

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark surfaces (wallet, live dates, immersive screens).
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurface2 = Color(0xFF2A2A2A);

  // Backwards-compatible aliases — `primary` now points at the brand accent so
  // existing references stay correct while we migrate hardcoded hex to tokens.
  static const Color primary = accent;
  static const Color primaryLight = accentLight;
  static const Color primaryDark = accentDark;

  static const Color backgroundLight = Color(0xFFF8F9FE); // Very light grey
  static const Color textDark = Color(0xFF1A1D1E); // Almost black
  static const Color textGrey = Color(0xFF9CA3AF); // Muted grey

  // Gradients
  static const LinearGradient primaryGradient = accentGradient;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        background: backgroundLight,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,

      // Typography
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textDark),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: textGrey, fontSize: 14),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      fontFamily: GoogleFonts.poppins().fontFamily,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Context-aware semantic tokens. These return the correct value for the
  // current ThemeMode so screens can support both light and dark. Use these
  // instead of hardcoding darkBg / Colors.white in dual-mode screens.
  // ---------------------------------------------------------------------------
  static const Color _lightBg = Color(0xFFF4F5F8);
  static const Color _lightSurface = Colors.white;
  static const Color _lightSurface2 = Color(0xFFEDEFF3);

  static bool isLight(BuildContext c) =>
      Theme.of(c).brightness == Brightness.light;

  static Color bg(BuildContext c) => isLight(c) ? _lightBg : darkBg;
  static Color surface(BuildContext c) => isLight(c) ? _lightSurface : darkSurface;
  static Color surface2(BuildContext c) =>
      isLight(c) ? _lightSurface2 : darkSurface2;

  /// Primary text/icon color.
  static Color textPrimary(BuildContext c) =>
      isLight(c) ? const Color(0xFF1A1D1E) : Colors.white;

  /// Secondary text (subtitles).
  static Color textSecondary(BuildContext c) =>
      isLight(c) ? const Color(0xFF6B7280) : Colors.white70;

  /// Muted/placeholder text.
  static Color textFaint(BuildContext c) =>
      isLight(c) ? const Color(0xFF9AA0A6) : Colors.white38;

  /// Subtle border / hairline.
  static Color hairline(BuildContext c) => isLight(c)
      ? Colors.black.withValues(alpha: 0.07)
      : Colors.white.withValues(alpha: 0.07);

  /// A foreground color at an arbitrary opacity that flips per mode (white in
  /// dark, near-black in light).
  static Color fg(BuildContext c, double opacity) => isLight(c)
      ? Colors.black.withValues(alpha: opacity)
      : Colors.white.withValues(alpha: opacity);
}
