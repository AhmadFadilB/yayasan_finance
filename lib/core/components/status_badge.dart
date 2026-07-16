import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/ui_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = label ?? status;

    final normalizedStatus = status.toLowerCase().trim();

    if (normalizedStatus == 'approved' ||
        normalizedStatus == 'disetujui' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'selesai' ||
        normalizedStatus == 'active' ||
        normalizedStatus == 'berjalan') {
      bg = AppTheme.colorSuccess.withAlpha(26); // 10% opacity
      fg = AppTheme.colorSuccess;
      if (label == null) {
        text = normalizedStatus == 'active' || normalizedStatus == 'berjalan'
            ? 'Berjalan'
            : (normalizedStatus == 'completed' || normalizedStatus == 'selesai' ? 'Selesai' : 'Disetujui');
      }
    } else if (normalizedStatus == 'rejected' ||
        normalizedStatus == 'ditolak' ||
        normalizedStatus == 'failed' ||
        normalizedStatus == 'gagal') {
      bg = AppTheme.colorError.withAlpha(26);
      fg = AppTheme.colorError;
      if (label == null) text = 'Ditolak';
    } else if (normalizedStatus == 'pending' ||
        normalizedStatus == 'planned' ||
        normalizedStatus == 'direncanakan' ||
        normalizedStatus == 'proses') {
      bg = AppTheme.colorWarning.withAlpha(26);
      fg = AppTheme.colorWarning;
      if (label == null) {
        text = normalizedStatus == 'planned' || normalizedStatus == 'direncanakan'
            ? 'Direncanakan'
            : 'Menunggu';
      }
    } else {
      bg = AppTheme.textLight.withAlpha(26);
      fg = AppTheme.textDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.s12, vertical: UIConstants.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(UIConstants.rMax),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
