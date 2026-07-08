import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna Utama (Deep Emerald & Mint/Teal)
  static const Color primaryColor = Color(0xFF0D5C46); // Emerald Tua
  static const Color primaryLight = Color(0xFF1E8267);
  static const Color secondaryColor = Color(0xFF2EC4B6); // Teal Terang
  static const Color accentColor = Color(0xFFFF9F1C); // Oranye untuk aksen saldo/alert
  static const Color backgroundColor = Color(0xFFF7FBF9); // Hijau Sangat Lembut
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1A2A25);
  static const Color textLight = Color(0xFF6B7F79);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: const Color(0xFFBA1A1A),
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withAlpha(26), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        headlineLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textDark),
        headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: textDark),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: textDark),
        bodySmall: GoogleFonts.outfit(fontSize: 12, color: textLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
        labelStyle: GoogleFonts.outfit(color: textLight),
        hintStyle: GoogleFonts.outfit(color: Colors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        selectedLabelTextStyle: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: GoogleFonts.outfit(color: Colors.grey),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withAlpha(38),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: Colors.grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return GoogleFonts.outfit(color: Colors.grey, fontSize: 12);
        }),
      ),
    );
  }
}
