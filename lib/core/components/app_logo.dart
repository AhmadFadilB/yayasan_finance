import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/ui_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String text;
  final String? subtitle;
  final double? fontSize;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = false,
    this.text = 'Yayasan Finance',
    this.subtitle = 'ISAK 35 COMPLIANT',
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoTextColor = color ?? Colors.white;

    final logoBadge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.55,
          color: AppTheme.primaryColor,
        ),
      ),
    );

    if (!showText) {
      return logoBadge;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoBadge,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: logoTextColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? 16,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!.toUpperCase(),
                style: GoogleFonts.inter(
                  color: logoTextColor.withAlpha(153),
                  fontWeight: FontWeight.w600,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

