# QA and Security Checklist

Automated by `pnpm validate` and GitHub Actions:

- TypeScript strict typecheck.
- Local Agent unit tests: config, limits, date rollover, counter reconciliation, safety signals.
- Telegram and Meta webhook fixture checks, including tampered-body HMAC rejection.
- n8n JSON parsing, required workflow inventory, unique node IDs/names, and connection integrity.
- Environment template completeness.
- Tracked-path and credential-pattern scan.
- PostgreSQL 17 migration execution, seed execution, RLS checks, atomic scheduling claim, cancel/reschedule, and idempotent comment-action claim.

Manual checks that require external credentials:

- Import every workflow into the target n8n workspace and replace credential IDs.
- Confirm Telegram callback rendering and all confirmation buttons.
- Apply Supabase migrations to a disposable/branch database, then run advisors.
- Test Meta Development Mode page sync and one test publication for every enabled media type.
- Validate webhook GET challenge and signed POST using the exact n8n production URL.
- Log into Facebook manually in the Local Agent profile; test with friend automation disabled first.
- Trigger a test checkpoint/safety page and confirm the agent disables itself.

No external-service test is marked passed until the relevant credentials are supplied.
