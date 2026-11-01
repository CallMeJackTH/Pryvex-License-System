-- Pryvex License System schema
-- Run in Supabase SQL Editor. The Edge Function uses the service role.
create extension if not exists pgcrypto;

create table if not exists public.license_keys (
    id uuid primary key default gen_random_uuid(),
    key_hash text not null unique,
    key_prefix text not null,
    key_encrypted text,
    plan text not null default 'premium' check (plan = 'premium'),
    status text not null default 'active'
        check (status in ('active', 'disabled', 'banned')),
    expires_at timestamptz,
    bound_device_hash text,
    discord_id_label text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    last_verified_at timestamptz
);

-- Safe migrations for existing installations.
alter table public.license_keys add column if not exists key_encrypted text;
alter table public.license_keys add column if not exists plan text not null default 'premium';
alter table public.license_keys drop constraint if exists license_keys_plan_check;
alter table public.license_keys add constraint license_keys_plan_check check (plan = 'premium');

create index if not exists license_keys_status_idx
    on public.license_keys(status);
create index if not exists license_keys_created_at_idx
    on public.license_keys(created_at desc);

-- Tombstones preserve deleted-key fingerprints so an old key can be identified as deleted.
-- Only the server-side Edge Function can read or write this table.
create table if not exists public.license_key_revocations (
    key_hash text primary key,
    key_prefix text not null,
    deleted_at timestamptz not null default now()
);

alter table public.license_key_revocations enable row level security;
revoke all on public.license_key_revocations from anon, authenticated;

create table if not exists public.license_events (
    id bigint generated always as identity primary key,
    license_id uuid references public.license_keys(id) on delete set null,
    event_type text not null,
    detail jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists license_events_created_at_idx
    on public.license_events(created_at desc);
create index if not exists license_events_license_id_idx
    on public.license_events(license_id);

-- Atomic device binding. Recreate the function so its return signature is
-- consistent on both fresh installs and databases created by older releases.
drop function if exists public.claim_license_device(text, text, text);

create function public.claim_license_device(
    p_key_hash text,
    p_device_hash text,
    p_discord_id_label text default null
)
returns table (
    license_id uuid,
    license_status text,
    expires_at timestamptz,
    device_matches boolean,
    license_plan text
)
language plpgsql
security definer
set search_path = public
as $$
begin
    return query
    update public.license_keys k
       set bound_device_hash = coalesce(k.bound_device_hash, p_device_hash),
           discord_id_label = coalesce(k.discord_id_label, p_discord_id_label),
           last_verified_at = now(),
           updated_at = now()
     where k.key_hash = p_key_hash
       and k.status = 'active'
       and (k.expires_at is null or k.expires_at > now())
       and (k.bound_device_hash is null or k.bound_device_hash = p_device_hash)
    returning k.id, k.status, k.expires_at,
              (k.bound_device_hash = p_device_hash),
              k.plan;
end;
$$;

-- No direct client access to license data.
alter table public.license_keys enable row level security;
alter table public.license_events enable row level security;

revoke all on public.license_keys from anon, authenticated;
revoke all on public.license_events from anon, authenticated;
revoke all on function public.claim_license_device(text, text, text) from public, anon, authenticated;
grant execute on function public.claim_license_device(text, text, text) to service_role;
