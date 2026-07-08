# Ekspor Laporan ke format Excel (XLSX)

## Overview
Fitur ini memungkinkan bendahara yayasan untuk mengekspor data laporan transaksi keuangan ke format Excel (.xlsx) untuk keperluan pengolahan data lanjutan, auditing, atau integrasi manual.

## Architecture & Code Structure
Fitur ini diimplementasikan di frontend Flutter menggunakan package `excel` untuk menghasilkan workbook, sheet, dan sel-sel tabel secara dinamis.

Dua utilitas laporan yang dibuat/dimodifikasi:
- [excel_report_generator.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/excel_report_generator.dart) - Membuat berkas workbook excel dari list transaksi.
- [pdf_report_generator.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/utils/pdf_report_generator.dart) - Melakukan ekspor data ke PDF (existing).

## Data Model / Database Schema
Tidak ada tabel database baru yang didefinisikan. Data diambil secara langsung dari tabel `transactions` yang sudah ada menggunakan query filter per proyek atau rentang tanggal.

## Verification / How to Test
1. Masuk ke halaman Laporan Keuangan di aplikasi.
2. Klik tombol "Ekspor ke Excel".
3. Pastikan file excel berhasil diunduh dan dapat dibuka dengan Microsoft Excel, Google Sheets, atau aplikasi sejenis dengan format tabel yang rapi.
