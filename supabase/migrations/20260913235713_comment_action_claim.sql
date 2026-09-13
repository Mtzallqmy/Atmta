begin;

create function public.claim_comment_action(p_comment_id uuid)
returns setof public.comment_actions
language plpgsql
security invoker
set search_path = ''
as $$
declare
  c public.comments;
  r public.comment_rules;
  selected_action public.comment_action_type;
  selected_response text;
  app_tz text;
  ai_auto_enabled boolean;
begin
  select * into c from public.comments where id = p_comment_id for update;
  if c.id is null or c.replied or exists (select 1 from public.comment_actions a where a.comment_id = c.id) then return; end if;
  if c.facebook_user_id = (select p.page_id from public.facebook_pages p where p.id = c.page_id) then return; end if;

  app_tz := coalesce((select s.value #>> '{}' from public.system_settings s where s.key = 'app_timezone'), 'Asia/Aden');
  ai_auto_enabled := coalesce((select (s.value ->> 'auto_reply_enabled')::boolean from public.system_settings s where s.key = 'ai'), false);

  select rule.* into r
  from public.comment_rules rule
  where rule.enabled and (rule.page_id is null or rule.page_id = c.page_id)
    and case rule.match_type
      when 'contains' then exists (select 1 from jsonb_array_elements_text(rule.keywords) k where position(lower(k) in lower(c.message)) > 0)
      when 'equals' then exists (select 1 from jsonb_array_elements_text(rule.keywords) k where lower(c.message) = lower(k))
      when 'starts_with' then exists (select 1 from jsonb_array_elements_text(rule.keywords) k where lower(c.message) like lower(k) || '%')
      when 'has_any_keywords' then exists (select 1 from jsonb_array_elements_text(rule.keywords) k where position(lower(k) in lower(c.message)) > 0)
      when 'regex' then c.message ~* rule.regex_pattern
    end
    and not exists (
      select 1 from public.comment_actions a join public.comments prior on prior.id = a.comment_id
      where a.rule_id = rule.id and prior.facebook_user_id = c.facebook_user_id
        and a.created_at > now() - make_interval(mins => rule.cooldown_minutes)
        and a.status not in ('failed', 'ignored')
    )
    and (
      select count(*) from public.comment_actions a join public.comments prior on prior.id = a.comment_id
      where a.rule_id = rule.id and prior.facebook_user_id = c.facebook_user_id
        and (a.created_at at time zone app_tz)::date = (now() at time zone app_tz)::date
        and a.status not in ('failed', 'ignored')
    ) < rule.max_replies_per_user_per_day
  order by rule.priority, rule.created_at
  limit 1;

  if r.id is null then
    selected_action := 'send_for_review';
  elsif r.response_mode = 'rule_auto' then
    selected_action := 'reply'; selected_response := r.response_template;
  elsif r.response_mode = 'ai_auto' and ai_auto_enabled then
    selected_action := 'send_for_review'; -- AI generation still needs a separate guarded provider step.
  else
    selected_action := 'send_for_review';
  end if;

  return query
  insert into public.comment_actions (comment_id, rule_id, action, response_text, status)
  values (c.id, r.id, selected_action, selected_response, 'pending')
  on conflict (comment_id, action) do nothing
  returning *;
end;
$$;

revoke all on function public.claim_comment_action(uuid) from public, anon, authenticated;
grant execute on function public.claim_comment_action(uuid) to service_role;

commit;
