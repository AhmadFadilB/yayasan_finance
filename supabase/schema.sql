-- ----------------------------------------------------
-- DATABASE SCHEMA: YAYASAN FINANCE MVP
-- ----------------------------------------------------

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";

-- 2. TABLES DEFINITIONS

-- Tabel Profiles (Profil Pengguna)
-- Menyimpan nama dan detail profil yang terhubung ke Supabase Auth Users
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Tabel Foundations (Yayasan)
-- Menyimpan data yayasan
create table public.foundations (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  created_by uuid references public.profiles(id) default auth.uid(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Tabel Foundation Members (Anggota Yayasan)
-- Menghubungkan user ke yayasan dengan peran spesifik (admin, bendahara, viewer)
create table public.foundation_members (
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  role text not null check (role in ('admin', 'bendahara', 'viewer')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (foundation_id, profile_id)
);

-- Tabel Projects (Proyek Yayasan)
-- Menyimpan proyek keuangan yayasan (misal: Renovasi Masjid, Beasiswa)
create table public.projects (
  id uuid default gen_random_uuid() primary key,
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  name text not null,
  description text,
  start_date date,
  end_date date,
  status text not null check (status in ('active', 'completed', 'planned')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Tabel Transactions (Transaksi Keuangan)
-- Menyimpan pemasukan (income) dan pengeluaran (expense) yayasan
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete set null,
  type text not null check (type in ('income', 'expense')),
  amount numeric(15, 2) not null check (amount > 0),
  category text not null,
  description text,
  transaction_date date not null default current_date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. TRIGGERS & FUNCTIONS

-- A. Trigger untuk menyisipkan data profil otomatis saat ada user register baru
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- B. Trigger untuk otomatis menetapkan pembuat yayasan sebagai ADMIN yayasan tersebut
create or replace function public.handle_new_foundation()
returns trigger as $$
begin
  insert into public.foundation_members (foundation_id, profile_id, role)
  values (new.id, auth.uid(), 'admin');
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_foundation_created
  after insert on public.foundations
  for each row execute procedure public.handle_new_foundation();


-- C. Helper Functions to prevent RLS Infinite Recursion
create or replace function public.is_member_of(f_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.foundation_members
    where foundation_id = f_id and profile_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

create or replace function public.is_admin_of(f_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.foundation_members
    where foundation_id = f_id and profile_id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer;

create or replace function public.is_authorized_to_transact(f_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.foundation_members
    where foundation_id = f_id and profile_id = auth.uid() and role in ('admin', 'bendahara')
  );
end;
$$ language plpgsql security definer;


-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- Aktifkan RLS untuk semua tabel
alter table public.profiles enable row level security;
alter table public.foundations enable row level security;
alter table public.foundation_members enable row level security;
alter table public.projects enable row level security;
alter table public.transactions enable row level security;

-- A. Kebijakan Keamanan: Profiles
-- Siapapun yang terautentikasi dapat membaca semua profil (agar bisa melihat nama anggota)
create policy "Users can view all profiles"
  on public.profiles for select
  to authenticated
  using (true);

-- User hanya bisa update profil mereka sendiri
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id);

-- B. Kebijakan Keamanan: Foundations
-- Hanya anggota yayasan yang dapat melihat data yayasan tersebut
create policy "Members can select their foundations"
  on public.foundations for select
  to authenticated
  using (public.is_member_of(id) or created_by = auth.uid());

-- Pengguna terautentikasi dapat membuat yayasan baru
create policy "Users can insert foundations"
  on public.foundations for insert
  to authenticated
  with check (true);

-- Hanya admin yayasan yang bisa mengedit informasi yayasan
create policy "Admin can update their foundations"
  on public.foundations for update
  to authenticated
  using (public.is_admin_of(id));

-- Hanya admin yayasan yang bisa menghapus yayasan
create policy "Admin can delete their foundations"
  on public.foundations for delete
  to authenticated
  using (public.is_admin_of(id));

-- C. Kebijakan Keamanan: Foundation Members
-- Anggota yayasan dapat melihat daftar anggota lain di yayasan yang sama
create policy "Members can view other members in same foundation"
  on public.foundation_members for select
  to authenticated
  using (public.is_member_of(foundation_id));

-- Hanya admin yayasan yang dapat mengundang/menambah anggota baru ke yayasan
create policy "Admin can insert members to foundation"
  on public.foundation_members for insert
  to authenticated
  with check (public.is_admin_of(foundation_id));

-- Hanya admin yayasan yang dapat mengedit peran (role) anggota lain
create policy "Admin can update member roles"
  on public.foundation_members for update
  to authenticated
  using (public.is_admin_of(foundation_id));

-- Hanya admin yayasan yang dapat menghapus anggota dari yayasan
create policy "Admin can delete members from foundation"
  on public.foundation_members for delete
  to authenticated
  using (public.is_admin_of(foundation_id));

-- D. Kebijakan Keamanan: Projects
-- Hanya anggota yayasan yang dapat melihat proyek yayasan
create policy "Members can view projects"
  on public.projects for select
  to authenticated
  using (public.is_member_of(foundation_id));

-- Hanya admin yayasan yang dapat membuat proyek baru
create policy "Admin can insert projects"
  on public.projects for insert
  to authenticated
  with check (public.is_admin_of(foundation_id));

-- Hanya admin yayasan yang dapat memperbarui proyek
create policy "Admin can update projects"
  on public.projects for update
  to authenticated
  using (public.is_admin_of(foundation_id));

-- Hanya admin yayasan yang dapat menghapus proyek
create policy "Admin can delete projects"
  on public.projects for delete
  to authenticated
  using (public.is_admin_of(foundation_id));

-- E. Kebijakan Keamanan: Transactions
-- Hanya anggota yayasan yang dapat melihat transaksi keuangan yayasan tersebut
create policy "Members can view transactions"
  on public.transactions for select
  to authenticated
  using (public.is_member_of(foundation_id));

-- Admin dan Bendahara yayasan dapat menambah transaksi keuangan baru
create policy "Admin and Bendahara can insert transactions"
  on public.transactions for insert
  to authenticated
  with check (public.is_authorized_to_transact(foundation_id));

-- Admin dan Bendahara yayasan dapat mengedit transaksi keuangan
create policy "Admin and Bendahara can update transactions"
  on public.transactions for update
  to authenticated
  using (public.is_authorized_to_transact(foundation_id));

-- Hanya admin yayasan yang dapat menghapus transaksi keuangan
create policy "Admin can delete transactions"
  on public.transactions for delete
  to authenticated
  using (public.is_admin_of(foundation_id));

-- 5. HELPER FUNCTIONS FOR APPLICATION TESTING
-- RPC function untuk menambahkan anggota ke yayasan berdasarkan alamat email.
-- Opsi A: Memudahkan admin mencari profil pengguna berdasarkan email dan memasukkannya ke yayasan.
create or replace function public.add_member_by_email(p_foundation_id uuid, p_email text, p_role text)
returns void as $$
declare
  v_profile_id uuid;
begin
  -- Pastikan user yang mengeksekusi RPC ini adalah admin dari yayasan bersangkutan
  if not exists (
    select 1 from public.foundation_members
    where foundation_id = p_foundation_id and profile_id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Hanya admin yayasan yang berhak menambahkan anggota baru';
  end if;

  -- Cari profile_id berdasarkan email di tabel auth.users
  select id into v_profile_id
  from auth.users
  where email = p_email;

  if v_profile_id is null then
    raise exception 'Pengguna dengan email % tidak ditemukan. Pastikan dia sudah melakukan registrasi.', p_email;
  end if;

  -- Sisipkan ke dalam table foundation_members
  insert into public.foundation_members (foundation_id, profile_id, role)
  values (p_foundation_id, v_profile_id, p_role)
  on conflict (foundation_id, profile_id)
  do update set role = excluded.role;
end;
$$ language plpgsql security definer;
