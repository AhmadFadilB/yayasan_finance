# Excel Export (Ekspor Laporan Excel)

## Overview
Fitur Excel Export memungkinkan pengurus yayasan (khususnya bendahara) untuk mengunduh laporan ringkasan dan rincian transaksi keuangan dalam format berkas spreadsheet (.xlsx). Laporan yang diekspor disesuaikan secara dinamis berdasarkan filter rentang tanggal dan filter proyek yang sedang aktif pada layar laporan aplikasi.

Laporan Excel yang dihasilkan terformat secara rapi dengan warna latar, perataan data, ukuran font yang disesuaikan, serta lebar kolom otomatis agar siap digunakan untuk analisis internal atau pelaporan formal.

---

## Architecture & Code Structure

### 1. Cross-Platform File Saver
Untuk mendukung penyimpanan file di berbagai platform tanpa crash kompilasi, digunakan *Conditional Export* di Dart:
- **Wrapper:** [excel_saver.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_saver.dart)
  - Mengekspor file stub atau file implementasi platform spesifik secara dinamis.
- **Stub:** [excel_saver_stub.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_saver_stub.dart)
  - Antarmuka dasar pelempar pengecualian platform.
- **Web (Chrome/Browser):** [excel_saver_web.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_saver_web.dart)
  - Memicu pengunduhan file spreadsheet di browser menggunakan Blob URL dan elemen jangkar HTML5.
- **Mobile/Desktop:** [excel_saver_mobile.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_saver_mobile.dart)
  - Menyimpan file ke dalam direktori lokal dokumen aplikasi menggunakan pustaka `path_provider`.

### 2. Excel Generator Utility
- **Generator:** [excel_report_generator.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_report_generator.dart)
  - Utilitas utama untuk membuat dokumen workbook baru menggunakan package `excel`.
  - Berisi logika penulisan judul laporan, meta deskripsi periode, blok ringkasan keuangan, header tabel, dan iterasi penulisan baris transaksi.

### 3. UI Layer
- **Layar Laporan:** [report_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/screens/report_screen.dart)
  - Menghubungkan tombol **"Ekspor Excel"** pada summary panel untuk memicu pembuatan spreadsheet.

---

## Data Model / Database Schema

Spreadsheet Excel yang dihasilkan tersusun atas:
1.  **Header Informasi:**
    *   Judul: "LAPORAN KEUANGAN YAYASAN"
    *   Nama Yayasan
    *   Periode Laporan
    *   Nama Proyek (jika terfilter)
2.  **Blok Ringkasan Keuangan:**
    *   Total Pemasukan (dalam Rp)
    *   Total Pengeluaran (dalam Rp)
    *   Saldo Bersih (dalam Rp)
3.  **Tabel Rincian Transaksi:**
    *   Kolom: `No`, `Tanggal`, `Tipe`, `Kategori Akun`, `Proyek`, `Keterangan`, `Nominal (Rp)`

---

## UI & User Interaction

1.  **Filter Kriteria Laporan:** Pengguna menyesuaikan rentang tanggal mulai, tanggal akhir, serta proyek terkait di layar Laporan.
2.  **Tombol Ekspor Excel:** Terletak berdampingan dengan tombol "Ekspor PDF" di panel ringkasan dengan tema warna hijau tua khas Excel (`Color(0xFF1B5E20)`).
3.  **Proses Unduh Otomatis:** Setelah tombol ditekan, browser akan langsung mendownload berkas Excel dengan penamaan otomatis: `Laporan_Keuangan_<Nama_Yayasan>_<YYYYMMDD>.xlsx`.

---

## Verification / How to Test

### Pengujian Otomatis
Verifikasi keselarasan dependensi dan kompilasi platform silang dengan menjalankan perintah analisis:
```bash
flutter analyze
```

### Pengujian Manual
1.  Jalankan aplikasi di browser Chrome (`flutter run -d chrome`).
2.  Buka menu **Laporan**.
3.  Ubah kriteria tanggal filter transaksi.
4.  Klik tombol **Ekspor Excel**.
5.  Buka berkas unduhan spreadsheet di Microsoft Excel, Google Sheets, atau aplikasi pembaca xlsx lainnya.
6.  Verifikasi bahwa total pemasukan, total pengeluaran, saldo bersih, dan baris detail transaksi tercatat secara akurat sesuai pratinjau data di layar.
