begin;

create function public.daily_summary(p_timezone text default 'Asia/Aden')
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'local_date', (now() at time zone p_timezone)::date,
    'posts', jsonb_build_object(
      'published', (select count(*) from public.posts where status = 'published' and (published_at at time zone p_timezone)::date = (now() at time zone p_timezone)::date),
      'scheduled', (select count(*) from public.posts where status = 'scheduled'),
      'failed', (select count(*) from public.posts where status = 'failed' and (updated_at at time zone p_timezone)::date = (now() at time zone p_timezone)::date)
    ),
    'comments', jsonb_build_object(
      'new', (select count(*) from public.comments where (received_at at time zone p_timezone)::date = (now() at time zone p_timezone)::date),
      'replied', (select count(*) from public.comments where replied and (received_at at time zone p_timezone)::date = (now() at time zone p_timezone)::date)
    ),
    'friends', coalesce((select sum(accepted_count) from public.friend_request_stats where local_date = (now() at time zone p_timezone)::date), 0),
    'agent', coalesce((select jsonb_build_object('online', online and last_seen_at > now() - interval '2 minutes', 'state', state, 'last_seen_at', last_seen_at) from public.agent_status order by last_seen_at desc nulls last limit 1), '{"online": false, "state": "offline"}'::jsonb)
  );
$$;

revoke all on function public.daily_summary(text) from public, anon, authenticated;
grant execute on function public.daily_summary(text) to service_role;

commit;
