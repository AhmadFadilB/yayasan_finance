# Next Development Roadmap: Yayasan Finance

Dokumen ini merinci rencana pengembangan sistem keuangan "Yayasan Finance" setelah peluncuran versi MVP (Minimum Viable Product). Rencana ini dibagi berdasarkan tingkat prioritas, lengkap dengan manfaat, tingkat kesulitan, dan estimasi waktu pengerjaan.

---

## 1. Prioritas Tinggi (High Priority)
Fokus pada aspek keamanan data, kepatuhan (compliance), kelengkapan bukti transaksi, dan akuntabilitas kepengurusan yayasan.

### A. Audit Log (Log Audit Aktivitas) - [SELESAI / IMPLEMENTED]
- **Manfaat**: Mencatat setiap perubahan data (siapa yang menambah, mengubah, atau menghapus data proyek/transaksi beserta nilai sebelum/sesudah perubahan). Ini krusial bagi transparansi keuangan yayasan agar terhindar dari penyalahgunaan wewenang.
- **Status**: Selesai diimplementasikan. Data log dicatat secara otomatis di sisi Supabase Database menggunakan trigger PostgreSQL dan disajikan dalam linimasa aktivitas terperinci di aplikasi Flutter.
- **Dokumentasi**: [docs/features/audit_log.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/audit_log.md)
- **Tingkat Kesulitan**: Rendah - Menengah
- **Estimasi Waktu**: 3 - 5 Hari Kerja.

### B. Otomatisasi Backup Database
- **Manfaat**: Menjamin keselamatan data keuangan yayasan jika terjadi kegagalan sistem, salah hapus oleh admin, atau gangguan pada server Supabase.
- **Tingkat Kesulitan**: Rendah (Supabase menyediakan fitur backup otomatis harian pada paket Pro, atau menggunakan cron job GitHub Actions ke AWS S3 untuk paket gratis).
- **Estimasi Waktu**: 2 - 3 Hari Kerja.

### C. Ekspor Laporan ke format Excel (XLSX) - [SELESAI / IMPLEMENTED]
- **Manfaat**: Selain PDF untuk keperluan cetak, bendahara yayasan sering kali memerlukan format Excel untuk pengolahan data lanjutan, auditing, atau integrasi manual dengan sistem lain.
- **Status**: Selesai diimplementasikan. Menggunakan pustaka `excel` di frontend dengan dukungan cross-platform saver untuk Web (Blob HTML) dan Mobile/Desktop (path_provider). Tombol ekspor terintegrasi di layar Laporan.
- **Dokumentasi**: [docs/features/excel_export.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/excel_export.md)
- **Tingkat Kesulitan**: Rendah
- **Estimasi Waktu**: 4 - 6 Hari Kerja.

### D. Unggah Bukti Transaksi (Nota / Foto / Kuitansi) - [SELESAI / IMPLEMENTED]
- **Manfaat**: Menyimpan bukti fisik transaksi (foto nota belanja, kuitansi transfer, scan dokumen bantuan) langsung terikat dengan data transaksi digital untuk memudahkan proses audit eksternal.
- **Status**: Selesai diimplementasikan. Menggunakan Supabase Storage bucket `receipts` dengan aturan RLS terintegrasi. Form transaksi mendukung pencarian berkas lintas platform dengan preview foto atau tombol buka berkas PDF secara reaktif.
- **Dokumentasi**: [docs/features/receipt_upload.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/receipt_upload.md)
- **Tingkat Kesulitan**: Menengah
- **Estimasi Waktu**: 5 - 8 Hari Kerja.

### E. Alur Persetujuan Transaksi (Approval Workflow) - [SELESAI / IMPLEMENTED]
- **Manfaat**: Pengeluaran yayasan di atas nominal tertentu memerlukan verifikasi dan persetujuan (approval) oleh Pimpinan/Ketua Yayasan sebelum saldo benar-benar dipotong di sistem.
- **Status**: Selesai diimplementasikan. Menggunakan batasan nominal > Rp1.000.000 bagi bendahara untuk memicu status pending. Dilengkapi antarmuka kelola persetujuan khusus admin yayasan.
- **Dokumentasi**: [docs/features/transaction_approval.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/transaction_approval.md)
- **Tingkat Kesulitan**: Menengah - Tinggi
- **Estimasi Waktu**: 7 - 10 Hari Kerja.

### F. Sistem Notifikasi Transaksi Baru - [SELESAI / IMPLEMENTED]
- **Manfaat**: Memberitahu pengurus yayasan (misal Ketua atau Viewer) ketika ada donasi masuk bernominal besar atau ada pengajuan pengeluaran baru yang memerlukan persetujuan.
- **Status**: Selesai diimplementasikan. Menggunakan trigger database Supabase dan listener reaktif stream reaktif di Flutter.
- **Dokumentasi**: [docs/features/notifications.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/notifications.md)
- **Tingkat Kesulitan**: Menengah
- **Estimasi Waktu**: 4 - 6 Hari Kerja.

### G. Chart of Accounts (COA) Yayasan Sesuai Standar PSAK / ISAK 35 Indonesia Terbaru - [SELESAI / IMPLEMENTED]
- **Manfaat**: Menyusun bagan akun standar entitas nonlaba (seperti Aset Neto Terikat, Aset Neto Tidak Terikat, Dana Zakat/Infak/Sedekah) sesuai regulasi akuntansi resmi di Indonesia (ISAK 35 / PSAK 409). Ini memastikan laporan keuangan yayasan sah secara legal dan akuntansi perpajakan nasional.
- **Status**: Selesai diimplementasikan. Skema COA (Bagan Akun) terintegrasi ke database dengan inisialisasi akun otomatis saat pembuatan yayasan baru, layar manajemen bagan akun berbasis Tab di Flutter, dan dropdown kategori transaksi reaktif berbasis COA.
- **Dokumentasi**: [docs/features/coa.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/coa.md)
- **Tingkat Kesulitan**: Menengah
- **Estimasi Waktu**: 6 - 9 Hari Kerja.

---

## 2. Prioritas Menengah (Medium Priority)
Fokus pada perluasan cakupan operasional yayasan dan fleksibilitas pencatatan keuangan.

### A. Dukungan Multi-Cabang (Multi-Branch)
- **Manfaat**: Memungkinkan satu yayasan besar memiliki beberapa kantor cabang (misal Cabang Bandung, Cabang Jakarta) dengan pembukuan yang terpisah namun dapat dipantau secara konsolidasi oleh pengurus pusat.
- **Tingkat Kesulitan**: Menengah (menambahkan tabel `branches` dan relasi `branch_id` pada transaksi/proyek).
- **Estimasi Waktu**: 8 - 12 Hari Kerja.

### B. Dashboard Keuangan yang Lebih Lengkap & Grafik Tahunan - [SELESAI / IMPLEMENTED]
- **Manfaat**: Menyajikan perbandingan performa keuangan antar-bulan sepanjang tahun berjalan, tren donasi, serta diagram kategori pengeluaran terbesar untuk mempermudah evaluasi anggaran bulanan.
- **Status**: Selesai diimplementasikan. Menggunakan diagram donat sebaran pengeluaran reaktif (`ExpensePieChart`) dan diagram garis tren tahunan (`YearlyTrendChart`) berbasis filter tahun.
- **Dokumentasi**: [docs/features/interactive_dashboard.md](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/interactive_dashboard.md)
- **Tingkat Kesulitan**: Menengah
- **Estimasi Waktu**: 6 - 9 Hari Kerja.

### C. Kategori Kustom (Custom Categories)
- **Manfaat**: Mengizinkan pengurus yayasan membuat, mengedit, atau menghapus kategori pemasukan/pengeluaran mereka sendiri sesuai dengan kebutuhan unik yayasan, tidak terbatas pada opsi default MVP.
- **Tingkat Kesulitan**: Rendah - Menengah (membuat tabel `categories` di database yang terikat ke `foundation_id`).
- **Estimasi Waktu**: 5 - 7 Hari Kerja.

---

## 3. Prioritas Lanjutan (Advanced Priority)
Fokus pada integrasi pihak ketiga, perluasan platform, serta opsi monetisasi (SaaS).

### A. Mobile Push Notification (Firebase Cloud Messaging)
- **Manfaat**: Mengirimkan notifikasi langsung ke ponsel pengurus yayasan meskipun aplikasi sedang ditutup, berguna untuk alert persetujuan transaksi mendesak.
- **Tingkat Kesulitan**: Menengah - Tinggi (integrasi Firebase Cloud Messaging pada platform Android & iOS).
- **Estimasi Waktu**: 8 - 12 Hari Kerja.

### B. Integrasi Notifikasi WhatsApp
- **Manfaat**: Mengirimkan bukti tanda terima donasi otomatis ke WhatsApp donatur segera setelah bendahara mengonfirmasi transaksi masuk. Sangat disukai karena meningkatkan kepercayaan donatur.
- **Tingkat Kesulitan**: Menengah (integrasi dengan API Gateway WhatsApp pihak ketiga seperti Fonnte / Wablas).
- **Estimasi Waktu**: 6 - 8 Hari Kerja.

### C. Integrasi Gerbang Pembayaran (Payment Gateway)
- **Manfaat**: Mengizinkan donatur mengirimkan donasi/wakaf secara langsung lewat transfer bank otomatis (Virtual Account), QRIS, atau e-wallet (GoPay/OVO) yang langsung tercatat ke sistem tanpa input manual bendahara.
- **Tingkat Kesulitan**: Tinggi (integrasi API payment gateway Indonesia seperti Midtrans / Xendit).
- **Estimasi Waktu**: 12 - 18 Hari Kerja.

### D. Laporan Keuangan Standar Akuntansi (ISAK 35)
- **Manfaat**: Menghasilkan Laporan Posisi Keuangan, Laporan Penghasilan Komprehensif, dan Laporan Arus Kas sesuai dengan standar akuntansi entitas nirlaba (ISAK 35 / PSAK 409). Sangat penting agar laporan yayasan sah di mata hukum dan perpajakan.
- **Tingkat Kesulitan**: Tinggi (membutuhkan pemahaman akuntansi double-entry dan jurnal umum otomatis).
- **Estimasi Waktu**: 15 - 25 Hari Kerja.

### E. Model Langganan SaaS (Software-as-a-Service Subscription)
- **Manfaat**: Mengubah aplikasi menjadi platform komersial di mana yayasan-yayasan eksternal dapat mendaftar dan berlangganan sistem keuangan ini dengan membayar biaya bulanan/tahunan (multi-tenant komersial).
- **Tingkat Kesulitan**: Tinggi (perlu integrasi payment gateway untuk subscription billing, pembatasan kuota space storage, dan pengelolaan tenant komersial).
- **Estimasi Waktu**: 20 - 30 Hari Kerja.
