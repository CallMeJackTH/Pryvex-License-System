-- Existing handoff rows keep their original expiry and one-time behavior.
-- New admin-issued access codes can be permanent and reusable.
alter table public.protected_lua_handoffs
  alter column expires_at drop not null;

alter table public.protected_lua_handoffs
  add column if not exists is_permanent boolean not null default false;
