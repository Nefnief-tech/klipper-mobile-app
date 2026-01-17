import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0D0512);
  static const Color surface = Color(0xFF1A1020);
  static const Color primary = Color(0xFF8A3FD6);
  static const Color accent = Color(0xFFDFFF4F);
  static const Color text = Color(0xFFFAFAFF);
  static const Color muted = Color(0xFF666666);

  // Expressive Palette
  static const Color expressiveBackground = Color(0xFF0F0A15);
  static const Color expressiveSurface = Color(0xFF1C1428);
  static const Color expressivePrimary = Color(0xFFFFB1C8);
  static const Color expressiveSecondary = Color(0xFF91D7FF);
  static const Color expressiveTertiary = Color(0xFFFFDCA2);

  // Liquid Palette
  static const Color liquidBackground = Color(0xFF081221); // Deep Ocean Blue
  static const Color liquidSurface = Color(0xFF131D2E); // Dark Blue Surface
  static const Color liquidPrimary = Color(0xFF00FFFF); // Electric Cyan
  static const Color liquidSecondary = Color(0xFFFF33CC); // Neon Pink
  static const Color liquidText = Color(0xFFF2FAFD); // Icy White

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      onSurface: text,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.anton(
          letterSpacing: 1.2,
          fontSize: 18,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.anton(
        color: text,
        fontSize: 48,
        letterSpacing: -1,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontWeight: FontWeight.bold,
        color: text,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: text.withOpacity(0.8),
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        color: primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static ThemeData expressiveTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: expressiveBackground,
    colorScheme: const ColorScheme.dark(
      primary: expressivePrimary,
      secondary: expressiveSecondary,
      tertiary: expressiveTertiary,
      surface: expressiveSurface,
      onSurface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: expressiveSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40), // More rounded for expressive
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: expressivePrimary,
        foregroundColor: expressiveBackground,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.anton(
          letterSpacing: 1.2,
          fontSize: 18,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.anton(
        color: Colors.white,
        fontSize: 48,
        letterSpacing: -1,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: Colors.white.withOpacity(0.8),
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        color: expressivePrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static ThemeData liquidTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: liquidBackground,
    colorScheme: const ColorScheme.dark(
      primary: liquidPrimary,
      secondary: liquidSecondary,
      surface: liquidSurface,
      onSurface: liquidText,
    ),
    cardTheme: CardThemeData(
      color: liquidSurface.withOpacity(0.4), // Glass effect base
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: liquidPrimary.withOpacity(0.3), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: liquidPrimary,
        foregroundColor: liquidBackground,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        shadowColor: liquidPrimary.withOpacity(0.5),
        elevation: 8,
        textStyle: GoogleFonts.anton(
          letterSpacing: 1.2,
          fontSize: 18,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.anton(
        color: liquidText,
        fontSize: 48,
        letterSpacing: -1,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontWeight: FontWeight.bold,
        color: liquidText,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: liquidText.withOpacity(0.8),
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        color: liquidPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
