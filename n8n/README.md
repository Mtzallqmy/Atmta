# n8n Workflows

Workflow exports are stored in `workflows/`. Exports never contain credential values.

## Import order

1. `01-telegram-control-router.json`

Keep workflows inactive until credentials and n8n Variables are configured.

## Required credentials

- `Atmta Telegram Bot` (`telegramApi`)
- `Atmta Supabase` (`supabaseApi`, service-role key; trusted n8n only)

Replace placeholder credential IDs after import. Create the n8n Variable `SUPABASE_URL` with the project URL.
