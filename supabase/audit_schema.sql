-- ----------------------------------------------------
-- DATABASE SCHEMA: AUDIT LOGS FOR YAYASAN FINANCE
-- ----------------------------------------------------

-- 1. Create audit_logs table
create table if not exists public.audit_logs (
  id uuid default gen_random_uuid() primary key,
  foundation_id uuid references public.foundations(id) on delete cascade not null,
  table_name text not null,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  record_id uuid not null,
  old_values jsonb,
  new_values jsonb,
  performed_by uuid references public.profiles(id) on delete set null,
  performed_by_name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Enable RLS
alter table public.audit_logs enable row level security;

-- 3. Policy: Members can view audit logs
create policy "Members can view audit logs"
  on public.audit_logs for select
  to authenticated
  using (public.is_member_of(foundation_id));

-- 4. Trigger function to log audit actions
create or replace function public.log_audit_action()
returns trigger as $$
declare
  v_foundation_id uuid;
  v_user_id uuid;
  v_user_name text;
  v_record_id uuid;
  v_old_values jsonb := null;
  v_new_values jsonb := null;
begin
  -- Get user ID
  v_user_id := auth.uid();
  
  -- Get profile name
  if v_user_id is not null then
    select name into v_user_name from public.profiles where id = v_user_id;
  end if;

  -- Determine record ID and foundation ID based on table
  if TG_TABLE_NAME = 'foundations' then
    if TG_OP = 'DELETE' then
      v_record_id := old.id;
      v_foundation_id := old.id;
      v_old_values := to_jsonb(old);
    else
      v_record_id := new.id;
      v_foundation_id := new.id;
      v_new_values := to_jsonb(new);
      if TG_OP = 'UPDATE' then
        v_old_values := to_jsonb(old);
      end if;
    end if;
  elsif TG_TABLE_NAME = 'projects' then
    if TG_OP = 'DELETE' then
      v_record_id := old.id;
      v_foundation_id := old.foundation_id;
      v_old_values := to_jsonb(old);
    else
      v_record_id := new.id;
      v_foundation_id := new.foundation_id;
      v_new_values := to_jsonb(new);
      if TG_OP = 'UPDATE' then
        v_old_values := to_jsonb(old);
      end if;
    end if;
  elsif TG_TABLE_NAME = 'transactions' then
    if TG_OP = 'DELETE' then
      v_record_id := old.id;
      v_foundation_id := old.foundation_id;
      v_old_values := to_jsonb(old);
    else
      v_record_id := new.id;
      v_foundation_id := new.foundation_id;
      v_new_values := to_jsonb(new);
      if TG_OP = 'UPDATE' then
        v_old_values := to_jsonb(old);
      end if;
    end if;
  elsif TG_TABLE_NAME = 'foundation_members' then
    if TG_OP = 'DELETE' then
      v_record_id := old.profile_id;
      v_foundation_id := old.foundation_id;
      v_old_values := to_jsonb(old);
    else
      v_record_id := new.profile_id;
      v_foundation_id := new.foundation_id;
      v_new_values := to_jsonb(new);
      if TG_OP = 'UPDATE' then
        v_old_values := to_jsonb(old);
      end if;
    end if;
  end if;

  -- If foundation_id is null, we cannot associate it
  if v_foundation_id is null then
    return coalesce(new, old);
  end if;

  -- Insert into audit_logs
  insert into public.audit_logs (
    foundation_id,
    table_name,
    action,
    record_id,
    old_values,
    new_values,
    performed_by,
    performed_by_name
  ) values (
    v_foundation_id,
    TG_TABLE_NAME,
    TG_OP,
    v_record_id,
    v_old_values,
    v_new_values,
    v_user_id,
    coalesce(v_user_name, 'System')
  );

  return coalesce(new, old);
end;
$$ language plpgsql security definer;

-- 5. Attach triggers (drop first if exist to ensure idempotency)
drop trigger if exists audit_foundations_trigger on public.foundations;
create trigger audit_foundations_trigger
  after insert or update or delete on public.foundations
  for each row execute procedure public.log_audit_action();

drop trigger if exists audit_projects_trigger on public.projects;
create trigger audit_projects_trigger
  after insert or update or delete on public.projects
  for each row execute procedure public.log_audit_action();

drop trigger if exists audit_transactions_trigger on public.transactions;
create trigger audit_transactions_trigger
  after insert or update or delete on public.transactions
  for each row execute procedure public.log_audit_action();

drop trigger if exists audit_foundation_members_trigger on public.foundation_members;
create trigger audit_foundation_members_trigger
  after insert or update or delete on public.foundation_members
  for each row execute procedure public.log_audit_action();
