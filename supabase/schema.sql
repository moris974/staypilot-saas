-- StayPilot cloud MVP schema. Run once in Supabase SQL Editor in a NEW project.
-- Browser clients use only the publishable/anon key. RLS isolates host data.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  company text not null default '',
  role text not null default 'host' check (role in ('host','admin')),
  account_status text not null default 'active' check (account_status in ('active','suspended')),
  plan text not null default 'starter' check (plan in ('starter','professional','business')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.staypilot_new_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name, company)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name',''), coalesce(new.raw_user_meta_data ->> 'company',''))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists staypilot_auth_user_created on auth.users;
create trigger staypilot_auth_user_created after insert on auth.users
for each row execute function public.staypilot_new_profile();

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name text not null check (length(name) between 1 and 120),
  type text not null default 'Casa vacanze',
  address text not null default '',
  phone text not null default '',
  email text not null default '',
  checkin text not null default '15:00',
  checkout text not null default '10:00',
  wifi_name text not null default '',
  wifi_password text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.guides (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  title text not null check (length(title) between 1 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  status text not null default 'draft' check (status in ('draft','published')),
  language text not null default 'it',
  welcome text not null default '',
  description text not null default '',
  checkin_info text not null default '',
  checkout_info text not null default '',
  wifi_info text not null default '',
  house_rules text not null default '',
  local_tips text not null default '',
  address text not null default '',
  whatsapp text not null default '',
  theme text not null default '#b28a48',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles(id) on delete cascade,
  plan text not null default 'starter' check (plan in ('starter','professional','business')),
  status text not null default 'demo' check (status in ('demo','trialing','active','past_due','canceled','incomplete')),
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists properties_owner_idx on public.properties(owner_id);
create index if not exists guides_owner_idx on public.guides(owner_id);
create index if not exists guides_property_idx on public.guides(property_id);
create index if not exists guides_slug_idx on public.guides(slug);

alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.guides enable row level security;
alter table public.subscriptions enable row level security;

-- Remove all prior policies with these names to make this script repeatable.
drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles for select to authenticated using (id = (select auth.uid()));
-- Deliberately no browser UPDATE policy on profiles: users cannot self-assign admin/plan/status.

drop policy if exists properties_read_own on public.properties;
create policy properties_read_own on public.properties for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists properties_insert_own on public.properties;
create policy properties_insert_own on public.properties for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists properties_update_own on public.properties;
create policy properties_update_own on public.properties for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
drop policy if exists properties_delete_own on public.properties;
create policy properties_delete_own on public.properties for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists guides_read_own on public.guides;
create policy guides_read_own on public.guides for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists guides_read_published_public on public.guides;
create policy guides_read_published_public on public.guides for select to anon, authenticated using (status = 'published');
drop policy if exists guides_insert_own on public.guides;
create policy guides_insert_own on public.guides for insert to authenticated with check (
  owner_id = (select auth.uid()) and exists (select 1 from public.properties p where p.id = property_id and p.owner_id = (select auth.uid())
));
drop policy if exists guides_update_own on public.guides;
create policy guides_update_own on public.guides for update to authenticated using (owner_id = (select auth.uid())) with check (
  owner_id = (select auth.uid()) and exists (select 1 from public.properties p where p.id = property_id and p.owner_id = (select auth.uid())
));
drop policy if exists guides_delete_own on public.guides;
create policy guides_delete_own on public.guides for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists subscriptions_read_own on public.subscriptions;
create policy subscriptions_read_own on public.subscriptions for select to authenticated using (owner_id = (select auth.uid()));
-- Subscription writes intentionally server-only, pending Stripe webhook implementation.

grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.properties to authenticated;
grant select, insert, update, delete on public.guides to authenticated;
grant select on public.guides to anon;
grant select on public.subscriptions to authenticated;
