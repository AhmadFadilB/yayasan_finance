import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/transaction_form_dialog.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _selectedProjectId;
  String _selectedType = 'all'; // 'all', 'income', 'expense'
  String _selectedCategory = 'all'; // 'all' or categories

  final List<String> _allCategories = const [
    'all', 'Donasi', 'Wakaf', 'Bantuan', 'Operasional', 'Konsumsi', 'Transport', 'Lainnya'
  ];

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'approved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        text = 'Disetujui';
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        text = 'Tertunda';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        text = 'Ditolak';
        break;
      default:
        bgColor = Colors.grey.withAlpha(26);
        textColor = Colors.grey[800]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
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
      showDialog(
        context: context,
        builder: (_) => TransactionFormDialog(transaction: transaction),
      );
    }

    void confirmDeleteTransaction(TransactionModel tx) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hapus Transaksi'),
            content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.description ?? tx.category}" senilai ${Formatter.formatRupiah(tx.amount)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  final success = await ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi berhasil dihapus!')),
                    );
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    void showTransactionDetail(TransactionModel tx) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Detail Transaksi',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lencana Pemasukan/Pengeluaran
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: tx.isIncome ? const Color(0xFF0D5C46).withAlpha(26) : const Color(0xFFE53935).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 14,
                              color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tx.isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatter.formatTanggal(tx.transactionDate),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Nominal Uang
                  Text(
                    'Nominal Uang:',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    Formatter.formatRupiah(tx.amount),
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategori & Keterangan
                  _buildDetailRow('Kategori', tx.category),
                  _buildDetailRow('Keterangan', tx.description ?? '-'),
                  _buildDetailRow('Proyek', tx.projectName ?? 'Umum (Tidak terikat proyek)'),
                  _buildDetailRow('Dicatat Oleh', tx.creatorName ?? 'Umum'),
                  _buildDetailRow('Waktu Entri', Formatter.formatTanggal(tx.createdAt)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Persetujuan',
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(tx.status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tx.approverName != null) ...[
                    _buildDetailRow('Disetujui Oleh', tx.approverName!),
                    _buildDetailRow('Waktu Persetujuan', Formatter.formatTanggal(tx.approvedAt!)),
                  ],
                  if (tx.receiptUrl != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Bukti Transaksi',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    tx.receiptUrl!.toLowerCase().contains('.pdf')
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(tx.receiptUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Buka Berkas PDF'),
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
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            tx.receiptUrl!,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withAlpha(120),
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withAlpha(50)),
                                image: DecorationImage(
                                  image: NetworkImage(tx.receiptUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              if (canModify)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showTransactionForm(transaction: tx);
                  },
                  child: const Text('Ubah'),
                ),
            ],
          );
        },
      );
    }

    Widget buildFilterPanel() {
      return Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saring Transaksi',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
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
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 32,
            columns: [
              DataColumn(label: Text('Tanggal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tipe', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nominal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Proyek', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Dicatat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
            ],
            rows: filteredTxs.map((tx) {
              return DataRow(
                cells: [
                  DataCell(Text(Formatter.formatTanggalPendek(tx.transactionDate))),
                  DataCell(
                    Icon(
                      tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                      size: 18,
                    ),
                  ),
                  DataCell(
                    Text(
                      Formatter.formatRupiah(tx.amount),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
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
                          const Icon(Icons.attachment_outlined, size: 16, color: Color(0xFF0D5C46)),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(tx.description ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                          icon: const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                          onPressed: () => showTransactionDetail(tx),
                        ),
                        if (canModify)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                            onPressed: () => showTransactionForm(transaction: tx),
                          ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showTransactionDetail(tx),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tx.isIncome ? const Color(0xFF0D5C46).withAlpha(18) : const Color(0xFFE53935).withAlpha(18),
                      foregroundColor: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                      child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward),
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
                                  tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1A2A25),
                                  ),
                                ),
                              ),
                              if (tx.receiptUrl != null) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.attachment_outlined, size: 16, color: Color(0xFF0D5C46)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                Formatter.formatTanggalPendek(tx.transactionDate),
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                              ),
                              if (tx.projectName != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${tx.isIncome ? '+' : '-'}${Formatter.formatRupiah(tx.amount)}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(tx.status),
                        if (canModify) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => showTransactionForm(transaction: tx),
                                child: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => confirmDeleteTransaction(tx),
                                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
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
                  await ref.read(transactionProvider.notifier).loadTransactions(activeFoundation.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header daftar & Tombol catat
                    Row(
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
                              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada transaksi yang cocok dengan filter.',
                                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
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
      value: _selectedProjectId,
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
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Tipe',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Tipe')),
        DropdownMenuItem(value: 'income', child: Text('Pemasukan (Uang Masuk)')),
        DropdownMenuItem(value: 'expense', child: Text('Pengeluaran (Uang Keluar)')),
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
      value: _selectedCategory,
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
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2A25),
            ),
          ),
        ],
      ),
    );
  }
}
