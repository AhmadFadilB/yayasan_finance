import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/utils/url_helper.dart';
import '../../transactions/providers/transaction_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';
import '../widgets/project_carousel.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final dynamic project; // Menerima ProjectModel hasil copyWith dari list screen

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final projectsWithFinance = ref.watch(projectsWithFinanceProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    // Cari data proyek terbaru dari state provider untuk mendapatkan pembaruan setelah edit
    final currentProject = projectsWithFinance.firstWhere(
      (p) => p.id == project.id,
      orElse: () => project as ProjectModel,
    );

    // Filter transaksi yang hanya terkait dengan proyek ini
    final projectTxs = transactionState.transactions.where((tx) => tx.projectId == currentProject.id).toList();

    Widget buildFinancialCard(String label, double amount, Color color, IconData icon) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatter.formatRupiah(amount),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildInfoRow(IconData icon, String label, String value) {
      return Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textLight),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    Widget buildCoverImage() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ProjectCarousel(
          coverImageUrl: currentProject.coverImageUrl,
          galleryUrls: currentProject.galleryUrls,
          isPublic: currentProject.isPublic,
        ),
      );
    }

    Widget buildInfoAndTarget() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi & Target Proyek',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deskripsi Proyek',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Text(
                        currentProject.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentProject.description ?? 'Tidak ada deskripsi proyek.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                
                // Detail Waktu & Target
                buildInfoRow(
                  Icons.date_range_outlined,
                  'Tanggal Mulai',
                  currentProject.startDate != null ? Formatter.formatTanggal(currentProject.startDate!) : '-',
                ),
                const SizedBox(height: 8),
                buildInfoRow(
                  Icons.event_available_outlined,
                  'Tanggal Selesai',
                  currentProject.endDate != null ? Formatter.formatTanggal(currentProject.endDate!) : '-',
                ),
                const SizedBox(height: 8),
                buildInfoRow(
                  Icons.public_outlined,
                  'Tipe Proyek',
                  currentProject.isPublic ? 'Publik (Crowdfunding)' : 'Privat (Pembukuan Internal)',
                ),
                const SizedBox(height: 8),
                buildInfoRow(
                  Icons.track_changes,
                  'Target Dana',
                  currentProject.targetAmount != null && currentProject.targetAmount! > 0
                      ? Formatter.formatRupiah(currentProject.targetAmount!)
                      : 'Donasi Terbuka (Tanpa Target)',
                ),
                if (currentProject.isPublic) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String basePath = UrlHelper.getActualPath();
                        final String cleanPath = basePath.endsWith('/') ? basePath : '$basePath/';
                        final String publicUrl = '${Uri.base.origin}$cleanPath#/public/project?id=${currentProject.id}';
                        Clipboard.setData(ClipboardData(text: publicUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link crowdfunding proyek berhasil disalin!'),
                            backgroundColor: AppTheme.colorSuccess,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                      label: const Text('Salin Link Donasi Publik', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          currentProject.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah Proyek',
            onPressed: () {
              context.push('/proyek/${currentProject.id}/edit');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== SECTION 1 & 2: SIDE-BY-SIDE ON DESKTOP ====================
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: buildCoverImage(),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 5,
                    child: buildInfoAndTarget(),
                  ),
                ],
              )
            else ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: buildCoverImage(),
              ),
              const SizedBox(height: 24),
              buildInfoAndTarget(),
            ],
            const SizedBox(height: 32),

            // ==================== SECTION 3: RINGKASAN KEUANGAN ====================
            Text(
              'Ringkasan Keuangan Proyek',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: buildFinancialCard(
                    'Pemasukan',
                    currentProject.totalIncome,
                    const Color(0xFF0D5C46),
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFinancialCard(
                    'Pengeluaran',
                    currentProject.totalExpense,
                    const Color(0xFFE53935),
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFinancialCard(
                    'Saldo Sisa',
                    currentProject.balance,
                    currentProject.balance >= 0 ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ==================== SECTION 4: RIWAYAT TRANSAKSI ====================
            Text(
              'Riwayat Transaksi Proyek',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            if (projectTxs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi tercatat untuk proyek ini.',
                        style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.divider),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projectTxs.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final tx = projectTxs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: tx.isIncome ? AppTheme.colorSuccess.withAlpha(26) : AppTheme.colorError.withAlpha(26),
                        foregroundColor: tx.isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                        child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
                      ),
                      title: Text(
                        tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${Formatter.formatTanggal(tx.transactionDate)} • oleh ${tx.creatorName ?? "Umum"}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
                      ),
                      trailing: Text(
                        '${tx.isIncome ? '+' : '-'}${Formatter.formatRupiah(tx.amount)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          color: tx.isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
