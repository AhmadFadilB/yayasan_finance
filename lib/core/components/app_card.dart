import 'package:flutter/material.dart';
import '../theme/ui_constants.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? radius;
  final bool hasBorder;
  final bool hasShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.radius,
    this.hasBorder = true,
    this.hasShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.md);
    
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(UIConstants.s16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius,
        border: hasBorder ? Border.all(color: AppColors.divider, width: 1) : null,
        boxShadow: hasShadow ? UIConstants.shadowSoft : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Card(
        elevation: 0,
        margin: margin ?? EdgeInsets.zero,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    } else if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
