import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatter.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class ApprovalListScreen extends ConsumerWidget {
  const ApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;

    if (activeFoundation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D5C46))),
      );
    }

    // Filter transaksi yang berstatus pending
    final pendingTxs = transactionState.transactions
        .where((tx) => tx.status == 'pending')
        .toList();

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    void handleApprove(TransactionModel tx) {
      final isIncome = tx.isIncome;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              isIncome ? 'Verifikasi Donasi Masuk' : 'Setujui Transaksi',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              isIncome
                  ? 'Apakah Anda yakin ingin memverifikasi donasi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Saldo kas yayasan akan bertambah secara resmi.'
                  : 'Apakah Anda yakin ingin menyetujui pengeluaran "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Saldo yayasan akan dipotong secara resmi.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C46),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(transactionProvider.notifier)
                      .approveTransaction(tx.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isIncome ? 'Donasi berhasil diverifikasi!' : 'Transaksi berhasil disetujui!')
                            : 'Gagal memproses transaksi.'),
                        backgroundColor: success ? const Color(0xFF0D5C46) : Colors.red,
                      ),
                    );
                  }
                },
                child: Text(isIncome ? 'Verifikasi' : 'Setujui', style: GoogleFonts.outfit()),
              ),
            ],
          );
        },
      );
    }

    void handleReject(TransactionModel tx) {
      final isIncome = tx.isIncome;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              isIncome ? 'Tolak Donasi Masuk' : 'Tolak Transaksi',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              isIncome
                  ? 'Apakah Anda yakin ingin menolak donasi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Donasi ini akan ditandai ditolak.'
                  : 'Apakah Anda yakin ingin menolak pengeluaran "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Transaksi ini akan ditandai ditolak.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(transactionProvider.notifier)
                      .rejectTransaction(tx.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Transaksi ditolak!'
                            : 'Gagal memproses penolakan.'),
                        backgroundColor: success ? const Color(0xFFC62828) : Colors.red,
                      ),
                    );
                  }
                },
                child: Text(isIncome ? 'Tolak Donasi' : 'Tolak Transaksi', style: GoogleFonts.outfit()),
              ),
            ],
          );
        },
      );
    }

    Widget buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fact_check_outlined, size: 80, color: Color(0xFFB0BEC5)),
            const SizedBox(height: 20),
            Text(
              'Semua Transaksi Bersih!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A2A25),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada pengajuan pengeluaran atau donasi masuk baru yang membutuhkan persetujuan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF6B7F79), fontSize: 14),
            ),
          ],
        ),
      );
    }

    Widget buildDesktopTable() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(26)),
        ),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('Tanggal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tipe', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kategori Akun', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nominal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Proyek', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Diajukan Oleh', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Persetujuan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
            ],
            rows: pendingTxs.map((tx) {
              final isIncome = tx.isIncome;
              return DataRow(
                cells: [
                  DataCell(Text(Formatter.formatTanggalPendek(tx.transactionDate))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isIncome ? 'Pemasukan' : 'Pengeluaran',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(tx.category)),
                  DataCell(
                    Text(
                      Formatter.formatRupiah(tx.amount),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                  DataCell(Text(tx.projectName ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tx.receiptUrl != null) ...[
                          IconButton(
                            icon: const Icon(Icons.attachment_outlined, size: 16, color: Color(0xFF0D5C46)),
                            onPressed: () async {
                              final uri = Uri.parse(tx.receiptUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            tooltip: 'Buka bukti fisik',
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(tx.description ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(tx.creatorName ?? 'Donatur Publik')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5C46),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => handleApprove(tx),
                          icon: const Icon(Icons.check, size: 14),
                          label: Text(isIncome ? 'Verifikasi' : 'Setujui', style: GoogleFonts.outfit(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            side: const BorderSide(color: Color(0xFFC62828)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => handleReject(tx),
                          icon: const Icon(Icons.close, size: 14),
                          label: Text('Tolak', style: GoogleFonts.outfit(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    Widget buildMobileList() {
      return ListView.separated(
        itemCount: pendingTxs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = pendingTxs[index];
          final isIncome = tx.isIncome;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatter.formatTanggal(tx.transactionDate),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isIncome ? 'Pemasukan' : 'Pengeluaran',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              ),
                            ),
                          ),
                          if (tx.receiptUrl != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(tx.receiptUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: const Icon(Icons.attachment_outlined, size: 18, color: Color(0xFF0D5C46)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A2A25)),
                  ),
                  if (tx.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Akun: ${tx.category}',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diajukan: ${tx.creatorName ?? "Donatur Publik"}',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
                      ),
                      if (tx.projectName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.projectName!,
                            style: GoogleFonts.outfit(fontSize: 9, color: Colors.blue[800]),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatter.formatRupiah(tx.amount),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(color: Color(0xFFC62828)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => handleReject(tx),
                            child: Text('Tolak', style: GoogleFonts.outfit(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D5C46),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => handleApprove(tx),
                            child: Text(isIncome ? 'Verifikasi' : 'Setujui', style: GoogleFonts.outfit(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Persetujuan Transaksi',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Otorisasi Keuangan & Donasi Yayasan',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
            ),
          ],
        ),
      ),
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D5C46)))
          : transactionState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal Memuat Persetujuan',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transactionState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(transactionProvider.notifier)
                              .loadTransactions(activeFoundation.id),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(transactionProvider.notifier)
                        .loadTransactions(activeFoundation.id);
                  },
                  child: pendingTxs.isEmpty
                      ? buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: isDesktop ? buildDesktopTable() : buildMobileList(),
                        ),
                ),
    );
  }
}
