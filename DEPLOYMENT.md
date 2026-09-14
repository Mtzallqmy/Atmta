# Deployment

## Recommended

- n8n Cloud: workflows وwebhooks.
- Supabase Cloud: PostgreSQL وprivate Storage.
- Telegram Bot API: واجهة التحكم.
- Meta Developer App: Pages API وWebhooks.
- Local Agent: جهاز المستخدم، outbound traffic فقط.

طبّق الخطوات بالترتيب في [docs/setup-checklist.md](docs/setup-checklist.md). لا تفعّل schedulers أو webhooks قبل نجاح credentials والاختبارات اليدوية.

## Optional self-hosted n8n

على Railway/VPS/Docker استخدم PostgreSQL داخليًا لـn8n، volume دائمًا، HTTPS، `WEBHOOK_URL` عامًا صحيحًا، و`N8N_ENCRYPTION_KEY` قويًا محفوظًا خارج Git. اضبط timezone إلى `Asia/Aden` أو منطقتك. لا تستخدم SQLite لمسار production الذي يحتاج موثوقية أعلى.

## Release safety

- migrations تُختبر أولًا على مشروع/branch غير production.
- workflow exports تبقى `active: false` في Git.
- فعّل Error Handler أولًا، ثم subworkflows، ثم triggers/schedulers أخيرًا.
- احتفظ بنسخة export من n8n قبل أي تحديث كبير.
