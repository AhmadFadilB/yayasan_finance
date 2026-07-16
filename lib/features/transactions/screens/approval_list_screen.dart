import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/money_text.dart';
import '../../../core/components/empty_state_view.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/components/app_modal.dart';
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
      AppModal.show(
        context: context,
        title: Text(isIncome ? 'Verifikasi Donasi Masuk' : 'Setujui Transaksi'),
        subtitle: isIncome ? 'Verifikasi pemasukan ke kas yayasan' : 'Persetujuan pengeluaran kas yayasan',
        content: Text(
          isIncome
              ? 'Apakah Anda yakin ingin memverifikasi donasi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Saldo kas yayasan akan bertambah secara resmi.'
              : 'Apakah Anda yakin ingin menyetujui pengeluaran "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Saldo yayasan akan dipotong secara resmi.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          AppButton(
            text: 'Batal',
            style: AppButtonStyle.outline,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: isIncome ? 'Verifikasi' : 'Setujui',
            style: AppButtonStyle.primary,
            onPressed: () async {
              final success = await ref
                  .read(transactionProvider.notifier)
                  .approveTransaction(tx.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isIncome ? 'Donasi berhasil diverifikasi!' : 'Transaksi berhasil disetujui!')
                        : 'Gagal memproses transaksi.'),
                    backgroundColor: success ? AppTheme.colorSuccess : AppTheme.colorError,
                  ),
                );
              }
            },
          ),
        ],
      );
    }

    void handleReject(TransactionModel tx) {
      final isIncome = tx.isIncome;
      AppModal.show(
        context: context,
        title: Text(isIncome ? 'Tolak Donasi Masuk' : 'Tolak Transaksi'),
        subtitle: 'Pemasukan/pengeluaran ini akan ditandai ditolak',
        content: Text(
          isIncome
              ? 'Apakah Anda yakin ingin menolak donasi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Donasi ini akan ditandai ditolak.'
              : 'Apakah Anda yakin ingin menolak pengeluaran "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}? Transaksi ini akan ditandai ditolak.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          AppButton(
            text: 'Batal',
            style: AppButtonStyle.outline,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: isIncome ? 'Tolak Donasi' : 'Tolak Transaksi',
            style: AppButtonStyle.secondary, // Accent/Amber/Red style
            onPressed: () async {
              final success = await ref
                  .read(transactionProvider.notifier)
                  .rejectTransaction(tx.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Transaksi ditolak!'
                        : 'Gagal memproses penolakan.'),
                    backgroundColor: success ? AppTheme.colorError : Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      );
    }

    Widget buildEmptyState() {
      return const EmptyStateView(
        icon: Icons.fact_check_outlined,
        title: 'Semua Transaksi Bersih!',
        description: 'Tidak ada pengajuan pengeluaran atau donasi masuk baru yang membutuhkan persetujuan.',
      );
    }

    Widget buildDesktopTable() {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: AppColors.divider.withAlpha(80),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                outline: AppColors.divider.withAlpha(80),
                outlineVariant: AppColors.divider.withAlpha(80),
              ),
            ),
            child: DataTable(
              columnSpacing: 24,
              columns: [
              DataColumn(label: Text('Tanggal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tipe', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kategori Akun', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nominal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Proyek', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Diajukan Oleh', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Persetujuan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
            ],
            rows: pendingTxs.map((tx) {
              final isIncome = tx.isIncome;
              return DataRow(
                cells: [
                  DataCell(Text(Formatter.formatTanggalPendek(tx.transactionDate))),
                  DataCell(
                    StatusBadge(
                      status: isIncome ? 'approved' : 'rejected',
                      label: isIncome ? 'Pemasukan' : 'Pengeluaran',
                    ),
                  ),
                  DataCell(Text(tx.category)),
                  DataCell(
                    MoneyText(
                      amount: tx.amount,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      styleType: isIncome ? MoneyTextStyleType.debit : MoneyTextStyleType.credit,
                    ),
                  ),
                  DataCell(Text(tx.projectName ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tx.receiptUrl != null) ...[
                          IconButton(
                            icon: const Icon(Icons.attachment_outlined, size: 16, color: AppTheme.primaryColor),
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
                        AppButton(
                          text: isIncome ? 'Verifikasi' : 'Setujui',
                          style: AppButtonStyle.primary,
                          height: 32,
                          onPressed: () => handleApprove(tx),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: 'Tolak',
                          style: AppButtonStyle.outline,
                          height: 32,
                          onPressed: () => handleReject(tx),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
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
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatter.formatTanggal(tx.transactionDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        StatusBadge(
                          status: isIncome ? 'approved' : 'rejected',
                          label: isIncome ? 'Pemasukan' : 'Pengeluaran',
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
                            child: const Icon(Icons.attachment_outlined, size: 18, color: AppTheme.primaryColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (tx.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Akun: ${tx.category}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diajukan: ${tx.creatorName ?? "Donatur Publik"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (tx.projectName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withAlpha(26),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          tx.projectName!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MoneyText(
                      amount: tx.amount,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      styleType: isIncome ? MoneyTextStyleType.debit : MoneyTextStyleType.credit,
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: 'Tolak',
                          style: AppButtonStyle.outline,
                          height: 36,
                          onPressed: () => handleReject(tx),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: isIncome ? 'Verifikasi' : 'Setujui',
                          style: AppButtonStyle.primary,
                          height: 36,
                          onPressed: () => handleApprove(tx),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Persetujuan Transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Otorisasi Keuangan & Donasi Yayasan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : transactionState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppTheme.colorError),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal Memuat Persetujuan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transactionState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Coba Lagi',
                          onPressed: () => ref
                              .read(transactionProvider.notifier)
                              .loadTransactions(activeFoundation.id),
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
