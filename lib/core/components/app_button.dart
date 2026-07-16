import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/ui_constants.dart';

enum AppButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double? radius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.sm);
    
    // Define colors based on button style
    Color bg;
    Color fg;
    BorderSide? border;

    switch (style) {
      case AppButtonStyle.primary:
        bg = onPressed == null ? AppTheme.textLight.withAlpha(51) : AppTheme.primaryColor;
        fg = Colors.white;
        break;
      case AppButtonStyle.secondary:
        bg = onPressed == null ? AppTheme.textLight.withAlpha(51) : AppTheme.secondaryColor;
        fg = Colors.white;
        break;
      case AppButtonStyle.outline:
        bg = Colors.transparent;
        fg = onPressed == null ? AppTheme.textLight : AppTheme.primaryColor;
        border = BorderSide(color: fg, width: 1.5);
        break;
      case AppButtonStyle.ghost:
        bg = Colors.transparent;
        fg = onPressed == null ? AppTheme.textLight : AppTheme.primaryColor;
        break;
    }

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: UIConstants.s24),
        ),
        child: content,
      ),
    );
  }
}
