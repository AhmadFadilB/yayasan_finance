import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_constants.dart';

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AppColors {
  static const Color divider = Color(0xFFE5E7EB);
}

class AppTheme {
  // Brand & Semantic Colors (Exact Stitch Literal Hex)
  static const Color primaryColor = Color(0xFF08241A); // Stitch brand-forest
  static const Color primaryLight = Color(0xFF163E2D);
  static const Color primaryDark = Color(0xFF000905); // Stitch primary
  
  static const Color secondaryColor = Color(0xFFC9972B); // Stitch brand-gold

  static const Color backgroundColor = Color(0xFFF8F7F4); // Stitch background
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textDark = Color(0xFF1A1C1B); // Stitch on-surface
  static const Color textLight = Color(0xFF6B7570); // Stitch on-surface-variant

  // Semantic Colors
  static const Color colorSuccess = Color(0xFF1F7A4D);
  static const Color colorError = Color(0xFFC1443A);
  static const Color colorWarning = Color(0xFFD9A441);

  // Muted / Desaturated Colors for Chart Graphics (Stitch look)
  static const Color chartSuccessMuted = Color(0xFF265835); // Deep muted forest green
  static const Color chartErrorMuted = Color(0xFF7A2E29);   // Deep muted brick red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: kIsWeb
              ? const NoTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: kIsWeb
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: kIsWeb
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: colorError,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: AppColors.divider,

      // Card Theme with AppRadius.md (No Border, Shadow Based)
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: BorderSide.none,
        ),
      ),

      // Clean AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),

      // Typography system using Plus Jakarta Sans for headers & Inter for body text
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),

        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textDark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textLight,
        ),
      ),

      // Input Decoration with standard radius & borderless soft fill
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: const BorderSide(color: colorError, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          color: textLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(color: textLight.withAlpha(128)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: textLight),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(color: textLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withAlpha(38),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: textLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return GoogleFonts.plusJakartaSans(color: textLight, fontSize: 12);
        }),
      ),
    );
  }
}
