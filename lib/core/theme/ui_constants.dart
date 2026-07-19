import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double pill = 9999.0;

  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusPill => BorderRadius.circular(pill);
}

class UIConstants {
  // Spacing Scale
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // Radius Scale (Deprecated - Use AppRadius instead)
  static const double r12 = 6.0;
  static const double r16 = 8.0;
  static const double r20 = 10.0;
  static const double rMax = 999.0;

  static BorderRadius get radius12 => BorderRadius.circular(r12);
  static BorderRadius get radius16 => BorderRadius.circular(r16);
  static BorderRadius get radius20 => BorderRadius.circular(r20);
  static BorderRadius get radiusMax => BorderRadius.circular(rMax);

  // Soft Shadows (large blur, low opacity)
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: const Color(0xFF1A1F1C).withAlpha(10), // Very light gray-greenish-black
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: const Color(0xFF1A1F1C).withAlpha(15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
