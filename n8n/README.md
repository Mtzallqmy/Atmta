# n8n Workflows

Workflow exports are stored in `workflows/`. Exports never contain credential values.

## Import order

1. `00-meta-page-sync.json` (manual connectivity and page sync)
2. `01-telegram-control-router.json`
3. `02-publish-now.json`
4. `03-scheduled-publisher.json`
5. `04-meta-comments-webhook.json`

Keep workflows inactive until credentials and n8n Variables are configured.

## Required credentials

- `Atmta Telegram Bot` (`telegramApi`)
- `Atmta Supabase` (`supabaseApi`, service-role key; trusted n8n only)
- `Meta User Token` (`httpHeaderAuth`; `Authorization: Bearer …`)
- `Meta Page Token` (`httpHeaderAuth`; configure `Authorization: OAuth …` for publishing and Reels upload)

Replace placeholder credential IDs after import. Create n8n Variables `SUPABASE_URL`, `META_GRAPH_API_VERSION`, `PUBLISH_WORKFLOW_ID`, `META_WEBHOOK_VERIFY_TOKEN`, and `META_APP_SECRET`. For production, source the two Meta secrets from n8n External Secrets/runtime secret configuration when available rather than ordinary shared Variables.

`04` requires raw webhook bodies. Do not activate it until a test with `meta-comment-event.json` plus a correctly calculated signature passes; unsigned or reconstructed JSON bodies are deliberately rejected.
