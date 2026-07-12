-- ----------------------------------------------------
-- DATABASE SCHEMA: IN-APP NOTIFICATION SYSTEM
-- YAYASAN FINANCE (SUPABASE DATABASE MIGRATION)
-- ----------------------------------------------------

-- 1. Buat tabel notifications
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  message text not null,
  type text not null check (type in ('pending_approval', 'status_changed', 'large_income')),
  related_id uuid references public.transactions(id) on delete cascade,
  is_read boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Aktifkan RLS (Row Level Security)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan RLS (RLS Policies)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'notifications' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.notifications', pol.policyname);
    END LOOP;
END $$;

create policy "Pengguna hanya dapat melihat notifikasi miliknya sendiri"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Pengguna hanya dapat memperbarui status baca notifikasi miliknya"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "System/Service Role dapat melakukan semua operasi"
  on public.notifications for all
  using (true)
  with check (true);

-- 4. Fungsi trigger untuk membuat notifikasi otomatis berdasarkan aktivitas transaksi
create or replace function public.handle_transaction_notifications()
returns trigger as $$
begin
  -- SKENARIO 1: Pengajuan pengeluaran atau donasi berstatus 'pending' (memerlukan persetujuan admin)
  if (TG_OP = 'INSERT' and NEW.status = 'pending') then
    insert into public.notifications (foundation_id, user_id, title, message, type, related_id)
    select 
      NEW.foundation_id, 
      profile_id, 
      case when NEW.type = 'income' then 'Verifikasi Donasi Masuk' else 'Persetujuan Diperlukan' end, 
      case when NEW.type = 'income' then 'Donasi baru untuk "' else 'Pengeluaran baru untuk "' end || coalesce(NEW.description, NEW.category) || '" sebesar ' || NEW.amount::text || ' membutuhkan persetujuan/verifikasi Anda.',
      'pending_approval', 
      NEW.id
    from public.foundation_members
    where foundation_id = NEW.foundation_id and role = 'admin';
  
  -- SKENARIO 2: Pemasukan (Income) bernominal besar >= Rp1.000.000 (menginfokan seluruh pengurus)
  elsif (TG_OP = 'INSERT' and NEW.type = 'income' and NEW.amount >= 1000000 and NEW.status = 'approved') then
    insert into public.notifications (foundation_id, user_id, title, message, type, related_id)
    select 
      NEW.foundation_id, 
      profile_id, 
      'Pemasukan Besar Diterima', 
      'Pemasukan baru masuk untuk "' || coalesce(NEW.description, NEW.category) || '" sebesar ' || NEW.amount::text || '.',
      'large_income', 
      NEW.id
    from public.foundation_members
    where foundation_id = NEW.foundation_id;

  -- SKENARIO 3: Perubahan status transaksi pending disetujui / ditolak oleh admin
  elsif (TG_OP = 'UPDATE' and OLD.status = 'pending' and NEW.status in ('approved', 'rejected')) then
    if (NEW.created_by is not null) then
      insert into public.notifications (foundation_id, user_id, title, message, type, related_id)
      values (
        NEW.foundation_id,
        NEW.created_by,
        case when NEW.status = 'approved' then 'Pengajuan Disetujui' else 'Pengajuan Ditolak' end,
        'Pengajuan pengeluaran Anda untuk "' || coalesce(NEW.description, NEW.category) || '" sebesar ' || NEW.amount::text || 
        case when NEW.status = 'approved' then ' telah disetujui.' else ' telah ditolak.' end,
        'status_changed',
        NEW.id
      );
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

-- 5. Trigger pada tabel transactions
drop trigger if exists on_transaction_notification_trigger on public.transactions;
create trigger on_transaction_notification_trigger
  after insert or update on public.transactions
  for each row execute function public.handle_transaction_notifications();

-- 6. Aktifkan Supabase Realtime untuk tabel notifications
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
exception
  when duplicate_object then
    null; -- Abaikan jika tabel sudah terdaftar di publication
end $$;
