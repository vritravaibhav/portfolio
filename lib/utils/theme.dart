import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color secondaryColor = Color(0xFFF2F2F2);
  static const Color accentColor = Color(0xFF007BFF);
  static const Color lightTextColor = Color(0xFF333333);
  static const Color darkTextColor = Color(0xFF555555);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onPrimary: lightTextColor,
      onSecondary: darkTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        color: lightTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: lightTextColor),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: lightTextColor,
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: lightTextColor,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: lightTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: accentColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: lightTextColor,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: darkTextColor,
        fontSize: 14,
      ),
    ),
  );
}
