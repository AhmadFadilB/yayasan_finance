import 'package:intl/intl.dart';

class Formatter {
  // Format angka menjadi Rupiah (IDR)
  static String formatRupiah(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format tanggal menjadi format Indonesia (contoh: 28 Juni 2026)
  static String formatTanggal(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  // Format tanggal pendek (contoh: 28/06/2026)
  static String formatTanggalPendek(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format tanggal dari String (yyyy-MM-dd) ke DateTime
  static DateTime parseDateString(String dateStr) {
    return DateTime.parse(dateStr);
  }

  // Format DateTime ke string database (yyyy-MM-dd)
  static String toDbDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
