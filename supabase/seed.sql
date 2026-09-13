insert into public.system_settings (key, value) values
  ('app_timezone', '"Asia/Aden"'::jsonb),
  ('ai', '{"provider": null, "model": null, "auto_reply_enabled": false}'::jsonb),
  ('telegram_session_ttl_minutes', '30'::jsonb)
on conflict (key) do update set value = excluded.value;

insert into public.agent_settings (agent_id, enabled, batch_size, interval_minutes, daily_limit, timezone)
values ('primary', false, 20, 30, 100, 'Asia/Aden')
on conflict (agent_id) do nothing;
