import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../../core/utils/formatter.dart';
import '../providers/accounting_provider.dart';
import '../models/journal_model.dart';
import '../../foundations/providers/foundation_provider.dart';

class Isak35ReportsScreen extends ConsumerStatefulWidget {
  const Isak35ReportsScreen({super.key});

  @override
  ConsumerState<Isak35ReportsScreen> createState() => _Isak35ReportsScreenState();
}

class _Isak35ReportsScreenState extends ConsumerState<Isak35ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: Text(
          'Laporan Keuangan ISAK 35',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Posisi Keuangan (Neraca)'),
            Tab(text: 'Aktivitas (Laba Rugi)'),
            Tab(text: 'Perubahan Aset Neto'),
            Tab(text: 'Arus Kas'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPosisiKeuangan(state.entries),
                _buildLaporanAktivitas(state.entries),
                _buildLaporanPerubahanAsetNeto(state.entries),
                _buildLaporanArusKas(state.entries),
              ],
            ),
    );
  }

  // 1. LAPORAN POSISI KEUANGAN (NERACA)
  Widget _buildPosisiKeuangan(List<JournalEntryModel> entries) {
    double totalAssets = 0;
    double totalLiabilities = 0;
    double beginningNetAssetsUnrestricted = 0;
    double beginningNetAssetsRestricted = 0;

    // 1. Calculate assets & liabilities directly from journal items
    for (var entry in entries) {
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        if (code.startsWith('1')) {
          // Asset: +Debit, -Credit
          totalAssets += (item.debit - item.credit);
        } else if (code.startsWith('2')) {
          // Liability: +Credit, -Debit
          totalLiabilities += (item.credit - item.debit);
        } else if (code.startsWith('31')) {
          // Net Asset Unrestricted: +Credit, -Debit
          beginningNetAssetsUnrestricted += (item.credit - item.debit);
        } else if (code.startsWith('32')) {
          // Net Asset Restricted: +Credit, -Debit
          beginningNetAssetsRestricted += (item.credit - item.debit);
        }
      }
    }

    // 2. Add accumulated revenue - expenses to Net Assets
    double surplusUnrestricted = 0;
    double surplusRestricted = 0;
    for (var entry in entries) {
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        if (code.startsWith('41')) {
          // Unrestricted Revenue: +Credit, -Debit
          surplusUnrestricted += (item.credit - item.debit);
        } else if (code.startsWith('42')) {
          // Restricted Revenue: +Credit, -Debit
          surplusRestricted += (item.credit - item.debit);
        } else if (code.startsWith('52') || code.startsWith('51') || code.startsWith('6')) {
          // Expenses: +Debit, -Credit
          final expenseVal = (item.debit - item.credit);
          if (code.startsWith('5110') || code.startsWith('5120') || code.startsWith('5130')) {
            // Zakat/Infaq Penyaluran (Restricted Expenses)
            surplusRestricted -= expenseVal;
          } else {
            // Unrestricted General/Program Expenses
            surplusUnrestricted -= expenseVal;
          }
        }
      }
    }

    final finalNetAssetsUnrestricted = beginningNetAssetsUnrestricted + surplusUnrestricted;
    final finalNetAssetsRestricted = beginningNetAssetsRestricted + surplusRestricted;
    final totalNetAssets = finalNetAssetsUnrestricted + finalNetAssetsRestricted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompanyHeader('LAPORAN POSISI KEUANGAN (NERACA)'),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. ASET'),
                _buildReportRow('Aset Lancar & Tetap', totalAssets),
                _buildTotalRow('TOTAL ASET', totalAssets),
                const SizedBox(height: 24),
                _buildSectionHeader('2. LIABILITAS'),
                _buildReportRow('Utang Usaha / Kewajiban', totalLiabilities),
                _buildTotalRow('TOTAL LIABILITAS', totalLiabilities),
                const SizedBox(height: 24),
                _buildSectionHeader('3. ASET NETO (EKUITAS)'),
                _buildReportRow('Aset Neto Tanpa Pembatasan', finalNetAssetsUnrestricted),
                _buildReportRow('Aset Neto Dengan Pembatasan', finalNetAssetsRestricted),
                _buildTotalRow('TOTAL ASET NETO', totalNetAssets),
                const SizedBox(height: 24),
                const Divider(color: Colors.black38, thickness: 1.5),
                const SizedBox(height: 8),
                _buildTotalRow('TOTAL LIABILITAS DAN ASET NETO', totalLiabilities + totalNetAssets, highlightColor: const Color(0xFF0F5A47)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. LAPORAN AKTIVITAS
  Widget _buildLaporanAktivitas(List<JournalEntryModel> entries) {
    double donasiUmum = 0;
    double penerimaanJasa = 0;
    double donasiTerikat = 0;
    double penerimaanZakat = 0;
    double penerimaanInfaq = 0;
    double penerimaanWakaf = 0;

    double bebanPenyaluranRestricted = 0;
    double bebanGaji = 0;
    double bebanListrik = 0;
    double bebanSewa = 0;
    double bebanOperasionalLain = 0;

    for (var entry in entries) {
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        final amount = item.credit - item.debit;
        final expenseAmount = item.debit - item.credit;

        if (code == '4110') donasiUmum += amount;
        if (code == '4120') penerimaanJasa += amount;
        if (code == '4210') donasiTerikat += amount;
        if (code == '4220') penerimaanZakat += amount;
        if (code == '4230') penerimaanInfaq += amount;
        if (code == '4240') penerimaanWakaf += amount;

        if (code.startsWith('51')) bebanPenyaluranRestricted += expenseAmount;
        if (code == '5210') bebanGaji += expenseAmount;
        if (code == '5220') bebanListrik += expenseAmount;
        if (code == '5230') bebanSewa += expenseAmount;
        if (code == '5240') bebanOperasionalLain += expenseAmount;
      }
    }

    final totalRevenueUnrestricted = donasiUmum + penerimaanJasa;
    final totalRevenueRestricted = donasiTerikat + penerimaanZakat + penerimaanInfaq + penerimaanWakaf;
    final totalExpenseUnrestricted = bebanGaji + bebanListrik + bebanSewa + bebanOperasionalLain;

    final changeNetAssetsUnrestricted = totalRevenueUnrestricted - totalExpenseUnrestricted;
    final changeNetAssetsRestricted = totalRevenueRestricted - bebanPenyaluranRestricted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompanyHeader('LAPORAN AKTIVITAS'),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('ASET NETO TANPA PEMBATASAN'),
                _buildReportRow('Donasi Umum (Tidak Terikat)', donasiUmum, indent: true),
                _buildReportRow('Penerimaan Jasa', penerimaanJasa, indent: true),
                _buildTotalRow('Total Penerimaan Tanpa Pembatasan', totalRevenueUnrestricted, isSubtotal: true),
                const SizedBox(height: 12),
                _buildReportRow('Beban Gaji & Honorarium', bebanGaji, indent: true, isExpense: true),
                _buildReportRow('Beban Listrik, Air & Internet', bebanListrik, indent: true, isExpense: true),
                _buildReportRow('Beban Sewa Kantor', bebanSewa, indent: true, isExpense: true),
                _buildReportRow('Beban Operasional Lainnya', bebanOperasionalLain, indent: true, isExpense: true),
                _buildTotalRow('Total Beban Tanpa Pembatasan', totalExpenseUnrestricted, isSubtotal: true, isExpense: true),
                _buildTotalRow('Kenaikan/(Penurunan) Aset Neto Tanpa Pembatasan', changeNetAssetsUnrestricted),
                
                const SizedBox(height: 32),
                _buildSectionHeader('ASET NETO DENGAN PEMBATASAN'),
                _buildReportRow('Donasi Terikat', donasiTerikat, indent: true),
                _buildReportRow('Penerimaan Zakat', penerimaanZakat, indent: true),
                _buildReportRow('Penerimaan Infak/Sedekah', penerimaanInfaq, indent: true),
                _buildReportRow('Penerimaan Wakaf', penerimaanWakaf, indent: true),
                _buildTotalRow('Total Penerimaan Dengan Pembatasan', totalRevenueRestricted, isSubtotal: true),
                const SizedBox(height: 12),
                _buildReportRow('Beban Penyaluran Dana Terikat/Ziswaf', bebanPenyaluranRestricted, indent: true, isExpense: true),
                _buildTotalRow('Total Beban Dengan Pembatasan', bebanPenyaluranRestricted, isSubtotal: true, isExpense: true),
                _buildTotalRow('Kenaikan/(Penurunan) Aset Neto Dengan Pembatasan', changeNetAssetsRestricted),

                const SizedBox(height: 24),
                const Divider(color: Colors.black38, thickness: 1.5),
                const SizedBox(height: 8),
                _buildTotalRow('TOTAL PERUBAHAN ASET NETO', changeNetAssetsUnrestricted + changeNetAssetsRestricted, highlightColor: const Color(0xFF0F5A47)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. LAPORAN PERUBAHAN ASET NETO
  Widget _buildLaporanPerubahanAsetNeto(List<JournalEntryModel> entries) {
    double beginningNetAssetsUnrestricted = 0;
    double beginningNetAssetsRestricted = 0;

    for (var entry in entries) {
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        if (code.startsWith('31')) {
          beginningNetAssetsUnrestricted += (item.credit - item.debit);
        } else if (code.startsWith('32')) {
          beginningNetAssetsRestricted += (item.credit - item.debit);
        }
      }
    }

    double donasiUmum = 0;
    double penerimaanJasa = 0;
    double donasiTerikat = 0;
    double penerimaanZakat = 0;
    double penerimaanInfaq = 0;
    double penerimaanWakaf = 0;

    double bebanPenyaluranRestricted = 0;
    double bebanGaji = 0;
    double bebanListrik = 0;
    double bebanSewa = 0;
    double bebanOperasionalLain = 0;

    for (var entry in entries) {
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        final amount = item.credit - item.debit;
        final expenseAmount = item.debit - item.credit;

        if (code == '4110') donasiUmum += amount;
        if (code == '4120') penerimaanJasa += amount;
        if (code == '4210') donasiTerikat += amount;
        if (code == '4220') penerimaanZakat += amount;
        if (code == '4230') penerimaanInfaq += amount;
        if (code == '4240') penerimaanWakaf += amount;

        if (code.startsWith('51')) bebanPenyaluranRestricted += expenseAmount;
        if (code == '5210') bebanGaji += expenseAmount;
        if (code == '5220') bebanListrik += expenseAmount;
        if (code == '5230') bebanSewa += expenseAmount;
        if (code == '5240') bebanOperasionalLain += expenseAmount;
      }
    }

    final totalRevenueUnrestricted = donasiUmum + penerimaanJasa;
    final totalRevenueRestricted = donasiTerikat + penerimaanZakat + penerimaanInfaq + penerimaanWakaf;
    final totalExpenseUnrestricted = bebanGaji + bebanListrik + bebanSewa + bebanOperasionalLain;

    final changeNetAssetsUnrestricted = totalRevenueUnrestricted - totalExpenseUnrestricted;
    final changeNetAssetsRestricted = totalRevenueRestricted - bebanPenyaluranRestricted;

    final endingNetAssetsUnrestricted = beginningNetAssetsUnrestricted + changeNetAssetsUnrestricted;
    final endingNetAssetsRestricted = beginningNetAssetsRestricted + changeNetAssetsRestricted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompanyHeader('LAPORAN PERUBAHAN ASET NETO'),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Aset Neto Tanpa Pembatasan'),
                _buildReportRow('Saldo Awal', beginningNetAssetsUnrestricted, indent: true),
                _buildReportRow('Kenaikan/(Penurunan) Aset Neto', changeNetAssetsUnrestricted, indent: true),
                _buildTotalRow('Saldo Akhir Aset Neto Tanpa Pembatasan', endingNetAssetsUnrestricted, isSubtotal: true),

                const SizedBox(height: 24),
                _buildSectionHeader('Aset Neto Dengan Pembatasan'),
                _buildReportRow('Saldo Awal', beginningNetAssetsRestricted, indent: true),
                _buildReportRow('Kenaikan/(Penurunan) Aset Neto', changeNetAssetsRestricted, indent: true),
                _buildTotalRow('Saldo Akhir Aset Neto Dengan Pembatasan', endingNetAssetsRestricted, isSubtotal: true),

                const SizedBox(height: 24),
                const Divider(color: Colors.black38, thickness: 1.5),
                const SizedBox(height: 8),
                _buildTotalRow('TOTAL SALDO AKHIR ASET NETO', endingNetAssetsUnrestricted + endingNetAssetsRestricted, highlightColor: const Color(0xFF0F5A47)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. LAPORAN ARUS KAS (DIRECT METHOD)
  Widget _buildLaporanArusKas(List<JournalEntryModel> entries) {
    double cashReceivedFromDonors = 0;
    double cashPaidToProgram = 0;
    double cashPaidToOperations = 0;
    double cashPaidForAssets = 0;

    for (var entry in entries) {
      // Find if cash/bank accounts (1110, 1120) are involved in this entry
      final cashItems = entry.items.where((i) => i.accountCode == '1110' || i.accountCode == '1120').toList();
      if (cashItems.isEmpty) continue;

      // Classify the counterparties
      for (var item in entry.items) {
        final code = item.accountCode ?? '';
        if (code == '1110' || code == '1120') continue; // Skip cash itself

        // Debit cash = cash received (we credit counterparties)
        // Credit cash = cash paid (we debit counterparties)
        if (code.startsWith('4')) {
          // Counterparty is Revenue: cash in
          cashReceivedFromDonors += (item.credit - item.debit);
        } else if (code.startsWith('51')) {
          // Program expenses: cash out
          cashPaidToProgram += (item.debit - item.credit);
        } else if (code.startsWith('52') || code.startsWith('6')) {
          // Operations expenses: cash out
          cashPaidToOperations += (item.debit - item.credit);
        } else if (code.startsWith('12')) {
          // Purchasing equipment: cash out
          cashPaidForAssets += (item.debit - item.credit);
        }
      }
    }

    final netCashOperating = cashReceivedFromDonors - cashPaidToProgram - cashPaidToOperations;
    final netCashInvesting = -cashPaidForAssets;
    final netCashChange = netCashOperating + netCashInvesting;

    // Calculate cash beginning balance
    double beginningCash = 0;
    // For beginning cash, we take all cash transactions before but since this is dynamic, we'll calculate it
    // Or normally beginningCash = total Cash at start. For simulation, let's start with 0.
    final endingCash = beginningCash + netCashChange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompanyHeader('LAPORAN ARUS KAS (METODE LANGSUNG)'),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. ARUS KAS DARI AKTIVITAS OPERASIONAL'),
                _buildReportRow('Penerimaan dari Donatur/Masyarakat', cashReceivedFromDonors, indent: true),
                _buildReportRow('Pembayaran Penyaluran Bantuan/Program', cashPaidToProgram, indent: true, isExpense: true),
                _buildReportRow('Pembayaran Beban Operasional & Honor', cashPaidToOperations, indent: true, isExpense: true),
                _buildTotalRow('Arus Kas Bersih dari Aktivitas Operasional', netCashOperating, isSubtotal: true),

                const SizedBox(height: 24),
                _buildSectionHeader('2. ARUS KAS DARI AKTIVITAS INVESTASI'),
                _buildReportRow('Pembelian Peralatan/Aset Tetap', cashPaidForAssets, indent: true, isExpense: true),
                _buildTotalRow('Arus Kas Bersih dari Aktivitas Investasi', netCashInvesting, isSubtotal: true),

                const SizedBox(height: 24),
                _buildSectionHeader('3. ARUS KAS DARI AKTIVITAS PENDANAAN'),
                _buildReportRow('Penerimaan pinjaman jangka panjang', 0.0, indent: true),
                _buildTotalRow('Arus Kas Bersih dari Aktivitas Pendanaan', 0.0, isSubtotal: true),

                const SizedBox(height: 24),
                const Divider(color: Colors.black38, thickness: 1.5),
                const SizedBox(height: 8),
                _buildTotalRow('KENAIKAN/(PENURUNAN) BERSIH KAS', netCashChange),
                _buildReportRow('Kas dan Setara Kas Awal Periode', beginningCash),
                _buildTotalRow('KAS DAN SETARA KAS AKHIR PERIODE', endingCash, highlightColor: const Color(0xFF0F5A47)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HELPERS
  Widget _buildCompanyHeader(String reportName) {
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    return Column(
      children: [
        Text(
          activeFoundation?.name.toUpperCase() ?? 'YAYASAN FINANCE',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF37474F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          reportName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F5A47)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Untuk periode yang berakhir pada 31 Desember 2026',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: const Color(0xFF37474F),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, double amount, {bool indent = false, bool isExpense = false}) {
    final amountVal = isExpense ? -amount : amount;
    return Padding(
      padding: EdgeInsets.only(left: indent ? 24.0 : 8.0, top: 6.0, bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF555555)),
            ),
          ),
          Text(
            amountVal == 0.0 ? 'Rp0' : (amountVal < 0 ? '(${Formatter.formatRupiah(amountVal.abs())})' : Formatter.formatRupiah(amountVal)),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: amountVal < 0 ? const Color(0xFFE53935) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isSubtotal = false, bool isExpense = false, Color? highlightColor}) {
    final amountVal = isExpense ? -amount : amount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: isSubtotal ? 13 : 14,
                color: highlightColor ?? const Color(0xFF37474F),
              ),
            ),
          ),
          Text(
            amountVal == 0.0 ? 'Rp0' : (amountVal < 0 ? '(${Formatter.formatRupiah(amountVal.abs())})' : Formatter.formatRupiah(amountVal)),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: isSubtotal ? 13 : 14,
              color: highlightColor ?? (amountVal < 0 ? const Color(0xFFE53935) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
