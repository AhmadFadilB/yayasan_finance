import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/ui_constants.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // Range 0.0 to 1.0
  final double height;
  final Gradient? gradient;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    
    final fillGradient = gradient ?? const LinearGradient(
      colors: [
        AppTheme.secondaryColor,
        Color(0xFFE5BE6B),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(UIConstants.rMax),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * clampedProgress;
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              width: targetWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: fillGradient,
                borderRadius: BorderRadius.circular(UIConstants.rMax),
              ),
            ),
          );
        },
      ),
    );
  }
}
