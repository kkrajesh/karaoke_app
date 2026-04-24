import 'package:flutter/material.dart';

class AppTheme {
  // AIStudio Color Palette
  static const Color bgDark = Color(0xFF111827); // gray-900
  static const Color bgCard = Color(0xFF1F2937); // gray-800
  static const Color bgInput = Color(0xFF374151); // gray-700
  static const Color border = Color(0xFF4B5563); // gray-600
  
  static const Color textMain = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400
  
  static const Color accentPurple = Color(0xFF9333EA); // purple-600
  static const Color accentPurpleLight = Color(0xFFD8B4FE); // purple-300
  static const Color accentPink = Color(0xFFDB2777); // pink-600
  static const Color accentBlue = Color(0xFF2563EB); // blue-600
  static const Color accentRed = Color(0xFFDC2626); // red-600
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentPurple,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: bgCard,
        surfaceContainerHighest: bgInput,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textMain),
        bodyMedium: TextStyle(color: textMain),
        bodySmall: TextStyle(color: textMuted),
        headlineSmall: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textMain, fontWeight: FontWeight.w600),
      ),
    );
  }
}
