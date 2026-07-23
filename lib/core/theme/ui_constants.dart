import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double badge = 12.0;
  static const double pill = 9999.0;

  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusBadge => BorderRadius.circular(badge);
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

  // Soft Shadows (Exact Stitch CSS .soft-elevation)
  // box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.05), 0 2px 10px -2px rgba(0, 0, 0, 0.03);
  static List<BoxShadow> get shadowSoft => [
        const BoxShadow(
          color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
          offset: Offset(0, 4),
          blurRadius: 20,
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x08000000), // rgba(0, 0, 0, 0.03)
          offset: Offset(0, 2),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

