import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/empty_state_view.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/utils/formatter.dart';
import '../providers/accounting_provider.dart';
import '../models/journal_model.dart';
import '../../foundations/providers/foundation_provider.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountingProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final userRole = activeFoundation?.currentUserRole ?? 'viewer';
    final canModify = userRole == 'admin' || userRole == 'bendahara';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: Text(
          'Jurnal Umum (Double-Entry)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (canModify)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/accounting/journal/form');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Voucher Jurnal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.entries.isEmpty
              ? const EmptyStateView(
                  icon: Icons.menu_book_rounded,
                  title: 'Belum Ada Jurnal',
                  description: 'Silakan buat voucher jurnal umum pertama Anda.',
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListView.separated(
                    itemCount: state.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return _buildJournalVoucherCard(context, ref, entry, canModify);
                    },
                  ),
                ),
    );
  }

  Widget _buildJournalVoucherCard(BuildContext context, WidgetRef ref, JournalEntryModel entry, bool canModify) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: const EdgeInsets.all(20),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: AppRadius.radiusSm,
              ),
              child: Text(
                entry.proofNumber,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description?.isNotEmpty == true
                        ? entry.description!
                        : 'Voucher Jurnal Umum',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Formatter.formatTanggal(entry.transactionDate),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Oleh: ${entry.createdByName ?? 'System'}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Debit/Kredit',
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatter.formatRupiah(entry.totalDebit),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF0F5A47),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            if (canModify)
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, ref, value, entry),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Voucher'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus Jurnal', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        children: [
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2), // Kode Akun
              1: FlexColumnWidth(2.5), // Nama Akun & Memo
              2: FlexColumnWidth(1.5), // Proyek
              3: FlexColumnWidth(1.5), // Debit
              4: FlexColumnWidth(1.5), // Kredit
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Kode Akun'),
                  _buildTableHeader('Nama Akun / Memo'),
                  _buildTableHeader('Proyek'),
                  _buildTableHeader('Debit', alignLeft: false),
                  _buildTableHeader('Kredit', alignLeft: false),
                ],
              ),
              ...entry.items.map((item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(item.accountCode ?? '-', style: GoogleFonts.inter(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.accountName ?? '-', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                          if (item.memo?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(item.memo!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        item.projectName ?? 'Umum',
                        style: GoogleFonts.outfit(fontSize: 12, color: item.projectId != null ? AppTheme.primaryColor : Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.debit > 0 ? Formatter.formatRupiah(item.debit) : '-',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: item.debit > 0 ? FontWeight.bold : FontWeight.normal,
                            color: item.debit > 0 ? const Color(0xFF0F5A47) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.credit > 0 ? Formatter.formatRupiah(item.credit) : '-',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: item.credit > 0 ? FontWeight.bold : FontWeight.normal,
                            color: item.credit > 0 ? const Color(0xFFE53935) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          if (entry.changeReason?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: Colors.amber.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan Perubahan: ${entry.changeReason!}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[900], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {bool alignLeft = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF37474F),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, JournalEntryModel entry) {
    if (action == 'edit') {
      context.push('/accounting/journal/form?id=${entry.id}');
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus Voucher Jurnal?'),
          content: Text('Apakah Anda yakin ingin menghapus voucher jurnal ${entry.proofNumber}? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(accountingProvider.notifier).removeJournalEntry(entry.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher jurnal berhasil dihapus.'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                } else if (context.mounted) {
                  final error = ref.read(accountingProvider).errorMessage ?? 'Gagal menghapus voucher.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }
}
