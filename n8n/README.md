# n8n Workflows

Workflow exports are stored in `workflows/`. Exports never contain credential values.

## Import order

1. `00-meta-page-sync.json` (manual connectivity and page sync)
2. `01-telegram-control-router.json`
3. `02-publish-now.json`
4. `03-scheduled-publisher.json`
5. `04-meta-comments-webhook.json`
6. `05-comment-automation.json`
7. `06-local-agent-notifications.json`
8. `07-daily-summary.json`
9. `08-error-handler.json`

Keep workflows inactive until credentials and n8n Variables are configured.

## Required credentials

- `Atmta Telegram Bot` (`telegramApi`)
- `Atmta Supabase` (`supabaseApi`, service-role key; trusted n8n only)
- `Meta User Token` (`httpHeaderAuth`; `Authorization: Bearer …`)
- `Meta Page Token` (`httpHeaderAuth`; configure `Authorization: OAuth …` for publishing and Reels upload)

Replace placeholder credential IDs after import. Create n8n Variables `SUPABASE_URL`, `META_GRAPH_API_VERSION`, `PUBLISH_WORKFLOW_ID`, `COMMENT_AUTOMATION_WORKFLOW_ID`, `META_WEBHOOK_VERIFY_TOKEN`, and `META_APP_SECRET`. For production, source the two Meta secrets from n8n External Secrets/runtime secret configuration when available rather than ordinary shared Variables.

`04` requires raw webhook bodies. Do not activate it until a test with `meta-comment-event.json` plus a correctly calculated signature passes; unsigned or reconstructed JSON bodies are deliberately rejected.

Import `08` first if you want to assign it as the Error Workflow while configuring the remaining workflows. After importing, set it manually as Error Workflow for 01–07. Activate order: 08, 02, 05, 00 (manual only), 01, 04, 03, 06, 07.
