import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/status_badge.dart';

class ProjectCard extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool isPublic;
  final String status;
  final String foundationName;
  final double? targetAmount;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.isPublic,
    required this.status,
    required this.foundationName,
    this.targetAmount,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Widget _buildStatusBadge(String status) {
    String label;
    String statusVal;
    switch (status) {
      case 'active':
        statusVal = 'approved';
        label = 'BERJALAN';
        break;
      case 'completed':
        statusVal = 'settled';
        label = 'SELESAI';
        break;
      case 'planned':
      default:
        statusVal = 'pending';
        label = 'DIRENCANAKAN';
        break;
    }
    return StatusBadge(status: statusVal, label: label);
  }

  Widget _buildAdminMetric(BuildContext context, String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textLight),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatter.formatRupiah(amount),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetAmount != null && targetAmount! > 0;
    final progress = hasTarget ? (totalIncome / targetAmount!).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Section - 16:9 Cover Image / Placeholder
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              children: [
                // Cover Image or Gradient Placeholder
                Positioned.fill(
                  child: coverImageUrl != null
                      ? Image.network(
                          coverImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFF7F6F2),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: AppTheme.primaryColor),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              isPublic ? Icons.volunteer_activism : Icons.folder_special,
                              color: Colors.white.withAlpha(180),
                              size: 40,
                            ),
                          ),
                        ),
                ),

                // Overlay Badge (Status for Admin, Foundation Name for Public)
                Positioned(
                  top: 12,
                  left: 12,
                  child: isAdmin
                      ? _buildStatusBadge(status)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.radiusSm,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            foundationName.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                ),

                // Popup Menu Overlay for Admin View
                if (isAdmin)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.black26),
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Ubah'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 2. Bottom Section - Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Judul Proyek (Maks 2 baris)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor.withAlpha(26),
                      child: Text(
                        (foundationName.isNotEmpty ? foundationName[0] : 'Y').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (description != null && description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Spacing and Divider for Admin vs Progress elements for Public
                if (isAdmin) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildAdminMetric(context, 'Pemasukan', totalIncome, AppTheme.colorSuccess)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAdminMetric(context, 'Pengeluaran', totalExpense, AppTheme.colorError)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAdminMetric(context, 'Saldo Sisa', balance, AppTheme.primaryColor)),
                    ],
                  ),
                ] else ...[
                  // Metadata Baris Kecil
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volunteer_activism, size: 12, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${Formatter.formatRupiah(totalIncome)} terkumpul',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        hasTarget ? '$percent% tercapai' : 'Donasi Terbuka',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasTarget ? const Color(0xFFD9A441) : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (hasTarget) ...[
                    const SizedBox(height: 8),
                    // Progress Bar Amber Gradient
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEBEB),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD9A441), Color(0xFFF3C472)],
                            ),
                            borderRadius: AppRadius.radiusPill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
