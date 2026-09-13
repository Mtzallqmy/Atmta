begin;

create function public.cancel_scheduled_post(p_post_id uuid)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare changed integer;
begin
  update public.posts
  set status = 'cancelled', updated_at = now()
  where id = p_post_id and status in ('draft', 'awaiting_approval', 'scheduled');
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

create function public.reschedule_post(p_post_id uuid, p_scheduled_at timestamptz)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare changed integer;
begin
  if p_scheduled_at <= now() then raise exception 'scheduled time must be in the future'; end if;
  update public.posts
  set status = 'scheduled', scheduled_at = p_scheduled_at, error_message = null, updated_at = now()
  where id = p_post_id and status in ('draft', 'awaiting_approval', 'scheduled', 'failed');
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

revoke all on function public.cancel_scheduled_post(uuid) from public, anon, authenticated;
revoke all on function public.reschedule_post(uuid, timestamptz) from public, anon, authenticated;
grant execute on function public.cancel_scheduled_post(uuid) to service_role;
grant execute on function public.reschedule_post(uuid, timestamptz) to service_role;

commit;
