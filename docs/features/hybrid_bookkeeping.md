# Model Pembukuan Hibrida (Debit & Kredit)

## Overview
Model Pembukuan Hibrida menyelaraskan istilah transaksi pada aplikasi dengan standar akuntansi profesional menggunakan istilah **Debit (Uang Masuk)** dan **Kredit (Uang Keluar)**. 

Untuk mempermudah penggunaan oleh pengurus yayasan yang mungkin tidak memiliki latar belakang akuntansi mendalam, sistem di belakang layar (database Supabase) tetap menggunakan penyimpanan model *single-entry* yang sangat andal dan ringkas. Namun, pada antarmuka pengguna (UI/UX) dan laporan mutasi kas, data disajikan dalam format kolom Debit dan Kredit yang standar.

---

## Implementasi Visual & UI/UX

### 1. Form Input Transaksi (`TransactionFormDialog`)
*   Pilihan tipe transaksi menggunakan segmented button dengan label yang jelas:
    *   **Debit (Uang Masuk)**
    *   **Kredit (Uang Keluar)**
*   Label input jumlah uang diganti menjadi **Nominal Transaksi (Rp)**.

### 2. Daftar Transaksi Utama (`TransactionListScreen`)
*   **Desktop (Table):**
    Kolom `Tipe` dan `Nominal` yang sebelumnya tergabung didekonstruksi menjadi dua kolom terpisah:
    *   **Debit (Masuk):** Nominal pemasukan ditampilkan di kolom ini dengan teks tebal berwarna hijau.
    *   **Kredit (Keluar):** Nominal pengeluaran ditampilkan di kolom ini dengan teks tebal berwarna merah.
    *   Baris transaksi yang tidak cocok akan ditandai dengan strip (`-`).
*   **Mobile (List Card):**
    Di bawah visual nominal transaksi pada pojok kanan kartu, ditambahkan badge teks kecil penanda **`[DEBIT]`** (hijau) atau **`[KREDIT]`** (merah) untuk memberikan kejelasan aliran kas yang presisi.

### 3. Ringkasan Dasbor & Grafik
*   **Dashboard Cards:**
    *   `Total Pemasukan` $\rightarrow$ **Total Debit (Masuk)**
    *   `Total Pengeluaran` $\rightarrow$ **Total Kredit (Keluar)**
*   **Chart Legends & Tooltips:**
    *   Legenda warna dan tooltip pada diagram batang perbandingan (`FinancialChart`) dan diagram garis tren tahunan (`YearlyTrendChart`) diubah secara seragam menjadi **Debit** dan **Kredit**.

### 4. Pratinjau Laporan (`ReportScreen`)
*   Header kolom tabel desktop diselaraskan menjadi **Debit (Masuk)** dan **Kredit (Keluar)**.
*   Mutasi list mobile dihiasi penanda badge teks kecil `DEBIT` / `KREDIT` tepat di bawah nominal transaksi.

### 5. Catatan Audit (`AuditLogScreen`)
*   Penerjemahan nilai historis perubahan log untuk kolom tipe (`type`) diselaraskan:
    *   `income` $\rightarrow$ **Debit (Masuk)**
    *   `expense` $\rightarrow$ **Kredit (Keluar)**

---

## Struktur Berkas Sumber Terkait
*   [transaction_list_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/screens/transaction_list_screen.dart) (Tabel & card penanda mutasi)
*   [transaction_form_dialog.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/widgets/transaction_form_dialog.dart) (Tipe pilihan form & label input)
*   [dashboard_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/dashboard/screens/dashboard_screen.dart) (Teks ringkasan kartu keuangan)
*   [financial_chart.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/dashboard/widgets/financial_chart.dart) (Legenda & tooltip grafik batang)
*   [yearly_trend_chart.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/dashboard/widgets/yearly_trend_chart.dart) (Legenda & tooltip grafik garis)
*   [report_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/reports/screens/report_screen.dart) (Header tabel mutasi & badge mobile)
*   [audit_log_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/audit_logs/screens/audit_log_screen.dart) (Translasi log jenis transaksi)

---

## Panduan Verifikasi Manual
1.  **Pengujian Form Catat Uang:**
    *   Tekan tombol **"+ Catat Uang"** di pojok kanan atas halaman Transaksi.
    *   Verifikasi pilihan teratas adalah `Debit (Uang Masuk)` dan `Kredit (Uang Keluar)`.
2.  **Verifikasi Kolom Tabel Desktop:**
    *   Buka halaman **Transaksi** pada layar komputer.
    *   Pastikan tabel memuat kolom Debit (Masuk) dan Kredit (Keluar) secara terpisah berdampingan.
3.  **Verifikasi Tampilan HP:**
    *   Buka halaman Transaksi atau Laporan pada ponsel pintar.
    *   Pastikan di bawah angka nominal rupiah tertera teks kecil `DEBIT` berwarna hijau atau `KREDIT` berwarna merah.
4.  **Verifikasi Dasbor:**
    *   Kembali ke halaman utama/dasbor, pastikan kartu ringkasan menampilkan `Total Debit (Masuk)` dan `Total Kredit (Keluar)`.
