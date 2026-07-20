import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../core/utils/formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/empty_state_view.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../utils/pdf_report_generator.dart';
import '../utils/excel_report_generator.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // Tanggal 1 bulan ini
  DateTime _endDate = DateTime.now();
  String? _selectedProjectId;
  bool _isGeneratingPdf = false;

  Future<void> _pickDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportPdfReport(
    String foundationName,
    List<dynamic> filteredTxs,
    double totalIncome,
    double totalExpense,
    String? projectName,
  ) async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final userProfile = ref.read(authProvider).profile;
      final creatorName = userProfile?.name ?? 'Admin Keuangan';

      // Pastikan transaksi di-cast dengan benar ke TransactionModel
      final typedTxs = filteredTxs.map((e) => e as TransactionModel).toList();

      final pdfBytes = await PdfReportGenerator.generate(
        foundationName: foundationName,
        startDate: _startDate,
        endDate: _endDate,
        projectName: projectName,
        transactions: typedTxs,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        creatorName: creatorName,
      );

      // Jalankan dialog cetak / simpan bawaan sistem operasi (iOS/Android/macOS/Windows)
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'Laporan_Keuangan_${foundationName.replaceAll(" ", "_")}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final projects = ref.watch(projectProvider).projects;
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;

    if (activeFoundation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filter transaksi berdasarkan Rentang Tanggal dan Proyek
    final filteredTxs = transactionState.transactions.where((tx) {
      if (tx.status != 'approved') return false;
      // Bandingkan tanpa memperhatikan waktu (jam/menit)
      final txDate = DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day);
      final compareStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final compareEnd = DateTime(_endDate.year, _endDate.month, _endDate.day);

      final isWithinDate = (txDate.isAtSameMomentAs(compareStart) || txDate.isAfter(compareStart)) &&
          (txDate.isAtSameMomentAs(compareEnd) || txDate.isBefore(compareEnd));

      if (!isWithinDate) return false;

      if (_selectedProjectId != null && tx.projectId != _selectedProjectId) {
        return false;
      }

      return true;
    }).toList();

    // Hitung ringkasan
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in filteredTxs) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    // Ambil nama proyek yang terpilih
    String? selectedProjectName;
    if (_selectedProjectId != null) {
      selectedProjectName = projects.firstWhere((p) => p.id == _selectedProjectId).name;
    }

    // Urutkan kronologis (terlama ke terbaru) untuk menghitung saldo berjalan (running balance)
    final chronologicalTxs = List<TransactionModel>.from(filteredTxs)
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    final List<double> runningBalances = [];
    double currentBalance = 0;
    for (var tx in chronologicalTxs) {
      if (tx.isIncome) {
        currentBalance += tx.amount;
      } else {
        currentBalance -= tx.amount;
      }
      runningBalances.add(currentBalance);
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    Widget buildDesktopTable() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            // Header Tabel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(100), // Tanggal
                  1: FlexColumnWidth(2),    // Keterangan / Proyek
                  2: FlexColumnWidth(1),    // Debit
                  3: FlexColumnWidth(1),    // Kredit
                  4: FlexColumnWidth(1.2),  // Saldo
                },
                children: [
                  TableRow(
                    children: [
                       Text('Tanggal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF37474F), fontSize: 13)),
                      Text('Keterangan / Proyek', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF37474F), fontSize: 13)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Debit (Masuk)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF37474F), fontSize: 13)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Kredit (Keluar)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF37474F), fontSize: 13)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Saldo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF37474F), fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            // Isi Tabel
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chronologicalTxs.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final tx = chronologicalTxs[index];
                final runningBal = runningBalances[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(100),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1.2),
                    },
                    children: [
                      TableRow(
                        children: [
                          // Tanggal
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              Formatter.formatTanggalPendek(tx.transactionDate),
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7F79)),
                            ),
                          ),
                          // Keterangan / Proyek
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A2A25)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx.projectName ?? 'Umum',
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          // Uang Masuk
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                tx.isIncome ? Formatter.formatRupiah(tx.amount) : '-',
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: tx.isIncome ? AppTheme.colorSuccess : Colors.grey,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          // Uang Keluar
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                !tx.isIncome ? Formatter.formatRupiah(tx.amount) : '-',
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: !tx.isIncome ? AppTheme.colorError : Colors.grey,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          // Saldo
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                Formatter.formatRupiah(runningBal),
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: runningBal >= 0 ? AppTheme.colorSuccess : AppTheme.colorError,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    Widget buildMobileList() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chronologicalTxs.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
          itemBuilder: (context, index) {
            final tx = chronologicalTxs[index];
            final runningBal = runningBalances[index];
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: tx.isIncome ? AppTheme.colorSuccess.withAlpha(26) : AppTheme.colorError.withAlpha(26),
                foregroundColor: tx.isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
              ),
              title: Text(
                tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '${Formatter.formatTanggalPendek(tx.transactionDate)} • ${tx.projectName ?? "Umum"}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Uang Masuk / Keluar
                  Text(
                    '${tx.isIncome ? '+' : '-'}${Formatter.formatRupiah(tx.amount)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tx.isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tx.isIncome ? 'DEBIT' : 'KREDIT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: tx.isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Saldo Berjalan
                  Text(
                    'Saldo: ${Formatter.formatRupiah(runningBal)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Halaman
            Text(
              'Laporan Keuangan',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A2A25),
              ),
            ),
            Text(
              'Sesuaikan filter untuk membuat berkas cetak PDF laporan keuangan.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6B7F79),
              ),
            ),
            const SizedBox(height: 24),

            // Form Filter (Rentang Tanggal & Proyek)
            Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penyusunan Kriteria Laporan',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    isDesktop
                        ? Row(
                            children: [
                              // Tanggal Mulai
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                  ),
                                  onPressed: () => _pickDate(true),
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    'Mulai: ${Formatter.formatTanggalPendek(_startDate)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Tanggal Akhir
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                  ),
                                  onPressed: () => _pickDate(false),
                                  icon: const Icon(Icons.event),
                                  label: Text(
                                    'Akhir: ${Formatter.formatTanggalPendek(_endDate)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                ),
                                onPressed: () => _pickDate(true),
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  'Mulai: ${Formatter.formatTanggalPendek(_startDate)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                ),
                                onPressed: () => _pickDate(false),
                                icon: const Icon(Icons.event),
                                label: Text(
                                  'Akhir: ${Formatter.formatTanggalPendek(_endDate)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    // Dropdown Proyek
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedProjectId,
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Kotak Ringkasan & Tombol Cetak PDF
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan Laporan',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isGeneratingPdf
                                      ? null
                                      : () => _exportPdfReport(
                                            activeFoundation.name,
                                            filteredTxs,
                                            totalIncome,
                                            totalExpense,
                                            selectedProjectName,
                                          ),
                                  icon: _isGeneratingPdf
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.picture_as_pdf, size: 18),
                                  label: const Text('Ekspor PDF'),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await ExcelReportGenerator.generate(
                                      foundationName: activeFoundation.name,
                                      transactions: filteredTxs,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                      projectName: selectedProjectName,
                                    );
                                  },
                                  icon: const Icon(Icons.table_view_outlined, size: 18),
                                  label: const Text('Ekspor Excel'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan Laporan',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isGeneratingPdf
                                        ? null
                                        : () => _exportPdfReport(
                                              activeFoundation.name,
                                              filteredTxs,
                                              totalIncome,
                                              totalExpense,
                                              selectedProjectName,
                                            ),
                                    icon: _isGeneratingPdf
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.picture_as_pdf, size: 18),
                                    label: const Text('Ekspor PDF'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await ExcelReportGenerator.generate(
                                        foundationName: activeFoundation.name,
                                        transactions: filteredTxs,
                                        startDate: _startDate,
                                        endDate: _endDate,
                                        projectName: selectedProjectName,
                                      );
                                    },
                                    icon: const Icon(Icons.table_view_outlined, size: 18),
                                    label: const Text('Ekspor Excel'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),
                  isDesktop
                      ? Row(
                          children: [
                            // Total Pemasukan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pemasukan',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    Formatter.formatRupiah(totalIncome),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.colorSuccess,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Total Pengeluaran
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengeluaran',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    Formatter.formatRupiah(totalExpense),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.colorError,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Saldo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo Bersih',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    Formatter.formatRupiah(balance),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: balance >= 0 ? AppTheme.colorSuccess : AppTheme.colorError,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Total Pemasukan
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pemasukan',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  Formatter.formatRupiah(totalIncome),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colorSuccess,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Total Pengeluaran
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengeluaran',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  Formatter.formatRupiah(totalExpense),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colorError,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Saldo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Bersih',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  Formatter.formatRupiah(balance),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0 ? AppTheme.colorSuccess : AppTheme.colorError,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Daftar Pratinjau Transaksi Terfilter
            Text(
              'Pratinjau Rincian Laporan (${filteredTxs.length} Transaksi)',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A2A25)),
            ),
            const SizedBox(height: 16),

            if (filteredTxs.isEmpty)
              EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'Tidak ada transaksi',
                description: 'Tidak ada transaksi pada kriteria filter ini.',
              )
            else
              isDesktop ? buildDesktopTable() : buildMobileList(),
          ],
        ),
      ),
    );
  }
}
