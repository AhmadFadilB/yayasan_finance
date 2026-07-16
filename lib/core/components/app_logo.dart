import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String text;
  final double? fontSize;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = false,
    this.text = 'Yayasan Crowdfund',
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppTheme.primaryColor;
    
    final logoIcon = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppTheme.primaryColor,
          AppTheme.secondaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        Icons.volunteer_activism_outlined,
        size: size,
        color: Colors.white,
      ),
    );

    if (!showText) {
      return logoIcon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: logoColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
        ),
      ],
    );
  }
}
