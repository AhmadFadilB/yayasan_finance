-- ----------------------------------------------------
-- DATABASE SCHEMA: TRANSACTION APPROVAL WORKFLOW
-- YAYASAN FINANCE (SUPABASE DATABASE MIGRATION)
-- ----------------------------------------------------

-- 1. Tambahkan kolom status ke tabel transactions jika belum ada
-- Gunakan CHECK constraint untuk memastikan status hanya berisi pending, approved, atau rejected
alter table public.transactions add column if not exists status text default 'approved';

do $$
begin
  if not exists (
    select 1 from information_schema.constraint_column_usage 
    where table_name = 'transactions' and constraint_name = 'transactions_status_check'
  ) then
    alter table public.transactions add constraint transactions_status_check check (status in ('pending', 'approved', 'rejected'));
  end if;
end $$;

-- 2. Tambahkan kolom approved_by ke tabel transactions jika belum ada
alter table public.transactions add column if not exists approved_by uuid references public.profiles(id) on delete set null;

-- 3. Tambahkan kolom approved_at ke tabel transactions jika belum ada
alter table public.transactions add column if not exists approved_at timestamptz;

-- 4. Perbarui RLS policies untuk tabel transactions agar mengizinkan update status persetujuan
-- Pembaruan (UPDATE) hanya diizinkan untuk admin (Pimpinan) untuk semua transaksi, atau bendahara untuk transaksinya sendiri (jika masih pending)
drop policy if exists "Allow admins to update all transactions" on public.transactions;
drop policy if exists "Allow members to update own pending transactions" on public.transactions;

create policy "Allow members to update/approve transactions based on role"
  on public.transactions for update
  to authenticated
  using (
    -- Admin yayasan bebas mengubah transaksi apapun
    exists (
      select 1 from public.foundation_members
      where foundation_members.foundation_id = transactions.foundation_id
        and foundation_members.profile_id = auth.uid()
        and foundation_members.role = 'admin'
    )
    or
    -- Bendahara hanya bisa mengubah transaksinya sendiri jika status masih pending
    (
      exists (
        select 1 from public.foundation_members
        where foundation_members.foundation_id = transactions.foundation_id
          and foundation_members.profile_id = auth.uid()
          and foundation_members.role = 'bendahara'
      )
      and transactions.created_by = auth.uid()
      and transactions.status = 'pending'
    )
  );
