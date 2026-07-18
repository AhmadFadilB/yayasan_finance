import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/components/money_text.dart';
import '../../../core/components/app_card.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/transaction_form_dialog.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _selectedProjectId;
  String _selectedType = 'all'; // 'all', 'income', 'expense'
  String _selectedCategory = 'all'; // 'all' or categories

  final List<String> _allCategories = const [
    'all',
    'Donasi',
    'Wakaf',
    'Bantuan',
    'Operasional',
    'Konsumsi',
    'Transport',
    'Lainnya',
  ];

  Widget _buildStatusBadge(String status) {
    return StatusBadge(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final projects = ref.watch(projectProvider).projects;
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;

    final role = activeFoundation?.currentUserRole ?? 'viewer';
    final isAdmin = role == 'admin';
    final isBendahara = role == 'bendahara';
    final canModify = isAdmin || isBendahara;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Terapkan filter di sisi client
    final filteredTxs = transactionState.transactions.where((tx) {
      // Filter Proyek
      if (_selectedProjectId != null && tx.projectId != _selectedProjectId) {
        return false;
      }
      // Filter Tipe
      if (_selectedType != 'all' && tx.type != _selectedType) {
        return false;
      }
      // Filter Kategori
      if (_selectedCategory != 'all' && tx.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    void showTransactionForm({TransactionModel? transaction}) {
      TransactionFormDialog.show(context, transaction: transaction);
    }

    void confirmDeleteTransaction(TransactionModel tx) {
      AppModal.show(
        context: context,
        title: const Text('Hapus Transaksi'),
        subtitle: 'Tindakan ini tidak dapat dibatalkan',
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}?',
        ),
        actions: [
          AppButton(
            text: 'Batal',
            style: AppButtonStyle.outline,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Hapus',
            style: AppButtonStyle.secondary, // Accent/Amber/Red style
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(transactionProvider.notifier)
                  .deleteTransaction(tx.id);
              if (success) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi berhasil dihapus'),
                    backgroundColor: AppTheme.colorSuccess,
                  ),
                );
              }
            },
          ),
        ],
      );
    }

    void showTransactionDetail(TransactionModel tx) {
      final isIncome = tx.isIncome;
      AppModal.show(
        context: context,
        title: Text(
          'Detail Transaksi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transaction type and Date header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  status: isIncome ? 'approved' : 'rejected',
                  label: isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                ),
                Text(
                  Formatter.formatTanggal(tx.transactionDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Large Money Amount
            Text('Nominal Uang:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            MoneyText(
              amount: tx.amount,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              styleType: isIncome
                  ? MoneyTextStyleType.debit
                  : MoneyTextStyleType.credit,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),

            // Detail fields (In premium side-by-side row detail layout)
            _buildDetailRow('Kategori', tx.category),
            _buildDetailRow('Keterangan', tx.description ?? '-'),
            _buildDetailRow(
              'Proyek',
              tx.projectName ?? 'Umum (Tidak terikat proyek)',
            ),
            _buildDetailRow('Dicatat Oleh', tx.creatorName ?? 'Umum'),
            _buildDetailRow(
              'Waktu Entri',
              Formatter.formatTanggal(tx.createdAt),
            ),
            _buildDetailRow(
              'Status Persetujuan',
              tx.status == 'approved'
                  ? 'Disetujui'
                  : (tx.status == 'rejected'
                        ? 'Ditolak'
                        : 'Menunggu Persetujuan'),
            ),
            if (tx.approverName != null) ...[
              _buildDetailRow('Disetujui Oleh', tx.approverName!),
              _buildDetailRow(
                'Waktu Persetujuan',
                Formatter.formatTanggal(tx.approvedAt!),
              ),
            ],

            if (tx.receiptUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                'Bukti Transaksi',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              tx.receiptUrl!.toLowerCase().contains('.pdf')
                  ? AppButton(
                      text: 'Buka Berkas PDF',
                      style: AppButtonStyle.outline,
                      icon: Icons.picture_as_pdf_outlined,
                      onPressed: () async {
                        final uri = Uri.parse(tx.receiptUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    )
                  : GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InteractiveViewer(
                                  child: ClipRRect(
                                    borderRadius: AppRadius.radiusMd,
                                    child: Image.network(
                                      tx.receiptUrl!,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withAlpha(
                                      120,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        radius: AppRadius.md,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.radiusMd,
                            image: DecorationImage(
                              image: NetworkImage(tx.receiptUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ],
        ),
        actions: [
          AppButton(
            text: 'Tutup',
            style: AppButtonStyle.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          if (canModify) ...[
            const SizedBox(width: 8),
            AppButton(
              text: 'Ubah',
              style: AppButtonStyle.primary,
              onPressed: () {
                Navigator.pop(context);
                showTransactionForm(transaction: tx);
              },
            ),
          ],
        ],
      );
    }

    Widget buildFilterPanel() {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saring Transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // Responsif Baris filter
            isDesktop
                ? Row(
                    children: [
                      // Filter Proyek
                      Expanded(child: _buildProjectDropdown(projects)),
                      const SizedBox(width: 12),
                      // Filter Tipe
                      Expanded(child: _buildTypeDropdown()),
                      const SizedBox(width: 12),
                      // Filter Kategori
                      Expanded(child: _buildCategoryDropdown()),
                    ],
                  )
                : Column(
                    children: [
                      _buildProjectDropdown(projects),
                      const SizedBox(height: 12),
                      _buildTypeDropdown(),
                      const SizedBox(height: 12),
                      _buildCategoryDropdown(),
                    ],
                  ),
          ],
        ),
      );
    }

    Widget buildDesktopTable() {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: AppColors.divider.withAlpha(80),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                outline: AppColors.divider.withAlpha(80),
                outlineVariant: AppColors.divider.withAlpha(80),
              ),
            ),
            child: DataTable(
              columnSpacing: 32,
              columns: [
              DataColumn(
                label: Text(
                  'Tanggal',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Debit (Masuk)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Kredit (Keluar)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Kategori',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Proyek',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Keterangan',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Dicatat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Aksi',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: filteredTxs.map((tx) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(Formatter.formatTanggalPendek(tx.transactionDate)),
                  ),
                  // Debit (Masuk)
                  DataCell(
                    Text(
                      tx.isIncome ? Formatter.formatRupiah(tx.amount) : '-',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome
                            ? AppTheme.colorSuccess
                            : AppTheme.textLight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // Kredit (Keluar)
                  DataCell(
                    Text(
                      !tx.isIncome ? Formatter.formatRupiah(tx.amount) : '-',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: !tx.isIncome
                            ? AppTheme.colorError
                            : AppTheme.textLight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  DataCell(Text(tx.category)),
                  DataCell(Text(tx.projectName ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tx.receiptUrl != null) ...[
                          const Icon(
                            Icons.attachment_outlined,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            tx.description ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(tx.creatorName ?? 'Umum')),
                  DataCell(_buildStatusBadge(tx.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue,
                          ),
                          onPressed: () => showTransactionDetail(tx),
                        ),
                        if (canModify)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                showTransactionForm(transaction: tx),
                          ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => confirmDeleteTransaction(tx),
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
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: filteredTxs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = filteredTxs[index];
          return AppCard(
            padding: EdgeInsets.zero,
            onTap: () => showTransactionDetail(tx),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: tx.isIncome
                        ? AppTheme.colorSuccess.withAlpha(26)
                        : AppTheme.colorError.withAlpha(26),
                    foregroundColor: tx.isIncome
                        ? AppTheme.colorSuccess
                        : AppTheme.colorError,
                    child: Icon(
                      tx.isIncome
                          ? Icons.account_balance_wallet_rounded
                          : Icons.receipt_long_rounded,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.description?.isNotEmpty == true
                                    ? tx.description!
                                    : tx.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (tx.receiptUrl != null) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.attachment_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Formatter.formatTanggalPendek(tx.transactionDate),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (tx.projectName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(
                                    UIConstants.rMax,
                                  ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoneyText(
                        amount: tx.amount,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        styleType: tx.isIncome
                            ? MoneyTextStyleType.debit
                            : MoneyTextStyleType.credit,
                        showSign: true,
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: tx.status),
                      if (canModify) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => showTransactionForm(transaction: tx),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: AppTheme.textLight,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => confirmDeleteTransaction(tx),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppTheme.colorError,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (activeFoundation != null) {
                  await ref
                      .read(transactionProvider.notifier)
                      .loadTransactions(activeFoundation.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header daftar & Tombol catat
                    isDesktop
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaksi Keuangan',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A2A25),
                                    ),
                                  ),
                                  Text(
                                    'Riwayat pencatatan keluar masuk uang yayasan.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7F79),
                                    ),
                                  ),
                                ],
                              ),
                              if (canModify)
                                ElevatedButton.icon(
                                  onPressed: () => showTransactionForm(),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Catat Uang'),
                                ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Transaksi Keuangan',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A2A25),
                                ),
                              ),
                              Text(
                                'Riwayat pencatatan keluar masuk uang yayasan.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7F79),
                                ),
                              ),
                              if (canModify) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => showTransactionForm(),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Catat Uang'),
                                ),
                              ],
                            ],
                          ),
                    const SizedBox(height: 20),

                    // Filter Panel
                    buildFilterPanel(),
                    const SizedBox(height: 20),

                    // Konten Tabel / List
                    if (filteredTxs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada transaksi yang cocok dengan filter.',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      isDesktop ? buildDesktopTable() : buildMobileList(),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Dropdown Project untuk filter
  Widget _buildProjectDropdown(List<dynamic> projects) {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedProjectId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Proyek',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Proyek')),
        ...projects.map((proj) {
          return DropdownMenuItem(value: proj.id, child: Text(proj.name));
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedProjectId = value;
        });
      },
    );
  }

  // Widget Dropdown Tipe untuk filter
  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tipe',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Tipe')),
        DropdownMenuItem(
          value: 'income',
          child: Text('Pemasukan (Uang Masuk)'),
        ),
        DropdownMenuItem(
          value: 'expense',
          child: Text('Pengeluaran (Uang Keluar)'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
    );
  }

  // Widget Dropdown Kategori untuk filter
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: _allCategories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(cat == 'all' ? 'Semua Kategori' : cat),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  // Widget Baris Detail Transaksi di dialog detail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
