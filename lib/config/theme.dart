import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color accentColor = Color(0xFF3498DB);
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color textColor = Color(0xFFF5F5F5);

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: textColor,
      onSecondary: textColor,
      onSurface: textColor,
      onBackground: textColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: textColor,
      displayColor: textColor,
    ),
  );
} 