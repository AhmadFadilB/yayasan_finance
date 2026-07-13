-- ----------------------------------------------------
-- DATABASE SCHEMA: CROWDFUNDING & GAMIFICATION (Fase 20)
-- ----------------------------------------------------

-- 1. MODIFIKASI TABEL PROJECTS
-- Menambahkan kolom pengaturan publikasi dan target donasi
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS target_amount NUMERIC(15, 2) DEFAULT 0.0;

-- 2. PEMBUATAN TABEL DONATIONS
-- Menyimpan metadata donatur publik
CREATE TABLE IF NOT EXISTS public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE NOT NULL,
    donor_name VARCHAR(100) NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    email VARCHAR(100),
    phone VARCHAR(20),
    unique_code INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Mengaktifkan Row Level Security (RLS) pada tabel donations
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

-- 3. PERBAIKAN & PENAMBAHAN KEBIJAKAN KEAMANAN (RLS POLICIES)

-- A. Kebijakan untuk tabel PROJECTS
-- Menghapus kebijakan lama agar re-runable
DROP POLICY IF EXISTS "Members can view projects" ON public.projects;
DROP POLICY IF EXISTS "Anyone can view public projects or members can view all" ON public.projects;

-- Kebijakan baru: Siapa pun (termasuk anonim/donatur) dapat melihat proyek yang disetel publik,
-- dan anggota yayasan dapat melihat semua proyek (baik publik maupun privat) di yayasan mereka.
CREATE POLICY "Anyone can view public projects or members can view all" 
ON public.projects FOR SELECT 
USING (
    is_public = true 
    OR (auth.role() = 'authenticated' AND EXISTS (
        SELECT 1 FROM public.foundation_members 
        WHERE foundation_id = projects.foundation_id AND profile_id = auth.uid()
    ))
);

-- B. Kebijakan untuk tabel TRANSACTIONS (Melihat Donasi Masuk)
DROP POLICY IF EXISTS "Members can view transactions" ON public.transactions;
DROP POLICY IF EXISTS "Anyone can view approved public transactions or members view all" ON public.transactions;
DROP POLICY IF EXISTS "Anyone can view approved public transactions" ON public.transactions;
DROP POLICY IF EXISTS "Members can view all transactions of their foundation" ON public.transactions;

-- 1. Publik dapat melihat donasi (pemasukan) yang sudah disetujui
CREATE POLICY "Anyone can view approved public transactions" 
ON public.transactions FOR SELECT 
TO public
USING (
    project_id IS NOT NULL 
    AND status = 'approved'
    AND EXISTS (
        SELECT 1 FROM public.projects 
        WHERE id = transactions.project_id AND is_public = true
    )
);

-- 2. Anggota terautentikasi dapat melihat semua transaksi yayasan mereka
CREATE POLICY "Members can view all transactions of their foundation"
ON public.transactions FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.foundation_members
        WHERE foundation_id = transactions.foundation_id AND profile_id = auth.uid()
    )
);

-- 3. Mengizinkan siapa pun (termasuk anonim) melihat transaksi pending mereka untuk keperluan RETURNING saat insert
DROP POLICY IF EXISTS "Anyone can view pending public transactions" ON public.transactions;

CREATE POLICY "Anyone can view pending public transactions"
ON public.transactions FOR SELECT
TO public
USING (
    status = 'pending'
    AND type = 'income'
    AND project_id IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.projects
        WHERE id = transactions.project_id AND is_public = true
    )
);

-- Kebijakan untuk memasukkan donasi pending dari publik
DROP POLICY IF EXISTS "Anyone can insert pending transactions for public projects" ON public.transactions;

CREATE POLICY "Anyone can insert pending transactions for public projects"
ON public.transactions FOR INSERT
WITH CHECK (
    status = 'pending'
    AND type = 'income'
    AND project_id IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM public.projects
        WHERE id = project_id AND is_public = true
    )
);

-- C. Kebijakan untuk tabel DONATIONS
DROP POLICY IF EXISTS "Anyone can view donations of public projects" ON public.donations;
CREATE POLICY "Anyone can view donations of public projects" 
ON public.donations FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.transactions t 
        JOIN public.projects p ON t.project_id = p.id
        WHERE t.id = transaction_id AND p.is_public = true
    )
);

DROP POLICY IF EXISTS "Anyone can insert donations for pending public transactions" ON public.donations;
CREATE POLICY "Anyone can insert donations for pending public transactions" 
ON public.donations FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.transactions t 
        JOIN public.projects p ON t.project_id = p.id
        WHERE t.id = transaction_id AND t.status = 'pending' AND t.type = 'income' AND p.is_public = true
    )
);

-- D. Kebijakan untuk tabel FOUNDATIONS
-- Mengizinkan siapa pun (termasuk anonim) untuk melihat info yayasan agar namanya bisa dirender di proyek publik
DROP POLICY IF EXISTS "Anyone can view foundations" ON public.foundations;
CREATE POLICY "Anyone can view foundations" 
ON public.foundations FOR SELECT 
USING (true);

-- E. Kebijakan Storage untuk Bukti Transaksi Publik
-- Mengizinkan donatur anonim/publik untuk mengunggah file ke bucket 'receipts'
DROP POLICY IF EXISTS "Allow authenticated uploads to receipts" ON storage.objects;
DROP POLICY IF EXISTS "Allow anyone to upload receipts" ON storage.objects;

CREATE POLICY "Allow anyone to upload receipts"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'receipts');

-- F. Hak Akses PostgreSQL untuk Pengguna Publik (Anonymous)
-- Memberikan izin INSERT ke tabel storage.objects agar pengguna tidak terdaftar dapat melakukan upload
GRANT INSERT ON storage.objects TO anon;
