import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE8735A); // Warm coral
  static const Color secondaryColor = Color(0xFF5B8DB8); // Calm blue
  static const Color backgroundColor = Color(0xFFFFF8F5); // Warm white
  
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color dangerColor = Color(0xFFF44336);
  
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get largeTextTheme => _buildTheme(true);

  static ThemeData _buildTheme(bool isLarge) {
    final double sizeDelta = isLarge ? 4 : 0;

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        surface: backgroundColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: (32 + sizeDelta).toDouble(),
        ),
        displayMedium: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: (28 + sizeDelta).toDouble(),
        ),
        displaySmall: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: (24 + sizeDelta).toDouble(),
        ),
        headlineMedium: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: (20 + sizeDelta).toDouble(),
        ),
        titleLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: (18 + sizeDelta).toDouble(),
        ),
        bodyLarge: GoogleFonts.openSans(
          color: textPrimary,
          fontSize: (16 + sizeDelta).toDouble(),
        ),
        bodyMedium: GoogleFonts.openSans(
          color: textPrimary,
          fontSize: (14 + sizeDelta).toDouble(),
        ),
        bodySmall: GoogleFonts.openSans(
          color: textSecondary,
          fontSize: (12 + sizeDelta).toDouble(),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: (20 + sizeDelta).toDouble(),
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: (18 + sizeDelta).toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(fontSize: (16 + sizeDelta).toDouble()),
        hintStyle: TextStyle(fontSize: (14 + sizeDelta).toDouble()),
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(fontSize: (12 + sizeDelta).toDouble()),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded, // Ensures 48x48 min touch targets
    );
  }
}
