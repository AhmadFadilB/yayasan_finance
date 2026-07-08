# Audit Log (Log Audit Aktivitas)

## Overview
Fitur Audit Log mencatat setiap perubahan data penting di yayasan_finance (penambahan, perubahan, dan penghapusan data proyek serta transaksi). Hal ini bertujuan untuk menjaga transparansi dan akuntabilitas keuangan yayasan.

## Architecture & Code Structure
Audit log diimplementasikan di tingkat database PostgreSQL menggunakan trigger fungsi PL/pgSQL otomatis untuk menjamin semua perubahan tercatat terlepas dari platform klien yang digunakan.

## Data Model / Database Schema
Tabel audit log baru ditambahkan ke schema public:
```sql
create table public.audit_logs (
  id uuid default gen_random_uuid() primary key,
  table_name text not null,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  record_id uuid not null,
  old_value jsonb,
  new_value jsonb,
  changed_by uuid references public.profiles(id),
  changed_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

Fungsi trigger dibuat untuk merekam perubahan:
```sql
create or replace function public.process_audit_log()
returns trigger as $$
begin
  insert into public.audit_logs (table_name, action, record_id, old_value, new_value, changed_by)
  values (
    TG_TABLE_NAME,
    TG_OP,
    coalesce(new.id, old.id),
    case when TG_OP in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when TG_OP in ('INSERT', 'UPDATE') then to_jsonb(new) else null end,
    auth.uid()
  );
  return new;
end;
$$ language plpgsql security definer;
```

## Verification / How to Test
1. Jalankan operasi insert/update/delete pada tabel `transactions` atau `projects`.
2. Lakukan query `select * from public.audit_logs;` untuk memastikan perubahan berhasil dicatat dengan data `old_value` dan `new_value` yang sesuai.
