begin;

create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;
create schema if not exists api;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;
grant usage on schema api to anon, service_role;

create type public.post_type as enum ('text', 'image', 'video', 'reel');
create type public.post_status as enum ('draft', 'awaiting_approval', 'scheduled', 'processing', 'published', 'failed', 'cancelled');
create type public.comment_match_type as enum ('contains', 'equals', 'starts_with', 'regex', 'has_any_keywords');
create type public.comment_response_mode as enum ('manual', 'rule_auto', 'ai_draft', 'ai_auto');
create type public.comment_action_type as enum ('reply', 'ignore', 'hide', 'delete', 'send_for_review');
create type public.action_status as enum ('pending', 'approved', 'processing', 'done', 'failed', 'ignored');
create type public.agent_command_status as enum ('queued', 'running', 'done', 'failed', 'cancelled');
create type public.log_level as enum ('info', 'warning', 'error', 'security');

create table public.system_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (length(key) between 1 and 120),
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.telegram_admins (
  telegram_user_id bigint primary key,
  chat_id bigint not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique (telegram_user_id, chat_id)
);

create table public.telegram_sessions (
  id uuid primary key default gen_random_uuid(),
  telegram_user_id bigint not null,
  chat_id bigint not null,
  state text not null check (length(state) between 1 and 120),
  payload jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (telegram_user_id, chat_id)
);

create table public.meta_connections (
  id uuid primary key default gen_random_uuid(),
  meta_user_id text not null unique,
  status text not null default 'disconnected' check (status in ('connected', 'expired', 'revoked', 'disconnected')),
  token_reference text,
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.facebook_pages (
  id uuid primary key default gen_random_uuid(),
  meta_connection_id uuid references public.meta_connections(id) on delete set null,
  page_id text not null unique,
  name text not null,
  username text,
  picture_url text,
  enabled boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.facebook_pages(id) on delete restrict,
  type public.post_type not null,
  text_content text,
  media_urls jsonb not null default '[]'::jsonb check (jsonb_typeof(media_urls) = 'array'),
  status public.post_status not null default 'draft',
  scheduled_at timestamptz,
  published_at timestamptz,
  facebook_post_id text unique,
  idempotency_key uuid not null default gen_random_uuid() unique,
  error_message text,
  created_by_telegram_user_id bigint not null,
  processing_started_at timestamptz,
  attempt_count integer not null default 0 check (attempt_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint posts_content_required check (text_content is not null or jsonb_array_length(media_urls) > 0),
  constraint scheduled_time_required check (status <> 'scheduled' or scheduled_at is not null),
  constraint published_fields_consistent check (status <> 'published' or (published_at is not null and facebook_post_id is not null))
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.facebook_pages(id) on delete cascade,
  facebook_comment_id text not null unique,
  facebook_post_id text not null,
  facebook_user_id text,
  facebook_user_name text,
  message text not null default '',
  parent_comment_id text,
  created_time timestamptz,
  received_at timestamptz not null default now(),
  replied boolean not null default false,
  metadata jsonb not null default '{}'::jsonb
);

create table public.comment_rules (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  page_id uuid references public.facebook_pages(id) on delete cascade,
  enabled boolean not null default true,
  priority integer not null default 100 check (priority >= 0),
  match_type public.comment_match_type not null,
  keywords jsonb not null default '[]'::jsonb check (jsonb_typeof(keywords) = 'array'),
  regex_pattern text,
  response_mode public.comment_response_mode not null default 'manual',
  response_template text,
  cooldown_minutes integer not null default 60 check (cooldown_minutes >= 0),
  max_replies_per_user_per_day integer not null default 3 check (max_replies_per_user_per_day > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint regex_pattern_required check (match_type <> 'regex' or regex_pattern is not null),
  constraint automated_response_required check (response_mode not in ('rule_auto', 'ai_auto') or response_template is not null)
);

create table public.comment_actions (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.comments(id) on delete cascade,
  rule_id uuid references public.comment_rules(id) on delete set null,
  action public.comment_action_type not null,
  response_text text,
  status public.action_status not null default 'pending',
  error text,
  created_at timestamptz not null default now(),
  executed_at timestamptz,
  unique (comment_id, action)
);

create table public.automation_logs (
  id bigint generated by default as identity primary key,
  source text not null check (source in ('telegram', 'n8n', 'meta', 'scheduler', 'comments', 'local-agent', 'friend-requests')),
  action text not null,
  level public.log_level not null default 'info',
  message text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.agent_settings (
  id uuid primary key default gen_random_uuid(),
  agent_id text not null unique check (agent_id ~ '^[a-zA-Z0-9_-]{1,64}$'),
  enabled boolean not null default false,
  batch_size integer not null default 20 check (batch_size between 1 and 50),
  interval_minutes integer not null default 30 check (interval_minutes in (10, 30, 60)),
  daily_limit integer not null default 100 check (daily_limit between 1 and 200),
  timezone text not null default 'Asia/Aden',
  next_run_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.agent_status (
  agent_id text primary key references public.agent_settings(agent_id) on delete cascade,
  online boolean not null default false,
  state text not null default 'offline' check (state in ('offline', 'idle', 'running', 'paused', 'safety_stopped', 'daily_limit_reached', 'error')),
  last_seen_at timestamptz,
  current_task text,
  version text,
  metadata jsonb not null default '{}'::jsonb
);

create table public.friend_request_stats (
  id uuid primary key default gen_random_uuid(),
  agent_id text not null references public.agent_settings(agent_id) on delete cascade,
  local_date date not null,
  accepted_count integer not null default 0 check (accepted_count >= 0),
  failed_count integer not null default 0 check (failed_count >= 0),
  last_batch_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (agent_id, local_date)
);

create table public.agent_commands (
  id uuid primary key default gen_random_uuid(),
  agent_id text not null references public.agent_settings(agent_id) on delete cascade,
  type text not null check (type in ('run_friend_batch', 'pause', 'resume', 'open_browser', 'health_check')),
  payload jsonb not null default '{}'::jsonb,
  status public.agent_command_status not null default 'queued',
  created_at timestamptz not null default now(),
  claimed_at timestamptz,
  completed_at timestamptz,
  result jsonb,
  error text
);

create table private.agent_credentials (
  agent_id text primary key references public.agent_settings(agent_id) on delete cascade,
  token_hash text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  rotated_at timestamptz not null default now()
);
alter table private.agent_credentials enable row level security;
grant select, insert, update, delete on private.agent_credentials to service_role;

create index posts_due_idx on public.posts (scheduled_at, id) where status = 'scheduled';
create index posts_status_created_idx on public.posts (status, created_at desc);
create index telegram_sessions_expiry_idx on public.telegram_sessions (expires_at);
create index comments_page_received_idx on public.comments (page_id, received_at desc);
create index comments_unreplied_idx on public.comments (received_at) where replied = false;
create index comment_rules_match_idx on public.comment_rules (enabled, page_id, priority);
create index comment_actions_status_idx on public.comment_actions (status, created_at);
create index automation_logs_created_idx on public.automation_logs (created_at desc);
create index automation_logs_level_idx on public.automation_logs (level, created_at desc);
create index agent_commands_claim_idx on public.agent_commands (agent_id, created_at) where status = 'queued';
create index friend_stats_agent_date_idx on public.friend_request_stats (agent_id, local_date desc);

create function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger system_settings_updated before update on public.system_settings for each row execute function private.set_updated_at();
create trigger telegram_sessions_updated before update on public.telegram_sessions for each row execute function private.set_updated_at();
create trigger meta_connections_updated before update on public.meta_connections for each row execute function private.set_updated_at();
create trigger facebook_pages_updated before update on public.facebook_pages for each row execute function private.set_updated_at();
create trigger posts_updated before update on public.posts for each row execute function private.set_updated_at();
create trigger comment_rules_updated before update on public.comment_rules for each row execute function private.set_updated_at();
create trigger agent_settings_updated before update on public.agent_settings for each row execute function private.set_updated_at();
create trigger friend_stats_updated before update on public.friend_request_stats for each row execute function private.set_updated_at();

create function public.claim_due_posts(p_limit integer default 20)
returns setof public.posts
language sql
security invoker
set search_path = ''
as $$
  with claimed as (
    select p.id
    from public.posts p
    where p.status = 'scheduled'
      and p.scheduled_at <= now()
    order by p.scheduled_at, p.id
    for update skip locked
    limit least(greatest(p_limit, 1), 100)
  )
  update public.posts p
  set status = 'processing',
      processing_started_at = now(),
      attempt_count = p.attempt_count + 1,
      updated_at = now()
  from claimed
  where p.id = claimed.id
  returning p.*;
$$;

create function private.agent_token_valid(p_agent_id text, p_token text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.agent_credentials c
    where c.agent_id = p_agent_id
      and c.enabled
      and c.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
  );
$$;

create function private.register_agent_credential(p_agent_id text, p_token text)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into private.agent_credentials (agent_id, token_hash)
  values (p_agent_id, encode(extensions.digest(p_token, 'sha256'), 'hex'))
  on conflict (agent_id) do update
  set token_hash = excluded.token_hash, enabled = true, rotated_at = now();
$$;

revoke all on function private.agent_token_valid(text, text) from public, anon, authenticated;

create function api.agent_get_settings(p_agent_id text, p_token text)
returns public.agent_settings
language plpgsql
stable
security definer
set search_path = ''
as $$
declare result public.agent_settings;
begin
  if not private.agent_token_valid(p_agent_id, p_token) then
    raise exception 'unauthorized agent' using errcode = '28000';
  end if;
  select * into result from public.agent_settings where agent_id = p_agent_id;
  return result;
end;
$$;

create function api.agent_claim_commands(p_agent_id text, p_token text, p_limit integer default 10)
returns setof public.agent_commands
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.agent_token_valid(p_agent_id, p_token) then
    raise exception 'unauthorized agent' using errcode = '28000';
  end if;
  return query
  with claimed as (
    select c.id
    from public.agent_commands c
    where c.agent_id = p_agent_id and c.status = 'queued'
    order by c.created_at
    for update skip locked
    limit least(greatest(p_limit, 1), 25)
  )
  update public.agent_commands c
  set status = 'running', claimed_at = now()
  from claimed
  where c.id = claimed.id
  returning c.*;
end;
$$;

create function api.agent_heartbeat(p_agent_id text, p_token text, p_state text, p_current_task text default null, p_version text default null, p_metadata jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.agent_token_valid(p_agent_id, p_token) then
    raise exception 'unauthorized agent' using errcode = '28000';
  end if;
  if p_state not in ('offline', 'idle', 'running', 'paused', 'safety_stopped', 'daily_limit_reached', 'error') then
    raise exception 'invalid agent state';
  end if;
  insert into public.agent_status (agent_id, online, state, last_seen_at, current_task, version, metadata)
  values (p_agent_id, true, p_state, now(), p_current_task, p_version, coalesce(p_metadata, '{}'::jsonb))
  on conflict (agent_id) do update
  set online = true, state = excluded.state, last_seen_at = now(), current_task = excluded.current_task,
      version = excluded.version, metadata = excluded.metadata;
end;
$$;

create function api.agent_complete_command(p_agent_id text, p_token text, p_command_id uuid, p_succeeded boolean, p_result jsonb default null, p_error text default null)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare changed integer;
begin
  if not private.agent_token_valid(p_agent_id, p_token) then
    raise exception 'unauthorized agent' using errcode = '28000';
  end if;
  update public.agent_commands
  set status = case when p_succeeded then 'done'::public.agent_command_status else 'failed'::public.agent_command_status end,
      completed_at = now(), result = p_result, error = case when p_succeeded then null else left(p_error, 1000) end
  where id = p_command_id and agent_id = p_agent_id and status = 'running';
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

create function api.agent_record_friend_result(p_agent_id text, p_token text, p_local_date date, p_accepted boolean)
returns public.friend_request_stats
language plpgsql
security definer
set search_path = ''
as $$
declare result public.friend_request_stats;
begin
  if not private.agent_token_valid(p_agent_id, p_token) then
    raise exception 'unauthorized agent' using errcode = '28000';
  end if;
  insert into public.friend_request_stats (agent_id, local_date, accepted_count, failed_count, last_batch_at)
  values (p_agent_id, p_local_date, case when p_accepted then 1 else 0 end, case when p_accepted then 0 else 1 end, now())
  on conflict (agent_id, local_date) do update
  set accepted_count = public.friend_request_stats.accepted_count + case when p_accepted then 1 else 0 end,
      failed_count = public.friend_request_stats.failed_count + case when p_accepted then 0 else 1 end,
      last_batch_at = now(), updated_at = now()
  returning * into result;
  return result;
end;
$$;

alter table public.system_settings enable row level security;
alter table public.telegram_admins enable row level security;
alter table public.telegram_sessions enable row level security;
alter table public.meta_connections enable row level security;
alter table public.facebook_pages enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.comment_rules enable row level security;
alter table public.comment_actions enable row level security;
alter table public.automation_logs enable row level security;
alter table public.agent_settings enable row level security;
alter table public.agent_status enable row level security;
alter table public.friend_request_stats enable row level security;
alter table public.agent_commands enable row level security;

revoke all on all tables in schema public from anon, authenticated;
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
revoke all on function public.claim_due_posts(integer) from public, anon, authenticated;
grant execute on function public.claim_due_posts(integer) to service_role;
revoke all on all functions in schema api from public, authenticated;
grant execute on function api.agent_get_settings(text, text) to anon;
grant execute on function api.agent_claim_commands(text, text, integer) to anon;
grant execute on function api.agent_heartbeat(text, text, text, text, text, jsonb) to anon;
grant execute on function api.agent_complete_command(text, text, uuid, boolean, jsonb, text) to anon;
grant execute on function api.agent_record_friend_result(text, text, date, boolean) to anon;
revoke all on function private.register_agent_credential(text, text) from public, anon, authenticated;
grant execute on function private.register_agent_credential(text, text) to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('facebook-media', 'facebook-media', false, 104857600, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime'])
on conflict (id) do update set public = false;

commit;
