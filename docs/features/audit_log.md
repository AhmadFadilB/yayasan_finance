# Audit Log (Log Audit Aktivitas)

## Overview
Fitur Audit Log mencatat setiap perubahan data utama (penambahan, pembaruan, penghapusan) pada modul-modul penting seperti Yayasan, Anggota, Proyek, dan Transaksi. Data log dicatat secara otomatis di sisi PostgreSQL menggunakan trigger database untuk menjamin keamanan, integritas data, dan transparansi laporan keuangan yayasan.

---

## Architecture & Code Structure

### 1. Database (PostgreSQL / Supabase)
- **File Kueri:** [audit_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/audit_schema.sql)
  - Berisi definisi tabel `audit_logs`, kebijakan keamanan RLS, dan fungsi pemicu `log_audit_action()`.

### 2. Flutter Feature Layer
- **Model:** [audit_log_model.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/audit_logs/models/audit_log_model.dart)
  - Memetakan data log JSON database ke objek Dart.
- **Service:** [audit_log_service.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/audit_logs/services/audit_log_service.dart)
  - Mengambil data dari tabel `audit_logs` berdasarkan yayasan yang sedang aktif.
- **Provider:** [audit_log_provider.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/audit_logs/providers/audit_log_provider.dart)
  - Mengelola state pemuatan data log audit reaktif menggunakan Riverpod.
- **Screen:** [audit_log_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/audit_logs/screens/audit_log_screen.dart)
  - Antarmuka visual linimasa (timeline) log aktivitas dengan filter berdasarkan jenis modul dan tipe aksi.

---

## Data Model / Database Schema

### Tabel `public.audit_logs`

| Kolom | Tipe | Deskripsi |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key (auto-generated) |
| `foundation_id` | `uuid` | Relasi ke `public.foundations` (On Delete Cascade) |
| `table_name` | `text` | Nama tabel yang berubah (`transactions`, `projects`, dll.) |
| `action` | `text` | Jenis operasi data (`INSERT`, `UPDATE`, `DELETE`) |
| `record_id` | `uuid` | ID baris data yang mengalami perubahan |
| `old_values` | `jsonb` | Nilai data sebelum dilakukan pembaruan/penghapusan |
| `new_values` | `jsonb` | Nilai data sesudah dilakukan penambahan/pembaruan |
| `performed_by` | `uuid` | ID Pengguna yang melakukan perubahan (relasi ke `profiles.id`) |
| `performed_by_name` | `text` | Nama profil pengguna (denormalisasi untuk performa kueri) |
| `created_at` | `timestamptz` | Waktu pencatatan log |

### Keamanan Row Level Security (RLS)
Log audit diamankan secara ketat. Anggota yayasan hanya diperbolehkan membaca data audit dari yayasan tempat mereka terdaftar:
```sql
create policy "Members can view audit logs"
  on public.audit_logs for select
  to authenticated
  using (public.is_member_of(foundation_id));
```

---

## UI & User Interaction

Fitur ini diakses dari navigasi utama (BottomBar pada Mobile / Sidebar pada Desktop) berlabel **Log Audit**:
1. **Penyaringan Cepat (Filter Chips):** Pengguna dapat memfilter berdasarkan Modul Data (Semua, Transaksi, Proyek, Anggota, Yayasan) dan Tindakan (Semua, Tambah, Ubah, Hapus).
2. **Desain Linimasa Premium:** Log disajikan secara kronologis menurun dengan indikator warna (Hijau untuk Tambah, Oranye untuk Ubah, Merah untuk Hapus).
3. **Ekspansi Perbandingan Detail:** Pengguna dapat menekan ikon dropdown pada log untuk melihat data baru (untuk INSERT), data terhapus (untuk DELETE), atau perbandingan perbedaan field demi field secara detail (untuk UPDATE).

---

## Verification / How to Test

### Pengujian Otomatis
Jalankan analisis statis Dart untuk memastikan tidak ada error kode:
```bash
flutter analyze
```

### Pengujian Manual
1. Pastikan skrip database [audit_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/audit_schema.sql) telah dijalankan di panel SQL Editor Supabase.
2. Lakukan manipulasi data di aplikasi (seperti menambah transaksi baru, mengubah nama proyek, atau menghapus anggota).
3. Navigasikan ke menu **Log Audit** dan pastikan log aktivitas terbaru langsung tercatat beserta nama akun Anda dan detail perubahan yang dilakukan.
