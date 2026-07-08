# Chart of Accounts (COA / Bagan Akun) PSAK / ISAK 35

## Overview
Fitur Chart of Accounts (COA) / Bagan Akun menyusun struktur akun keuangan terstandarisasi untuk yayasan/entitas non-laba di Indonesia yang mematuhi pedoman **ISAK 35** (pengganti PSAK 45). Dengan bagan akun ini, pemasukan dikategorikan ke dalam akun penerimaan (seperti Donasi Terikat, Donasi Bebas, Zakat, Infak), dan pengeluaran dikategorikan ke dalam akun beban program atau operasional.

Sistem juga secara otomatis melakukan pengisian (*seeding*) akun default ISAK 35 saat yayasan baru dibuat agar pengguna dapat langsung memulai pembukuan tanpa konfigurasi rumit.

---

## Architecture & Code Structure

### 1. Database (PostgreSQL / Supabase)
- **Skema Kueri:** [coa_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/coa_schema.sql)
  - Berisi definisi tabel `chart_of_accounts`, kebijakan RLS, trigger inisialisasi bagan akun saat pembuatan yayasan (`handle_new_foundation_coa`), alter tabel `transactions` untuk kolom `account_id`, kueri migrasi data transaksi lama, dan trigger pencatatan log audit.

### 2. Flutter Feature Layer
- **Model:** [coa_model.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/coa/models/coa_model.dart)
  - Memetakan data tabel `chart_of_accounts` ke objek Dart.
- **Service:** [coa_service.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/coa/services/coa_service.dart)
  - Mengurus operasi kueri CRUD ke database Supabase.
- **Provider:** [coa_provider.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/coa/providers/coa_provider.dart)
  - Mengelola state daftar akun COA dan menyediakan `activeCoaProvider` untuk data dropdown aktif.
- **Screen:** [coa_list_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/coa/screens/coa_list_screen.dart)
  - Layar manajemen bagan akun berbasis Tab (Aset, Liabilitas, Aset Neto, Penerimaan, Beban) untuk melihat, menambah, mengubah, dan menghapus akun.

---

## Data Model / Database Schema

### Tabel `public.chart_of_accounts`

| Kolom | Tipe | Deskripsi |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key (auto-generated) |
| `foundation_id` | `uuid` | Relasi ke `public.foundations` (On Delete Cascade) |
| `code` | `text` | Kode akun unik per-yayasan (contoh: `1110`, `4220`) |
| `name` | `text` | Nama akun (contoh: `Kas Utama`, `Penerimaan Zakat`) |
| `category` | `text` | Kategori (`asset`, `liability`, `net_asset`, `revenue`, `expense`) |
| `parent_code` | `text` | Kode akun induk untuk penataan hierarki (opsional) |
| `is_active` | `boolean` | Menentukan apakah akun dapat dipilih saat transaksi |
| `created_at` | `timestamptz` | Waktu pembuatan data akun |

### Relasi pada Transaksi
Kolom `account_id` ditambahkan pada tabel `public.transactions` untuk mereferensikan akun spesifik dari bagan akun COA. Untuk menjaga kompatibilitas kueri laporan keuangan lama, nama akun tetap diduplikasi ke dalam kolom teks `category` saat penyimpanan transaksi.

---

## UI & User Interaction

1.  **Tombol Pintasan Bagan Akun:** Diakses melalui ikon struktur pohon (`Icons.account_tree_outlined`) pada AppBar kanan di navigasi utama.
2.  **Otomatisasi Penyembunyian Kode (Ramah Orang Awam):** Secara default, kode akun (angka 4 digit seperti `1110`, `5120`) disembunyikan agar antarmuka bersih dan mudah dibaca oleh orang awam.
3.  **Mode Lanjutan (Switch "Tampilkan Kode"):** Terdapat switch toggle "Tampilkan Kode" pada AppBar layar Bagan Akun. Jika diaktifkan, kode akun akan ditampilkan:
    *   Sebagai badge penanda di sisi kiri daftar akun COA.
    *   Sebagai awalan teks pada dropdown kategori transaksi.
    *   Pengaturan ini tersimpan secara permanen menggunakan `SharedPreferences` sehingga tetap bertahan setelah aplikasi dimulai ulang.
4.  **Dropdown Transaksi Dinamis:** Formulir dialog catat transaksi (`TransactionFormDialog`) menampilkan kategori berdasarkan akun COA terfilter:
    *   Tipe **Uang Masuk** memuat akun kategori **Penerimaan**.
    *   Tipe **Uang Keluar** memuat akun kategori **Beban**.

---

## Verification / How to Test

### Pengujian Otomatis
Jalankan perintah berikut untuk memastikan analisis sintaksis bersih:
```bash
flutter analyze
```

### Pengujian Manual
1.  Jalankan berkas [coa_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/coa_schema.sql) di panel SQL Editor Supabase.
2.  Buka aplikasi dan buat yayasan baru. Verifikasi bahwa sesaat setelah dibuat, data Bagan Akun (COA) langsung otomatis terisi dengan 19+ akun standar ISAK 35.
3.  Buka Bagan Akun melalui AppBar kanan dan tambahkan akun beban kustom baru (misal: kode `5250` nama "Beban Konsumsi Rapat").
4.  Buka form transaksi baru, pilih **Uang Keluar**, dan verifikasi bahwa akun "Beban Konsumsi Rapat" yang baru dibuat sudah dapat dipilih sebagai kategori transaksi.
5.  Catat transaksi tersebut dan cek di menu **Log Audit** bahwa aktivitas penambahan transaksi beserta relasi kategori akun tercatat dengan benar.
