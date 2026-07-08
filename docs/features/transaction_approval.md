# Transaction Approval Workflow (Alur Persetujuan Transaksi)

## Overview
Alur Persetujuan Transaksi (Approval Workflow) memberikan kontrol tata kelola keuangan yang ketat bagi yayasan. Fitur ini memastikan bahwa setiap pengeluaran dana di atas nominal tertentu harus diperiksa dan disetujui secara resmi oleh Pimpinan/Ketua Yayasan (peran `admin`) sebelum memotong saldo yayasan secara digital di sistem keuangan.

Fitur ini dirancang khusus untuk mematuhi prinsip akuntabilitas nirlaba dan menghindari penyalahgunaan wewenang.

---

## Aturan Status Transaksi (Business Logic)

Setiap transaksi baru yang dimasukkan ke sistem akan diberikan status awal (`status`) secara otomatis berdasarkan aturan berikut:

1.  **Semua Transaksi Uang Masuk (Income):**
    *   Otomatis berstatus **Disetujui (`approved`)** karena tidak memotong dana yayasan.
2.  **Transaksi Uang Keluar (Expense) di bawah Rp1.000.000:**
    *   Otomatis berstatus **Disetujui (`approved`)** untuk kelancaran operasional harian yang bernominal kecil.
3.  **Transaksi Uang Keluar (Expense) sebesar Rp1.000.000 ke atas:**
    *   Jika dicatat oleh **Bendahara (`bendahara`)**: Berstatus **Tertunda (`pending`)** dan membutuhkan persetujuan admin.
    *   Jika dicatat oleh **Pimpinan (`admin`)**: Otomatis berstatus **Disetujui (`approved`)** karena admin adalah pemegang otoritas persetujuan.

---

## Dampak Terhadap Laporan Keuangan

Transaksi yang berstatus selain `approved` (`pending` / `rejected`) **tidak akan dihitung** ke dalam:
-   Ringkasan neraca saldo di Dasbor utama.
-   Kalkulasi total pemasukan/pengeluaran proyek yayasan.
-   Diagram visual (chart) keuangan.
-   Laporan cetak PDF maupun spreadsheet Excel (XLSX).

Ini memastikan laporan keuangan yayasan selalu akurat dan hanya mencerminkan transaksi yang sah.

---

## Architecture & Code Structure

### 1. Database Schema
-   **Skema Kueri:** [approval_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/approval_schema.sql)
    -   Menambahkan kolom `status` (`text` dengan check constraint `pending`, `approved`, `rejected`), `approved_by` (`uuid`), dan `approved_at` (`timestamptz`) ke tabel `public.transactions`.
    -   Menetapkan RLS policy agar admin dapat mengubah semua transaksi dan bendahara hanya dapat mengupdate transaksi pending mereka sendiri.

### 2. Flutter Feature Layer
-   **Model:** [transaction_model.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/models/transaction_model.dart)
    -   Memuat properti `status`, `approvedBy`, `approvedAt`, dan `approverName` serta pemetaan data JSON.
-   **Provider:** [transaction_provider.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/providers/transaction_provider.dart)
    -   Mengalokasikan status awal secara dinamis saat `addTransaction` / `updateTransaction`.
    -   Menambahkan metode `approveTransaction` dan `rejectTransaction` untuk otorisasi admin.
-   **Layar Persetujuan:** [approval_list_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/screens/approval_list_screen.dart)
    -   Layar khusus admin untuk melihat seluruh pengajuan pengeluaran berstatus `pending` lengkap dengan info nominal, pengaju, bukti lampiran (jika ada), serta tombol aksi **Setujui** dan **Tolak**.
-   **Bilah Navigasi:** [main_navigation_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/dashboard/screens/main_navigation_screen.dart)
    -   Menampilkan tab menu **Persetujuan** (`Icons.rule`) secara dinamis hanya untuk pengguna dengan peran `admin`.

---

## Verification / How to Test

### Pengujian Otomatis
Lakukan analisis statis untuk memastikan kode terbebas dari kesalahan kompilasi:
```bash
flutter analyze
```

### Pengujian Manual
1.  Jalankan kueri SQL di berkas [approval_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/approval_schema.sql) di panel Supabase Dashboard SQL Editor.
2.  Buka aplikasi dan masuk sebagai **Bendahara**:
    -   Catat pengeluaran operasional bernilai Rp500.000. Pastikan status langsung **Disetujui**.
    -   Catat pengeluaran bantuan bernilai Rp1.200.000. Pastikan status menjadi **Tertunda**.
    -   Buka dasbor dan verifikasi saldo tidak berkurang oleh transaksi Rp1.200.000 tersebut.
3.  Masuk sebagai **Pimpinan (Admin)**:
    -   Verifikasi menu **Persetujuan** muncul di bilah navigasi.
    -   Buka menu tersebut, pilih transaksi Rp1.200.000, lalu klik **Setujui**.
    -   Buka dasbor dan pastikan saldo berkurang secara realtime dan transaksi berpindah status menjadi **Disetujui**.
4.  Cek rincian detail transaksi tersebut untuk memverifikasi nama penyetuju dan waktu persetujuan tertera rapi.
