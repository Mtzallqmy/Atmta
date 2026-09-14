begin;

create function api.agent_get_daily_stats(p_agent_id text, p_token text, p_local_date date)
returns public.friend_request_stats
language plpgsql
stable
security definer
set search_path = ''
as $$
declare result public.friend_request_stats;
begin
  if not private.agent_token_valid(p_agent_id, p_token) then raise exception 'unauthorized agent' using errcode = '28000'; end if;
  select * into result from public.friend_request_stats where agent_id = p_agent_id and local_date = p_local_date;
  return result;
end;
$$;

create function api.agent_set_next_run(p_agent_id text, p_token text, p_next_run_at timestamptz)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.agent_token_valid(p_agent_id, p_token) then raise exception 'unauthorized agent' using errcode = '28000'; end if;
  update public.agent_settings set next_run_at = p_next_run_at, updated_at = now() where agent_id = p_agent_id;
end;
$$;

create function api.agent_safety_stop(p_agent_id text, p_token text, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.agent_token_valid(p_agent_id, p_token) then raise exception 'unauthorized agent' using errcode = '28000'; end if;
  update public.agent_settings set enabled = false, updated_at = now() where agent_id = p_agent_id;
  insert into public.agent_status (agent_id, online, state, last_seen_at, metadata)
  values (p_agent_id, true, 'safety_stopped', now(), jsonb_build_object('reason', left(p_reason, 500)))
  on conflict (agent_id) do update set online = true, state = 'safety_stopped', last_seen_at = now(), metadata = excluded.metadata;
  insert into public.automation_logs (source, action, level, message, metadata)
  values ('local-agent', 'safety_stop', 'security', 'Local Agent stopped after a Facebook safety signal', jsonb_build_object('agent_id', p_agent_id, 'reason', left(p_reason, 500)));
end;
$$;

revoke all on function api.agent_get_daily_stats(text, text, date) from public, authenticated;
revoke all on function api.agent_set_next_run(text, text, timestamptz) from public, authenticated;
revoke all on function api.agent_safety_stop(text, text, text) from public, authenticated;
grant execute on function api.agent_get_daily_stats(text, text, date) to anon;
grant execute on function api.agent_set_next_run(text, text, timestamptz) to anon;
grant execute on function api.agent_safety_stop(text, text, text) to anon;

commit;
