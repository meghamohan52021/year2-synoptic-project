// lib/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Theme Color Constants ---
const Color kAppBackgroundColor = Color(0xFF874CF4);
const Color kButtonBackgroundColor =
    Color(0xFF874CF4); // Or a different color if needed
const Color kTextColorWhite = Colors.white;

// --- Assumed Font Weights & Styles ---
const FontWeight kBodyMediumWeight = FontWeight.normal;
const FontStyle kBodyMediumStyle = FontStyle.normal;
const FontWeight kTitleSmallWeight = FontWeight.w500;
const FontStyle kTitleSmallStyle = FontStyle.normal;

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kAppBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAppBackgroundColor,
        primary: kButtonBackgroundColor,
        onPrimary: kTextColorWhite,
        secondary: kButtonBackgroundColor,
        onSecondary: kTextColorWhite,
        background: kAppBackgroundColor,
        surface: kAppBackgroundColor,
        brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.leagueSpartan(
          color: kTextColorWhite,
          fontSize: 60,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.normal,
          letterSpacing: 0.0,
        ),
        bodyMedium: GoogleFonts.inter(
          color: kTextColorWhite,
          fontSize: 14,
          fontWeight: kBodyMediumWeight,
          fontStyle: kBodyMediumStyle,
          letterSpacing: 0.0,
        ),
        titleSmall: GoogleFonts.interTight(
          color: kTextColorWhite,
          fontSize: 15,
          fontWeight: kTitleSmallWeight,
          fontStyle: kTitleSmallStyle,
          letterSpacing: 0.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 95, 14, 246),
          foregroundColor: kTextColorWhite,
          elevation: 0,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.interTight(
            fontSize: 15,
            fontWeight: kTitleSmallWeight,
            fontStyle: kTitleSmallStyle,
            letterSpacing: 0.0,
          ),
        ),
      ),
    );
  }
}
