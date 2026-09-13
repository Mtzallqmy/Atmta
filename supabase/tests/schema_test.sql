\set ON_ERROR_STOP on

do $$
declare unsecured integer;
begin
  select count(*) into unsecured
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;
  if unsecured <> 0 then raise exception '% public tables do not have RLS', unsecured; end if;
  if has_table_privilege('anon', 'public.posts', 'select') then
    raise exception 'anon must not have direct posts access';
  end if;
end;
$$;

insert into public.facebook_pages (page_id, name) values ('test-page', 'Test Page');
insert into public.posts (page_id, type, text_content, status, scheduled_at, created_by_telegram_user_id)
select id, 'text', 'test', 'scheduled', now() - interval '1 minute', 1 from public.facebook_pages where page_id = 'test-page';

do $$
declare first_count integer; second_count integer;
begin
  select count(*) into first_count from public.claim_due_posts(10);
  select count(*) into second_count from public.claim_due_posts(10);
  if first_count <> 1 or second_count <> 0 then
    raise exception 'claim_due_posts is not idempotent: first %, second %', first_count, second_count;
  end if;
end;
$$;

insert into public.posts (page_id, type, text_content, status, scheduled_at, created_by_telegram_user_id)
select id, 'text', 'future', 'scheduled', now() + interval '1 hour', 1 from public.facebook_pages where page_id = 'test-page';

do $$
declare future_id uuid; changed boolean;
begin
  select id into future_id from public.posts where text_content = 'future';
  select public.reschedule_post(future_id, now() + interval '2 hours') into changed;
  if not changed then raise exception 'reschedule failed'; end if;
  select public.cancel_scheduled_post(future_id) into changed;
  if not changed then raise exception 'cancel failed'; end if;
end;
$$;
