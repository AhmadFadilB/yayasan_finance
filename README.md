# Yayasan Finance

Sistem Manajemen Keuangan Multi-Yayasan (Multi-Tenant) berbasis Flutter (Mobile & Desktop) dengan Supabase. Aplikasi ini dirancang khusus untuk memenuhi kebutuhan transparansi, akuntabilitas, dan kemudahan pencatatan keuangan pada organisasi non-profit atau yayasan di Indonesia.

---

## Fitur Utama & Dokumentasi

Berikut adalah daftar fitur utama yang telah diimplementasikan dalam aplikasi, beserta link dokumentasi teknisnya:

### 1. Manajemen Multi-Yayasan (Multi-Tenant)
*   **Deskripsi:** Satu pengguna dapat mengelola atau menjadi anggota di beberapa yayasan sekaligus. Terdapat pemisahan data yang ketat antar-yayasan yang didukung oleh Row-Level Security (RLS) di database.
*   **Peran (Role):** Admin (pengelola penuh), Bendahara (mengelola transaksi), dan Viewer (baca-saja).

### 2. Autentikasi Pengguna & Profil
*   **Deskripsi:** Registrasi dan masuk log (login) aman menggunakan Supabase Auth. Profil pengguna terintegrasi secara otomatis saat pendaftaran.

### 3. Modul Proyek Keuangan
*   **Deskripsi:** CRUD proyek yayasan (misal: Renovasi Masjid, Pembangunan Sekolah). Saldo reaktif proyek dihitung secara langsung dari transaksi terkait.

### 4. Modul Pencatatan Transaksi
*   **Deskripsi:** Pencatatan pemasukan dan pengeluaran keuangan, lengkap dengan kategori, nominal, tanggal, serta keterikatan proyek yang opsional.

### 5. Dasbor Dinamis & Analisis
*   **Deskripsi:** Ringkasan keuangan total (Saldo, Pemasukan, Pengeluaran) disertai grafik visual performa keuangan reaktif menggunakan bar chart.

### 6. Ekspor Laporan PDF (A4)
*   **Deskripsi:** Pembuatan dan pencetakan laporan keuangan berformat PDF A4 siap cetak dengan logo dan identitas yayasan aktif.

### 7. Log Audit Aktivitas (Audit Log)
*   **Deskripsi:** Pencatatan otomatis setiap aksi tambah, ubah, atau hapus data di tingkat database (via PostgreSQL triggers). Log aktivitas ditampilkan dalam bentuk linimasa terperinci di aplikasi.
*   **Dokumentasi Detail:** [Log Audit Aktivitas (docs/features/audit_log.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/audit_log.md)

### 8. Chart of Accounts (COA / Bagan Akun)
*   **Deskripsi:** Penyusunan struktur akun keuangan standar ISAK 35 non-laba Indonesia secara terstruktur (seperti Aset Neto Terikat, Zakat, dll.) dengan pengisian akun default otomatis, layar kelola bagan akun, dan dropdown input kategori transaksi yang dinamis.
*   **Dokumentasi Detail:** [Bagan Akun COA (docs/features/coa.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/coa.md)

### 9. Ekspor Laporan Keuangan ke format Excel (XLSX)
*   **Deskripsi:** Penyusunan berkas spreadsheet (.xlsx) untuk rekap data keuangan terfilter, total pemasukan/pengeluaran, dan detail baris transaksi secara terformat dan teratur.
*   **Dokumentasi Detail:** [Ekspor Laporan Excel (docs/features/excel_export.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/excel_export.md)

### 10. Unggah Bukti Transaksi (Nota / Foto / Kuitansi)
*   **Deskripsi:** Melampirkan berkas bukti transaksi secara fisik (foto nota belanja, kuitansi transfer, atau dokumen PDF kuitansi) secara langsung saat input data transaksi dengan integrasi Supabase Storage bucket.
*   **Dokumentasi Detail:** [Unggah Bukti Transaksi (docs/features/receipt_upload.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/receipt_upload.md)

### 11. Alur Persetujuan Transaksi (Approval Workflow)
*   **Deskripsi:** Pengeluaran dana yayasan bernominal besar (>= Rp1.000.000) yang dicatat oleh bendahara akan ditandakan sebagai Tertunda (`pending`), dan memerlukan verifikasi serta persetujuan resmi oleh Pimpinan/Ketua Yayasan sebelum memotong neraca saldo keuangan yayasan.
*   **Dokumentasi Detail:** [Alur Persetujuan Transaksi (docs/features/transaction_approval.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/transaction_approval.md)

### 12. Sistem Notifikasi Transaksi Baru (In-App Notification)
*   **Deskripsi:** Menyajikan notifikasi secara realtime langsung di dalam aplikasi (in-app banner & bel notifikasi) ketika bendahara mengajukan pengeluaran pending, pimpinan menyetujui/menolak pengajuan, atau ketika yayasan menerima pemasukan nominal besar.
*   **Dokumentasi Detail:** [Sistem Notifikasi Transaksi Baru (docs/features/notifications.md)](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/notifications.md)

---

## Struktur Folder Kode Sumber
Proyek ini menggunakan arsitektur **Feature-First**:
*   `lib/core/`: Menyimpan tema aplikasi global, utilitas formatter, dan penanganan status bersama.
*   `lib/features/`: Direktori fitur modular:
    *   `auth/`: Manajemen masuk/daftar pengguna.
    *   `foundations/`: Pemilihan yayasan dan penambahan anggota.
    *   `dashboard/`: Tampilan ringkasan dasbor dan grafik.
    *   `projects/`: Manajemen proyek yayasan.
    *   `transactions/`: Layar dan formulir transaksi keuangan.
    *   `reports/`: Layar ekspor laporan PDF.
    *   `audit_logs/`: Log aktivitas perubahan data.
    *   `coa/`: Manajemen bagan akun (COA) PSAK / ISAK 35.
