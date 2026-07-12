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
-- Menghapus kebijakan lama jika ingin di-replace
DROP POLICY IF EXISTS "Members can view projects" ON public.projects;

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

CREATE POLICY "Anyone can view approved public transactions or members view all" 
ON public.transactions FOR SELECT 
USING (
    (
        project_id IS NOT NULL 
        AND status = 'approved'
        AND EXISTS (
            SELECT 1 FROM public.projects 
            WHERE id = transactions.project_id AND is_public = true
        )
    )
    OR (auth.role() = 'authenticated' AND EXISTS (
        SELECT 1 FROM public.foundation_members 
        WHERE foundation_id = transactions.foundation_id AND profile_id = auth.uid()
    ))
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
CREATE POLICY "Anyone can view donations of public projects" 
ON public.donations FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.transactions t 
        JOIN public.projects p ON t.project_id = p.id
        WHERE t.id = transaction_id AND p.is_public = true
    )
);

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
CREATE POLICY "Anyone can view foundations" 
ON public.foundations FOR SELECT 
USING (true);
