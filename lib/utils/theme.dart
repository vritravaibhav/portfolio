import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgPrimary   = Color(0xFF0A0E1A);
  static const Color bgCard      = Color(0xFF0F1629);
  static const Color accentCyan  = Color(0xFF0FF0FC);
  static const Color accentAmber = Color(0xFFFFB703);
  static const Color textPrimary = Color(0xFFCBD5E1);
  static const Color textMuted   = Color(0xFF64748B);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: bgPrimary,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: bgPrimary,
      secondary: bgCard,
      tertiary: accentCyan,
      onPrimary: textPrimary,
      onSecondary: textMuted,
      surface: bgCard,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.syne(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.syne(
        color: textPrimary,
        fontSize: 52,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
      ),
      displayMedium: GoogleFonts.syne(
        color: textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      displaySmall: GoogleFonts.syne(
        color: accentCyan,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.syne(
        color: accentAmber,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.ibmPlexSans(
        color: textPrimary,
        fontSize: 15,
        height: 1.7,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        color: textPrimary,
        fontSize: 13,
        height: 1.7,
      ),
      labelSmall: GoogleFonts.ibmPlexMono(
        color: accentCyan,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF0F1F33),
      labelStyle: GoogleFonts.ibmPlexMono(
        color: accentCyan,
        fontSize: 11,
      ),
      side: const BorderSide(color: Color(0x330FF0FC)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0A1020),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x330FF0FC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x330FF0FC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentCyan, width: 1.5),
      ),
      labelStyle: GoogleFonts.ibmPlexSans(color: textMuted),
      errorStyle: GoogleFonts.ibmPlexSans(color: Colors.redAccent, fontSize: 11),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentCyan,
        foregroundColor: Colors.black87,
        textStyle: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}
