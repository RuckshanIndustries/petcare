import 'package:flutter/material.dart';

// Define theme colors
const Color primaryGreen = Color(0xFF4CAF50); // For headers, buttons, bottom nav
const Color backgroundLight = Color(0xFFF5F5F5); // Background color
const Color cardWhite = Color(0xFFFFFFFF); // Card background
const Color textPrimary = Color(0xFF333333); // Primary text
const Color textSecondary = Color(0xFF666666); // Secondary text
const Color shadowColor = Color(0x1A000000); // Subtle shadow
const Color accentOrange = Color(0xFFFF9800); // For profile backgrounds

ThemeData getAppTheme() {
  return ThemeData(
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundLight,
    fontFamily: 'Poppins',
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
    ),
    cardTheme: CardTheme(
      color: cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      shadowColor: shadowColor,
    ),
  );
}