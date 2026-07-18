-- ----------------------------------------------------
-- DATABASE SCHEMA: CHART OF ACCOUNTS (COA)
-- YAYASAN FINANCE (ISAK 35 COMPLIANT)
-- ----------------------------------------------------

-- 1. Create chart_of_accounts table. 
create table if not exists public.chart_of_accounts (
  id uuid default gen_random_uuid() primary key,
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  code text not null,
  name text not null,
  category text not null check (category in ('asset', 'liability', 'net_asset', 'revenue', 'expense')),
  parent_code text,
  is_active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Setiap kode akun harus unik dalam satu yayasan
  constraint coa_foundation_code_unique unique (foundation_id, code)
);

-- 2. Enable Row Level Security (RLS)
alter table public.chart_of_accounts enable row level security;

-- 3. RLS Policies for Chart of Accounts
-- Semua anggota yayasan dapat melihat Bagan Akun
create policy "Members can view coa"
  on public.chart_of_accounts for select
  to authenticated
  using (public.is_member_of(foundation_id));

-- Admin dan Bendahara dapat menambah akun baru
create policy "Admin and Bendahara can insert coa"
  on public.chart_of_accounts for insert
  to authenticated
  with check (public.is_authorized_to_transact(foundation_id));

-- Admin dan Bendahara dapat mengedit akun
create policy "Admin and Bendahara can update coa"
  on public.chart_of_accounts for update
  to authenticated
  using (public.is_authorized_to_transact(foundation_id));

-- Hanya Admin yang dapat menghapus akun
create policy "Admin can delete coa"
  on public.chart_of_accounts for delete
  to authenticated
  using (public.is_admin_of(foundation_id));

-- 4. Trigger function to automatically seed standard COA (ISAK 35) on new foundation
create or replace function public.handle_new_foundation_coa()
returns trigger as $$
begin
  insert into public.chart_of_accounts (foundation_id, code, name, category)
  values
    -- Aset (1xxx)
    (new.id, '1110', 'Kas Utama', 'asset'),
    (new.id, '1120', 'Bank', 'asset'),
    (new.id, '1210', 'Peralatan Kantor', 'asset'),
    
    -- Liabilitas (2xxx)
    (new.id, '2110', 'Utang Usaha', 'liability'),
    
    -- Aset Neto / Ekuitas (3xxx)
    (new.id, '3110', 'Aset Neto Tanpa Pembatasan', 'net_asset'),
    (new.id, '3210', 'Aset Neto Dengan Pembatasan', 'net_asset'),
    
    -- Penerimaan / Pemasukan (4xxx)
    (new.id, '4110', 'Donasi Umum (Tidak Terikat)', 'revenue'),
    (new.id, '4120', 'Penerimaan Jasa', 'revenue'),
    (new.id, '4210', 'Donasi Terikat', 'revenue'),
    (new.id, '4220', 'Penerimaan Zakat', 'revenue'),
    (new.id, '4230', 'Penerimaan Infak/Sedekah', 'revenue'),
    (new.id, '4240', 'Penerimaan Wakaf', 'revenue'),
    
    -- Beban / Pengeluaran (5xxx)
    (new.id, '5110', 'Beban Penyaluran Donasi Terikat', 'expense'),
    (new.id, '5120', 'Beban Penyaluran Zakat', 'expense'),
    (new.id, '5130', 'Beban Penyaluran Infak/Sedekah', 'expense'),
    (new.id, '5210', 'Beban Gaji & Honorarium', 'expense'),
    (new.id, '5220', 'Beban Listrik, Air & Internet', 'expense'),
    (new.id, '5230', 'Beban Sewa Kantor', 'expense'),
    (new.id, '5240', 'Beban Operasional Lainnya', 'expense')
  on conflict do nothing;

  return new;
end;
$$ language plpgsql security definer;

-- Attach trigger to foundations table
drop trigger if exists on_foundation_created_seed_coa on public.foundations;
create trigger on_foundation_created_seed_coa
  after insert on public.foundations
  for each row execute procedure public.handle_new_foundation_coa();

-- 5. Modify transactions table to link to coa
alter table public.transactions 
  add column if not exists account_id uuid references public.chart_of_accounts(id) on delete set null;

-- 6. Seed existing foundations in database (One-time migration)
do $$
declare
  f record;
begin
  for f in select id from public.foundations loop
    if not exists (select 1 from public.chart_of_accounts where foundation_id = f.id) then
      insert into public.chart_of_accounts (foundation_id, code, name, category) values
        -- Aset (1xxx)
        (f.id, '1110', 'Kas Utama', 'asset'),
        (f.id, '1120', 'Bank', 'asset'),
        (f.id, '1210', 'Peralatan Kantor', 'asset'),
        
        -- Liabilitas (2xxx)
        (f.id, '2110', 'Utang Usaha', 'liability'),
        
        -- Aset Neto / Ekuitas (3xxx)
        (f.id, '3110', 'Aset Neto Tanpa Pembatasan', 'net_asset'),
        (f.id, '3210', 'Aset Neto Dengan Pembatasan', 'net_asset'),
        
        -- Penerimaan / Pemasukan (4xxx)
        (f.id, '4110', 'Donasi Umum (Tidak Terikat)', 'revenue'),
        (f.id, '4120', 'Penerimaan Jasa', 'revenue'),
        (f.id, '4210', 'Donasi Terikat', 'revenue'),
        (f.id, '4220', 'Penerimaan Zakat', 'revenue'),
        (f.id, '4230', 'Penerimaan Infak/Sedekah', 'revenue'),
        (f.id, '4240', 'Penerimaan Wakaf', 'revenue'),
        
        -- Beban / Pengeluaran (5xxx)
        (f.id, '5110', 'Beban Penyaluran Donasi Terikat', 'expense'),
        (f.id, '5120', 'Beban Penyaluran Zakat', 'expense'),
        (f.id, '5130', 'Beban Penyaluran Infak/Sedekah', 'expense'),
        (f.id, '5210', 'Beban Gaji & Honorarium', 'expense'),
        (f.id, '5220', 'Beban Listrik, Air & Internet', 'expense'),
        (f.id, '5230', 'Beban Sewa Kantor', 'expense'),
        (f.id, '5240', 'Beban Operasional Lainnya', 'expense')
      on conflict do nothing;
    end if;
  end loop;
end;
$$;

-- 7. Update existing transactions to link to newly seeded accounts (Best-effort migration)
update public.transactions t
set account_id = coa.id
from public.chart_of_accounts coa
where t.foundation_id = coa.foundation_id
  and (
    lower(t.category) = lower(coa.name) or 
    (lower(t.category) = 'donasi' and coa.code = '4110') or
    (lower(t.category) = 'operasional' and coa.code = '5240') or
    (lower(t.category) = 'gaji' and coa.code = '5210')
  )
  and t.account_id is null;

-- 8. Add trigger to audit logs for coa changes (idempotent)
drop trigger if exists audit_chart_of_accounts_trigger on public.chart_of_accounts;
create trigger audit_chart_of_accounts_trigger
  after insert or update or delete on public.chart_of_accounts
  for each row execute procedure public.log_audit_action();
