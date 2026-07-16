import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/ui_constants.dart';
import '../theme/app_theme.dart';

class AppModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    String? subtitle,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Build the title with optional subtitle and close button
    Widget buildHeader(BuildContext ctx) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1F1C),
                  ),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7570),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close, size: 20),
            splashRadius: 20,
            tooltip: 'Tutup',
          ),
        ],
      );
    }

    if (isDesktop) {
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        barrierColor: Colors.black.withAlpha(102), // ~40% opacity black
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: AlertDialog(
              titlePadding: const EdgeInsets.only(
                left: UIConstants.s24,
                right: UIConstants.s24,
                top: UIConstants.s24,
                bottom: UIConstants.s12,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: UIConstants.s24,
                vertical: UIConstants.s8,
              ),
              actionsPadding: const EdgeInsets.only(
                left: UIConstants.s24,
                right: UIConstants.s24,
                bottom: UIConstants.s24,
                top: UIConstants.s12,
              ),
              title: buildHeader(context),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: content,
              ),
              actions: actions,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shadowColor: const Color(0xFF1A1F1C).withAlpha(30),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusLg, // 20px radius
              ),
            ),
          );
        },
      );
    }

    // On mobile, show a beautiful bottom sheet
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withAlpha(102), // ~40% opacity black
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)), // 20px radius
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: UIConstants.s8),
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: AppRadius.radiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: UIConstants.s24),
                  child: buildHeader(context),
                ),
                const SizedBox(height: UIConstants.s12),
                const Divider(color: AppColors.divider, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(UIConstants.s24),
                    child: content,
                  ),
                ),
                if (actions != null && actions.isNotEmpty) ...[
                  const Divider(color: AppColors.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(UIConstants.s16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions.map((w) {
                        return Padding(
                          padding: const EdgeInsets.only(left: UIConstants.s8),
                          child: w,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
