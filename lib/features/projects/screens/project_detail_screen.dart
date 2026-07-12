import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/utils/url_helper.dart';
import '../../transactions/providers/transaction_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final dynamic project; // Menerima ProjectModel hasil copyWith dari list screen

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    
    // Filter transaksi yang hanya terkait dengan proyek ini
    final projectTxs = transactionState.transactions.where((tx) => tx.projectId == project.id).toList();

    Widget buildFinancialCard(String label, double amount, Color color, IconData icon) {
      return Card(
        elevation: 0,
        color: Colors.white,
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
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatter.formatRupiah(amount),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
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
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1A2A25), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Informasi Proyek
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(26), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informasi Proyek',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A2A25)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5C46).withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.status.toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.description ?? 'Tidak ada deskripsi proyek.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7F79)),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Detail Waktu
                  buildInfoRow(
                    Icons.date_range_outlined,
                    'Tanggal Mulai',
                    project.startDate != null ? Formatter.formatTanggal(project.startDate!) : '-',
                  ),
                  const SizedBox(height: 8),
                  buildInfoRow(
                    Icons.event_available_outlined,
                    'Tanggal Selesai',
                    project.endDate != null ? Formatter.formatTanggal(project.endDate!) : '-',
                  ),
                  const SizedBox(height: 8),
                  buildInfoRow(
                    Icons.public_outlined,
                    'Tipe Proyek',
                    project.isPublic ? 'Publik (Crowdfunding)' : 'Privat (Pembukuan Internal)',
                  ),
                  if (project.isPublic) ...[
                    const SizedBox(height: 8),
                    buildInfoRow(
                      Icons.track_changes,
                      'Target Dana',
                      project.targetAmount > 0 ? Formatter.formatRupiah(project.targetAmount) : 'Tidak Terbatas',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final String basePath = UrlHelper.getActualPath();
                          final String cleanPath = basePath.endsWith('/') ? basePath : '$basePath/';
                          final String publicUrl = '${Uri.base.origin}${cleanPath}#/public/project?id=${project.id}';
                          Clipboard.setData(ClipboardData(text: publicUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link crowdfunding proyek berhasil disalin!'),
                              backgroundColor: Color(0xFF0D5C46),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                        label: const Text('Salin Link Donasi Publik', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C46),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Anggaran Proyek (3 Cards)
            Row(
              children: [
                Expanded(
                  child: buildFinancialCard(
                    'Pemasukan',
                    project.totalIncome,
                    const Color(0xFF0D5C46),
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFinancialCard(
                    'Pengeluaran',
                    project.totalExpense,
                    const Color(0xFFE53935),
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFinancialCard(
                    'Saldo Sisa',
                    project.balance,
                    project.balance >= 0 ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Daftar Transaksi Terkait Proyek
            Text(
              'Riwayat Keuangan Proyek',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A2A25)),
            ),
            const SizedBox(height: 16),

            if (projectTxs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(26)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi tercatat untuk proyek ini.',
                        style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(26)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projectTxs.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.withAlpha(26), height: 1),
                  itemBuilder: (context, index) {
                    final tx = projectTxs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: tx.isIncome ? const Color(0xFF0D5C46).withAlpha(18) : const Color(0xFFE53935).withAlpha(18),
                        foregroundColor: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                        child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
                      ),
                      title: Text(
                        tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${Formatter.formatTanggal(tx.transactionDate)} • oleh ${tx.creatorName ?? "Umum"}',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Text(
                        '${tx.isIncome ? '+' : '-'}${Formatter.formatRupiah(tx.amount)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
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
