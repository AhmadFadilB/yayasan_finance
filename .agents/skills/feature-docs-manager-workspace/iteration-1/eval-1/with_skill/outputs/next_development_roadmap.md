# Next Development Roadmap: Yayasan Finance

Dokumen ini merinci rencana pengembangan sistem keuangan "Yayasan Finance" setelah peluncuran versi MVP (Minimum Viable Product). Rencana ini dibagi berdasarkan tingkat prioritas, lengkap dengan manfaat, tingkat kesulitan, dan estimasi waktu pengerjaan.

---

## 1. Prioritas Tinggi (High Priority)
Fokus pada aspek keamanan data, kepatuhan (compliance), kelengkapan bukti transaksi, dan akuntabilitas kepengurusan yayasan.

### A. Audit Log (Log Audit Aktivitas) [IMPLEMENTED]
- **Manfaat**: Mencatat setiap perubahan data (siapa yang menambah, mengubah, atau menghapus data proyek/transaksi beserta nilai sebelum/sesudah perubahan). Ini krusial bagi transparansi keuangan yayasan agar terhindar dari penyalahgunaan wewenang.
- **Tingkat Kesulitan**: Rendah - Menengah (bisa diimplementasikan di level PostgreSQL menggunakan trigger audit database otomatis).
- **Status**: Selesai (Implemented) - Lihat [Audit Log Docs](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/audit_log.md)

### B. Otomatisasi Backup Database
- **Manfaat**: Menjamin keselamatan data keuangan yayasan jika terjadi kegagalan sistem, salah hapus oleh admin, atau gangguan pada server Supabase.
- **Tingkat Kesulitan**: Rendah (Supabase menyediakan fitur backup otomatis harian pada paket Pro, atau menggunakan cron job GitHub Actions ke AWS S3 untuk paket gratis).
- **Estimasi Waktu**: 2 - 3 Hari Kerja.

### C. Ekspor Laporan ke format Excel (XLSX)
- **Manfaat**: Selain PDF untuk keperluan cetak, bendahara yayasan sering kali memerlukan format Excel untuk pengolahan data lanjutan, auditing, atau integrasi manual dengan sistem lain.
- **Tingkat Kesulitan**: Rendah (menggunakan library Flutter `excel` di sisi frontend).
- **Estimasi Waktu**: 4 - 6 Hari Kerja.

### D. Unggah Bukti Transaksi (Nota / Foto / Kuitansi)
- **Manfaat**: Menyimpan bukti fisik transaksi (foto nota belanja, kuitansi transfer, scan dokumen bantuan) langsung terikat dengan data transaksi digital untuk memudahkan proses audit eksternal.
- **Tingkat Kesulitan**: Menengah (menggunakan Supabase Storage Bucket untuk penyimpanan file dan mengambil URL publiknya).
- **Estimasi Waktu**: 5 - 8 Hari Kerja.

### E. Alur Persetujuan Transaksi (Approval Workflow)
- **Manfaat**: Pengeluaran yayasan di atas nominal tertentu memerlukan verifikasi dan persetujuan (approval) oleh Pimpinan/Ketua Yayasan sebelum saldo benar-benar dipotong di sistem.
- **Tingkat Kesulitan**: Menengah - Tinggi (perlu menambahkan status persetujuan `pending`, `approved`, `rejected` pada tabel transaksi dan logika pengkondisian di dashboard).
- **Estimasi Waktu**: 7 - 10 Hari Kerja.

### F. Sistem Notifikasi Transaksi Baru
- **Manfaat**: Memberitahu pengurus yayasan (misal Ketua atau Viewer) ketika ada donasi masuk bernominal besar atau ada pengajuan pengeluaran baru yang memerlukan persetujuan.
- **Tingkat Kesulitan**: Menengah (notifikasi in-app menggunakan Supabase Realtime).
- **Estimasi Waktu**: 4 - 6 Hari Kerja.

### G. Chart of Accounts (COA) Yayasan Sesuai Standar PSAK / ISAK 35 Indonesia Terbaru
- **Manfaat**: Menyusun bagan akun standar entitas nonlaba (seperti Aset Neto Terikat, Aset Neto Tidak Terikat, Dana Zakat/Infak/Sedekah) sesuai regulasi akuntansi resmi di Indonesia (ISAK 35 / PSAK 409). Ini memastikan laporan keuangan yayasan sah secara legal dan akuntansi perpajakan nasional.
- **Tingkat Kesulitan**: Menengah (memerlukan perancangan relasi akun/jurnal double-entry dan otomatisasi pengkategorian transaksi).
- **Estimasi Waktu**: 6 - 9 Hari Kerja.

---

## 2. Prioritas Menengah (Medium Priority)
Fokus pada perluasan cakupan operasional yayasan dan fleksibilitas pencatatan keuangan.

### A. Dukungan Multi-Cabang (Multi-Branch)
- **Manfaat**: Memungkinkan satu yayasan besar memiliki beberapa kantor cabang (misal Cabang Bandung, Cabang Jakarta) dengan pembukuan yang terpisah namun dapat dipantau secara konsolidasi oleh pengurus pusat.
- **Tingkat Kesulitan**: Menengah (menambahkan tabel `branches` dan relasi `branch_id` pada transaksi/proyek).
- **Estimasi Waktu**: 8 - 12 Hari Kerja.

### B. Dashboard Keuangan yang Lebih Lengkap & Grafik Tahunan
- **Manfaat**: Menyajikan perbandingan performa keuangan antar-bulan sepanjang tahun berjalan, tren donasi, serta diagram kategori pengeluaran terbesar untuk mempermudah evaluasi anggaran bulanan.
- **Tingkat Kesulitan**: Menengah (membuat query agregasi SQL kustom / RPC untuk data tahunan dan integrasi fl_chart).
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
