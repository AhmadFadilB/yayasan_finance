import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../transactions/models/transaction_model.dart';
import '../../../core/utils/formatter.dart';
import 'excel_saver.dart';

class ExcelReportGenerator {
  static Future<void> generate({
    required String foundationName,
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
    String? projectName,
  }) async {
    // 1. Inisialisasi Excel
    final excel = Excel.createExcel();
    final String sheetName = 'Laporan Keuangan';
    
    // Ganti nama Sheet1 default
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];
    
    // Styling umum
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1A2A25'),
    );
    
    final metaStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#6B7F79'),
    );
    
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#0D5C46'), // Emerald Green
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),       // White
      horizontalAlign: HorizontalAlign.Center,
    );
    
    final summaryTitleStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#ECEFF1'),
      fontColorHex: ExcelColor.fromHexString('#37474F'),
    );

    final summaryValueStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#0D5C46'),
    );

    // 2. Tulis Header Judul Laporan
    sheet.cell(CellIndex.indexByString("A1")).value = TextCellValue("LAPORAN KEUANGAN YAYASAN");
    sheet.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
    
    sheet.cell(CellIndex.indexByString("A2")).value = TextCellValue("Yayasan: $foundationName");
    sheet.cell(CellIndex.indexByString("A2")).cellStyle = metaStyle;
    
    final String periodStr = "Periode: ${Formatter.formatTanggal(startDate)} s.d ${Formatter.formatTanggal(endDate)}";
    sheet.cell(CellIndex.indexByString("A3")).value = TextCellValue(periodStr);
    sheet.cell(CellIndex.indexByString("A3")).cellStyle = metaStyle;
    
    if (projectName != null) {
      sheet.cell(CellIndex.indexByString("A4")).value = TextCellValue("Proyek: $projectName");
      sheet.cell(CellIndex.indexByString("A4")).cellStyle = metaStyle;
    }
    
    // 3. Hitung Ringkasan Keuangan
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    double netBalance = totalIncome - totalExpense;
    
    // 4. Tulis Ringkasan Keuangan (Blok Summary)
    sheet.cell(CellIndex.indexByString("A6")).value = TextCellValue("RINGKASAN KEUANGAN");
    sheet.cell(CellIndex.indexByString("A6")).cellStyle = CellStyle(bold: true, fontSize: 12);
    
    sheet.cell(CellIndex.indexByString("A7")).value = TextCellValue("Total Pemasukan");
    sheet.cell(CellIndex.indexByString("A7")).cellStyle = summaryTitleStyle;
    sheet.cell(CellIndex.indexByString("B7")).value = DoubleCellValue(totalIncome);
    sheet.cell(CellIndex.indexByString("B7")).cellStyle = summaryValueStyle;
    
    sheet.cell(CellIndex.indexByString("A8")).value = TextCellValue("Total Pengeluaran");
    sheet.cell(CellIndex.indexByString("A8")).cellStyle = summaryTitleStyle;
    sheet.cell(CellIndex.indexByString("B8")).value = DoubleCellValue(totalExpense);
    sheet.cell(CellIndex.indexByString("B8")).cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#C62828'));
    
    sheet.cell(CellIndex.indexByString("A9")).value = TextCellValue("Saldo Bersih");
    sheet.cell(CellIndex.indexByString("A9")).cellStyle = summaryTitleStyle;
    sheet.cell(CellIndex.indexByString("B9")).value = DoubleCellValue(netBalance);
    sheet.cell(CellIndex.indexByString("B9")).cellStyle = CellStyle(bold: true, fontColorHex: netBalance >= 0 ? ExcelColor.fromHexString('#0D5C46') : ExcelColor.fromHexString('#C62828'));
    
    // 5. Tulis Table Header Transaksi
    final headers = ['No', 'Tanggal', 'Tipe', 'Kategori Akun', 'Proyek', 'Keterangan', 'Nominal (Rp)'];
    const startRow = 11;
    
    for (var i = 0; i < headers.length; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow);
      sheet.cell(cellIndex).value = TextCellValue(headers[i]);
      sheet.cell(cellIndex).cellStyle = headerStyle;
    }
    
    // 6. Tulis Data Transaksi
    int rowOffset = startRow + 1;

    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final dateStr = Formatter.formatTanggalPendek(tx.transactionDate);
      final typeStr = tx.isIncome ? 'Uang Masuk' : 'Uang Keluar';
      
      final rowIdx = rowOffset + i;
      
      // No
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
      
      // Tanggal
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = TextCellValue(dateStr);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
      
      // Tipe
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = TextCellValue(typeStr);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        fontColorHex: tx.isIncome ? ExcelColor.fromHexString('#2E7D32') : ExcelColor.fromHexString('#C62828'),
      );
      
      // Kategori Akun
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = TextCellValue(tx.category);
      
      // Proyek
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = TextCellValue(tx.projectName ?? '-');
      
      // Keterangan
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = TextCellValue(tx.description ?? '-');
      
      // Nominal
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = DoubleCellValue(tx.amount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        bold: true,
        fontColorHex: tx.isIncome ? ExcelColor.fromHexString('#2E7D32') : ExcelColor.fromHexString('#C62828'),
      );
    }
    
    // Set column widths secara manual agar rapi (Auto-fit sederhana)
    sheet.setColumnWidth(0, 6);   // No
    sheet.setColumnWidth(1, 15);  // Tanggal
    sheet.setColumnWidth(2, 14);  // Tipe
    sheet.setColumnWidth(3, 25);  // Kategori Akun
    sheet.setColumnWidth(4, 25);  // Proyek
    sheet.setColumnWidth(5, 35);  // Keterangan
    sheet.setColumnWidth(6, 20);  // Nominal
    
    // 7. Simpan file
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final cleanFoundationName = foundationName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      final dateSuffix = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'Laporan_Keuangan_${cleanFoundationName}_$dateSuffix.xlsx';
      
      await saveAndLaunchFile(fileBytes, fileName);
    }
  }
}
