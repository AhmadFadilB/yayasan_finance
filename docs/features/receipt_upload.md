# Receipt Upload (Unggah Bukti Transaksi)

## Overview
Fitur Receipt Upload memungkinkan pengurus yayasan melampirkan berkas bukti transaksi secara fisik (seperti foto nota belanja, struk pembelian, kuitansi transfer, atau dokumen PDF kuitansi) ketika mencatat atau mengubah data transaksi pemasukan maupun pengeluaran uang.

Berkas bukti diunggah secara aman ke storage publik Supabase, dan tautan URL publiknya disimpan ke kolom `receipt_url` di tabel `transactions`. Fitur ini sangat krusial untuk transparansi operasional pembukuan keuangan yayasan.

---

## Architecture & Code Structure

### 1. Database & Storage Configuration (Supabase)
- **Skema Kueri:** [receipt_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/receipt_schema.sql)
  - Berisi query `ALTER TABLE public.transactions ADD COLUMN receipt_url text;` untuk menyimpan tautan berkas bukti.
  - Berisi pendaftaran bucket penyimpanan `receipts` pada tabel `storage.buckets`.
  - Berisi kebijakan Row Level Security (RLS) pada objek storage agar pengunggahan hanya dapat dilakukan oleh pengguna terautentikasi dan pembacaan dapat diakses secara publik.

### 2. Flutter Feature Layer
- **Model:** [transaction_model.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/models/transaction_model.dart)
  - Diperbarui dengan field `receiptUrl` untuk memetakan tautan berkas bukti dari database.
- **Provider:** [transaction_provider.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/providers/transaction_provider.dart)
  - Ditambahkan fungsi pembantu `uploadReceiptFile` untuk mengunggah berkas biner (`Uint8List`) secara langsung ke Supabase Storage bucket `receipts` pada sub-folder folder berdasarkan ID yayasan (`foundationId`).
- **Form Dialog:** [transaction_form_dialog.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/widgets/transaction_form_dialog.dart)
  - Ditambahkan form input area bukti transaksi menggunakan pustaka `file_picker` (kompatibel web & mobile).
  - Melakukan unggahan berkas sebelum mengirim data transaksi, lalu menyimpannya dengan parameter `receiptUrl`.
- **List Screen & Details:** [transaction_list_screen.dart](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/lib/features/transactions/screens/transaction_list_screen.dart)
  - Menampilkan indikator ikon lampiran (`Icons.attachment_outlined`) pada data transaksi yang memiliki bukti.
  - Di dalam dialog rincian transaksi, ditampilkan preview instan berkas bukti (Image Network Viewer dengan zoom/pan atau tombol tautan buka PDF).

---

## UI & User Interaction

1.  **Form Input Transaksi:**
    *   Pengguna dapat memilih berkas bukti berformat `.jpg`, `.jpeg`, `.png`, atau `.pdf`.
    *   Tersedia pratinjau nama berkas terpilih sebelum disimpan, lengkap dengan opsi hapus/batal.
2.  **Daftar & Detail Transaksi:**
    *   Terdapat indikator ikon paperclip di samping keterangan transaksi.
    *   Membuka detail transaksi akan memuat pratinjau bukti:
        *   Jika berkas bukti berupa **Gambar/Foto**, gambar nota akan langsung ditampilkan sebagai thumbnail di detail dialog. Klik pada gambar untuk memperbesar secara interaktif.
        *   Jika berkas bukti berupa **PDF**, tombol "Buka Berkas PDF" akan muncul untuk membuka dokumen kuitansi di tab browser baru menggunakan `url_launcher`.

---

## Verification / How to Test

### Pengujian Otomatis
Verifikasi fungsionalitas dan impor pustaka lintas platform dengan menjalankan analisis statis:
```bash
flutter analyze
```

### Pengujian Manual
1.  Jalankan berkas [receipt_schema.sql](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/supabase/receipt_schema.sql) di panel SQL Editor Supabase.
2.  Buka aplikasi dan pilih salah satu yayasan aktif.
3.  Buka menu **Transaksi** dan klik **Catat Uang**.
4.  Isi data transaksi pengeluaran.
5.  Klik tombol **Pilih Berkas Bukti (Gambar / PDF)**, pilih salah satu berkas gambar nota, lalu klik **Catat**.
6.  Setelah transaksi tercatat, klik baris transaksi tersebut untuk membuka dialog detail.
7.  Pastikan pratinjau foto nota muncul dengan rapi di dalam dialog detail transaksi.
