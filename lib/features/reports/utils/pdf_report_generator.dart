import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../transactions/models/transaction_model.dart';

class PdfReportGenerator {
  // Menghasilkan dokumen PDF dan mengembalikan bytes berkas
  static Future<Uint8List> generate({
    required String foundationName,
    required DateTime startDate,
    required DateTime endDate,
    required String? projectName,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required String creatorName,
  }) async {
    final pdf = pw.Document();

    // Format Tanggal untuk Header
    final df = DateFormat('dd MMMM yyyy', 'id_ID');
    final filterRange = '${df.format(startDate)} - ${df.format(endDate)}';
    
    // Format mata uang rupiah
    String fmtIdr(double val) {
      final sign = val < 0 ? '-' : '';
      final absVal = val.abs().toInt();
      final formatter = NumberFormat('#,###', 'id_ID');
      return '$sign Rp ${formatter.format(absVal)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // 1. HEADER DOKUMEN
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEUANGAN YAYASAN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0D5C46'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      foundationName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (projectName != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Proyek: $projectName',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Rentang Laporan:',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#6B7F79')),
                    ),
                    pw.Text(
                      filterRange,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('#CCCCCC')),
            pw.SizedBox(height: 20),

            // 2. KOTAK RINGKASAN SALDO
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F7FBF9'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem(
                    title: 'TOTAL PEMASUKAN',
                    value: fmtIdr(totalIncome),
                    color: PdfColor.fromHex('#0D5C46'),
                  ),
                  pw.VerticalDivider(width: 1, color: PdfColor.fromHex('#E0E0E0')),
                  _buildSummaryItem(
                    title: 'TOTAL PENGELUARAN',
                    value: fmtIdr(totalExpense),
                    color: PdfColor.fromHex('#E53935'),
                  ),
                  pw.VerticalDivider(width: 1, color: PdfColor.fromHex('#E0E0E0')),
                  _buildSummaryItem(
                    title: 'SALDO BERSIH',
                    value: fmtIdr(totalIncome - totalExpense),
                    color: (totalIncome - totalExpense) >= 0 
                        ? PdfColor.fromHex('#0D5C46') 
                        : PdfColor.fromHex('#E53935'),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // 3. DAFTAR DETAIL TRANSAKSI
            pw.Text(
              'RINCIAN TRANSAKSI',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A2A25'),
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#EEEEEE'), width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#FFFFFF'),
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0D5C46'),
              ),
              rowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFFFFF'),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              headers: const [
                'Tanggal',
                'Tipe',
                'Kategori',
                'Proyek',
                'Keterangan',
                'Jumlah',
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(65),
                1: pw.FixedColumnWidth(60),
                2: pw.FixedColumnWidth(80),
                3: pw.FixedColumnWidth(90),
                4: pw.FixedColumnWidth(130),
                5: pw.FixedColumnWidth(90),
              },
              data: transactions.map((tx) {
                final dateStr = DateFormat('dd/MM/yyyy').format(tx.transactionDate);
                final typeStr = tx.isIncome ? 'Masuk' : 'Keluar';
                final amountStr = fmtIdr(tx.amount);
                return [
                  dateStr,
                  typeStr,
                  tx.category,
                  tx.projectName ?? '-',
                  tx.description ?? '-',
                  amountStr,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 48),

            // 4. SIGNATURE / PENANGGUNG JAWAB
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SizedBox(), // Spacer kiri
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Penanggung Jawab,',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#1A2A25')),
                    ),
                    pw.SizedBox(height: 48),
                    pw.Text(
                      creatorName,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Divider(thickness: 1, color: PdfColor.fromHex('#1A2A25')),
                    pw.Text(
                      'Yayasan Finance System',
                      style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#6B7F79')),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryItem({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#6B7F79'),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
