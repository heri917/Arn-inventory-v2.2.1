-- ARN Inventory • Revisi 1001
-- Supabase foundation + license administration.
-- Do not put service_role keys in the PWA.
create extension if not exists pgcrypto;

create table if not exists public.arn_accounts(
 id uuid primary key default gen_random_uuid(),
 name text not null default 'ARN Store',
 created_at timestamptz not null default now()
);
create table if not exists public.arn_profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 account_id uuid not null references public.arn_accounts(id) on delete cascade,
 display_name text,
 role text not null default 'user' check(role in('user','admin')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.arn_categories(id uuid primary key default gen_random_uuid(),account_id uuid not null references public.arn_accounts(id) on delete cascade,name text not null,is_active boolean not null default true,master boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(account_id,name));
create table if not exists public.arn_parts(
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.arn_accounts(id) on delete cascade,
 name text not null,
 code text,
 category_id uuid references public.arn_categories(id),
 unit text not null default 'pcs',
 purchase_price numeric,
 sale_price numeric,
 is_active boolean not null default true,
 master boolean not null default false,
 master_source text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.arn_part_compatibilities(
 id uuid primary key default gen_random_uuid(),
 part_id uuid not null references public.arn_parts(id) on delete cascade,
 model text not null,
 normalized_model text not null,
 source text,
 created_at timestamptz not null default now(),
 unique(part_id,normalized_model)
);
create table if not exists public.arn_stock_transactions(
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.arn_accounts(id) on delete cascade,
 part_id uuid not null references public.arn_parts(id),
 transaction_type text not null check(transaction_type in('in','out')),
 quantity integer not null check(quantity>0),
 reason text,
 movement_date date not null default current_date,
 supplier text,
 customer text,
 phone_model text,
 description text,
 purchase_price numeric,
 sale_price numeric,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.arn_license_codes(
 code text primary key,
 plan text not null check(plan in('user','admin')),
 duration_days integer,
 account_id uuid references public.arn_accounts(id) on delete set null,
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 created_by uuid references auth.users(id) on delete set null,
 activated_at timestamptz
);
create table if not exists public.arn_account_licenses(
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.arn_accounts(id) on delete cascade,
 license_type text not null check(license_type in('demo','user','admin')),
 starts_at timestamptz not null default now(),
 expires_at timestamptz,
 code text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);

-- Non-destructive migration for columns added in Revisi 1001.
alter table public.arn_categories add column if not exists master boolean not null default false;
alter table public.arn_categories add column if not exists updated_at timestamptz not null default now();
alter table public.arn_parts add column if not exists master boolean not null default false;
alter table public.arn_parts add column if not exists master_key text;
alter table public.arn_license_codes add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.arn_license_codes add column if not exists activated_at timestamptz;
alter table public.arn_account_licenses add column if not exists code text;

create or replace view public.arn_current_stock with (security_invoker=true) as
select p.id part_id,p.account_id,p.name,p.code,p.category_id,p.unit,p.purchase_price,p.sale_price,p.is_active,
coalesce(sum(case when t.transaction_type='in' then t.quantity when t.transaction_type='out' then -t.quantity else 0 end),0)::integer stock_quantity,
case when coalesce(sum(case when t.transaction_type='in' then t.quantity when t.transaction_type='out' then -t.quantity else 0 end),0)>5 then 'Normal'
when coalesce(sum(case when t.transaction_type='in' then t.quantity when t.transaction_type='out' then -t.quantity else 0 end),0)>0 then 'Menipis' else 'Kosong' end stock_status
from public.arn_parts p left join public.arn_stock_transactions t on t.part_id=p.id and t.account_id=p.account_id group by p.id;

create schema if not exists private;
create or replace function private.arn_current_account_id() returns uuid language sql stable security definer set search_path=public as $$
 select account_id from public.arn_profiles where id=auth.uid();
$$;
create or replace function private.arn_is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.arn_profiles where id=auth.uid() and role='admin');
$$;

alter table public.arn_accounts enable row level security;
alter table public.arn_profiles enable row level security;
alter table public.arn_categories enable row level security;
alter table public.arn_parts enable row level security;
alter table public.arn_part_compatibilities enable row level security;
alter table public.arn_stock_transactions enable row level security;
alter table public.arn_license_codes enable row level security;
alter table public.arn_account_licenses enable row level security;

-- Account/profile policies
 drop policy if exists arn_accounts_self on public.arn_accounts;
 create policy arn_accounts_self on public.arn_accounts for select using(id=private.arn_current_account_id());
 drop policy if exists arn_profiles_self on public.arn_profiles;
 create policy arn_profiles_self on public.arn_profiles for select using(id=auth.uid());

-- User data policies
 drop policy if exists arn_categories_rw on public.arn_categories;
 create policy arn_categories_rw on public.arn_categories for all using(account_id=private.arn_current_account_id()) with check(account_id=private.arn_current_account_id());
 drop policy if exists arn_parts_rw on public.arn_parts;
 create policy arn_parts_rw on public.arn_parts for all using(account_id=private.arn_current_account_id()) with check(account_id=private.arn_current_account_id());
 drop policy if exists arn_compat_rw on public.arn_part_compatibilities;
 create policy arn_compat_rw on public.arn_part_compatibilities for all using(part_id in(select id from public.arn_parts where account_id=private.arn_current_account_id())) with check(part_id in(select id from public.arn_parts where account_id=private.arn_current_account_id()));
 drop policy if exists arn_tx_rw on public.arn_stock_transactions;
 create policy arn_tx_rw on public.arn_stock_transactions for all using(account_id=private.arn_current_account_id() and exists(select 1 from public.arn_parts p where p.id=part_id and p.account_id=private.arn_current_account_id())) with check(account_id=private.arn_current_account_id() and exists(select 1 from public.arn_parts p where p.id=part_id and p.account_id=private.arn_current_account_id()));
 drop policy if exists arn_license_self on public.arn_account_licenses;
 create policy arn_license_self on public.arn_account_licenses for select using(account_id=private.arn_current_account_id());

-- License codes are deliberately not openly writable from the client.
drop policy if exists arn_license_codes_admin on public.arn_license_codes;
create policy arn_license_codes_admin on public.arn_license_codes for select using(private.arn_is_admin());

-- Self-heal existing Auth users whose profile/account was not created by an older trigger.
create or replace function public.arn_ensure_my_account(p_display_name text default null)
returns table(account_id uuid, display_name text, role text)
language plpgsql security definer set search_path=public as $$
declare aid uuid; nm text; existing_role text;
begin
 if auth.uid() is null then raise exception 'not_authenticated'; end if;
 select p.account_id,p.display_name,p.role into aid,nm,existing_role from public.arn_profiles p where p.id=auth.uid();
 if aid is null then
   nm:=coalesce(nullif(trim(p_display_name),''),split_part(coalesce((select email from auth.users where id=auth.uid()),'User'),'@',1),'User');
   insert into public.arn_accounts(name) values(nm) returning id into aid;
   insert into public.arn_profiles(id,account_id,display_name,role) values(auth.uid(),aid,nm,'user');
   existing_role:='user';
 else
   -- Free-access build: no demo or license record is created during account bootstrap.
   null;
 end if;
 return query select aid,nm,coalesce(existing_role,'user');
end; $$;
grant execute on function public.arn_ensure_my_account(text) to authenticated;

-- New auth user bootstrap. The role is always user. Admin is never granted by normal registration.
create or replace function public.arn_bootstrap_new_user() returns trigger
language plpgsql security definer set search_path=public as $$
declare aid uuid;
begin
 insert into public.arn_accounts(name) values(coalesce(new.raw_user_meta_data->>'name','ARN Store')) returning id into aid;
 insert into public.arn_profiles(id,account_id,display_name,role) values(new.id,aid,coalesce(new.raw_user_meta_data->>'name',split_part(new.email,'@',1)),'user');
 return new;
end; $$;
drop trigger if exists arn_on_auth_user on auth.users;
create trigger arn_on_auth_user after insert on auth.users for each row execute function public.arn_bootstrap_new_user();

-- Admin license generation. Only an authenticated profile with role=admin can call it.
create or replace function public.arn_admin_generate_license(p_plan text default 'user', p_duration_days integer default 365, p_count integer default 1)
returns table(code text, plan text, duration_days integer)
language plpgsql security definer set search_path=public as $$
declare i integer; c text;
begin
 if not private.arn_is_admin() then raise exception 'admin_required'; end if;
 if p_plan not in ('user','admin') then raise exception 'invalid_plan'; end if;
 if p_count < 1 or p_count > 100 then raise exception 'invalid_count'; end if;
 if p_plan='user' and (p_duration_days is null or p_duration_days < 1) then raise exception 'invalid_duration'; end if;
 for i in 1..p_count loop
   loop
     c:='ARN-'||upper(p_plan)||'-'||upper(encode(gen_random_bytes(2),'hex'))||'-'||upper(encode(gen_random_bytes(2),'hex'))||'-'||upper(encode(gen_random_bytes(2),'hex'));
     exit when not exists(select 1 from public.arn_license_codes where arn_license_codes.code=c);
   end loop;
   insert into public.arn_license_codes(code,plan,duration_days,created_by) values(c,p_plan,case when p_plan='admin' then null else p_duration_days end,auth.uid());
   return query select c,p_plan,case when p_plan='admin' then null else p_duration_days end;
 end loop;
end; $$;

-- License activation. A code can be activated once and becomes tied to the caller's account.
create or replace function public.arn_activate_license(p_code text)
returns jsonb
language plpgsql security definer set search_path=public as $$
declare aid uuid; lc public.arn_license_codes%rowtype; exp timestamptz;
begin
 aid:=private.arn_current_account_id(); if aid is null then raise exception 'account_required'; end if;
 select * into lc from public.arn_license_codes where upper(code)=upper(trim(p_code)) and is_active=true for update;
 if not found then raise exception 'license_invalid_or_used'; end if;
 if lc.account_id is not null and lc.account_id<>aid then raise exception 'license_already_used'; end if;
 if lc.plan='user' then exp:=now()+make_interval(days=>coalesce(lc.duration_days,365)); else exp:=null; end if;
 update public.arn_license_codes set account_id=aid,is_active=false,activated_at=now() where code=lc.code;
 update public.arn_account_licenses set is_active=false where account_id=aid;
 insert into public.arn_account_licenses(account_id,license_type,starts_at,expires_at,code,is_active) values(aid,lc.plan,now(),exp,lc.code,true);
 return jsonb_build_object('ok',true,'plan',lc.plan,'expires_at',exp,'code',lc.code);
end; $$;

grant execute on function public.arn_admin_generate_license(text,integer,integer) to authenticated;
grant execute on function public.arn_activate_license(text) to authenticated;


-- Admin license management: disable/enable unused codes and renew an issued user license.
create or replace function public.arn_admin_set_license_active(p_code text, p_active boolean)
returns jsonb
language plpgsql security definer set search_path=public as $$
declare aid uuid;
begin
 if not private.arn_is_admin() then raise exception 'admin_required'; end if;
 update public.arn_license_codes set is_active=p_active where upper(code)=upper(trim(p_code)) returning account_id into aid;
 if not found then raise exception 'license_not_found'; end if;
 if aid is not null then
   if not p_active then
     update public.arn_account_licenses set is_active=false where account_id=aid and upper(code)=upper(trim(p_code));
   else
     update public.arn_account_licenses set is_active=true where account_id=aid and upper(code)=upper(trim(p_code)) and (expires_at is null or expires_at>=now());
   end if;
 end if;
 return jsonb_build_object('ok',true,'code',trim(p_code),'is_active',p_active);
end; $$;

grant execute on function public.arn_admin_set_license_active(text,boolean) to authenticated;

create or replace function public.arn_admin_renew_license(p_code text, p_duration_days integer)
returns jsonb
language plpgsql security definer set search_path=public as $$
declare lc public.arn_license_codes%rowtype; aid uuid; exp timestamptz;
begin
 if not private.arn_is_admin() then raise exception 'admin_required'; end if;
 if p_duration_days is null or p_duration_days < 1 then raise exception 'invalid_duration'; end if;
 select * into lc from public.arn_license_codes where upper(code)=upper(trim(p_code)) for update;
 if not found then raise exception 'license_not_found'; end if;
 if lc.plan<>'user' then raise exception 'only_user_license_can_be_renewed'; end if;
 update public.arn_license_codes set duration_days=p_duration_days,is_active=true where code=lc.code returning account_id into aid;
 exp:=now()+make_interval(days=>p_duration_days);
 if aid is not null then
   update public.arn_account_licenses set expires_at=exp,is_active=true where account_id=aid and code=lc.code;
 end if;
 return jsonb_build_object('ok',true,'code',lc.code,'duration_days',p_duration_days,'expires_at',exp);
end; $$;

grant execute on function public.arn_admin_renew_license(text,integer) to authenticated;


-- FIRST OWNER ADMIN SETUP (run once in Supabase SQL Editor after the owner account exists):
-- Replace the email below with the owner's email. Normal registration never grants admin.
-- update public.arn_profiles p set role='admin' from auth.users u where u.id=p.id and lower(u.email)=lower('EMAIL_ADMIN_ANDA');

-- ===== ARN Inventory Revisi 1002 final backend additions =====
alter table public.arn_stock_transactions add column if not exists movement_time time;
alter table public.arn_stock_transactions add column if not exists job_reference text;

create table if not exists public.arn_master_parts(
 id uuid primary key default gen_random_uuid(),
 master_key text not null unique,
 name text not null,
 code text,
 category text,
 unit text not null default 'pcs',
 source text,
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.arn_master_compatibilities(
 id uuid primary key default gen_random_uuid(),
 master_part_id uuid not null references public.arn_master_parts(id) on delete cascade,
 model text not null,
 normalized_model text not null,
 source text,
 created_at timestamptz not null default now(),
 unique(master_part_id,normalized_model)
);
alter table public.arn_master_parts enable row level security;
alter table public.arn_master_compatibilities enable row level security;
drop policy if exists arn_master_parts_read on public.arn_master_parts;
create policy arn_master_parts_read on public.arn_master_parts for select to authenticated using(true);
drop policy if exists arn_master_compat_read on public.arn_master_compatibilities;
create policy arn_master_compat_read on public.arn_master_compatibilities for select to authenticated using(true);

create or replace function public.arn_guard_nonnegative_stock() returns trigger
language plpgsql security definer set search_path=public as $$
declare pid uuid; other_pid uuid; resulting integer; part_account uuid;
begin
 if TG_OP='DELETE' then
   pid:=OLD.part_id;
   perform pg_advisory_xact_lock(hashtextextended(pid::text,0));
   select coalesce(sum(case when transaction_type='in' then quantity when transaction_type='out' then -quantity else 0 end),0) into resulting
   from public.arn_stock_transactions where part_id=pid and id<>OLD.id;
   if resulting<0 then raise exception 'stock_would_be_negative'; end if;
   return OLD;
 end if;
 pid:=NEW.part_id;
 select account_id into part_account from public.arn_parts where id=pid;
 if part_account is null or part_account<>NEW.account_id then raise exception 'part_account_mismatch'; end if;
 perform pg_advisory_xact_lock(hashtextextended(pid::text,0));
 if TG_OP='UPDATE' and OLD.part_id<>NEW.part_id then
   other_pid:=OLD.part_id;
   perform pg_advisory_xact_lock(hashtextextended(other_pid::text,0));
   select coalesce(sum(case when transaction_type='in' then quantity when transaction_type='out' then -quantity else 0 end),0) into resulting
   from public.arn_stock_transactions where part_id=other_pid and id<>OLD.id;
   if resulting<0 then raise exception 'stock_would_be_negative'; end if;
 end if;
 if TG_OP='INSERT' then
   select coalesce(sum(case when transaction_type='in' then quantity when transaction_type='out' then -quantity else 0 end),0) into resulting
   from public.arn_stock_transactions where part_id=pid;
 else
   select coalesce(sum(case when transaction_type='in' then quantity when transaction_type='out' then -quantity else 0 end),0) into resulting
   from public.arn_stock_transactions where part_id=pid and id<>OLD.id;
 end if;
 if NEW.transaction_type='in' then resulting:=resulting+NEW.quantity; else resulting:=resulting-NEW.quantity; end if;
 if resulting<0 then raise exception 'stock_would_be_negative'; end if;
 return NEW;
end; $$;
drop trigger if exists arn_guard_stock_nonnegative on public.arn_stock_transactions;
create trigger arn_guard_stock_nonnegative before insert or update or delete on public.arn_stock_transactions for each row execute function public.arn_guard_nonnegative_stock();
