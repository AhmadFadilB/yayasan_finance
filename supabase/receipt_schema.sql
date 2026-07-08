-- ----------------------------------------------------
-- DATABASE SCHEMA: RECEIPT UPLOAD (BUKTI TRANSAKSI)
-- YAYASAN FINANCE (SUPABASE STORAGE BUCKET CONFIG)
-- ----------------------------------------------------

-- 1. Tambahkan kolom receipt_url ke tabel transactions jika belum ada
alter table public.transactions add column if not exists receipt_url text;

-- 2. Daftarkan bucket 'receipts' ke dalam tabel storage.buckets jika belum ada
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true)
on conflict (id) do nothing;

-- 3. Kebijakan Row Level Security (RLS) untuk bucket 'receipts'
-- Hapus kebijakan lama jika ada untuk menghindari konflik penamaan
drop policy if exists "Allow authenticated uploads to receipts" on storage.objects;
drop policy if exists "Allow public read access to receipts" on storage.objects;
drop policy if exists "Allow authenticated delete of receipts" on storage.objects;

-- Kebijakan INSERT: Mengizinkan anggota yayasan terautentikasi mengunggah bukti transaksi
create policy "Allow authenticated uploads to receipts"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'receipts');

-- Kebijakan SELECT: Mengizinkan akses baca berkas bukti secara umum (karena bucket bersifat publik)
create policy "Allow public read access to receipts"
  on storage.objects for select
  to public
  using (bucket_id = 'receipts');

-- Kebijakan DELETE: Mengizinkan pengguna terautentikasi menghapus berkas bukti mereka
create policy "Allow authenticated delete of receipts"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'receipts');
