# Troubleshooting

## Telegram لا يستجيب

- تحقق من credential وتفعيل Workflow 01.
- أضف user/chat IDs إلى `telegram_admins`.
- Telegram يسمح بWebhook واحد للبوت؛ أوقف أي Workflow/خدمة قديمة تستخدم التوكن نفسه.

## Supabase يعيد 401/403 أو table not found

- تأكد أن n8n يستخدم service-role داخل credential موثوق.
- أضف schema `api` إلى Exposed schemas للـAgent RPCs.
- طبّق migrations بالترتيب؛ GRANT وRLS طبقتان منفصلتان.
- شغّل advisors بعد الربط.

## Meta OAuth أو Permission error

- لا تعمل retry بلا نهاية.
- تحقق من Graph API version، token expiry، page role، Advanced Access وApp Review.
- في Development Mode استخدم مستخدمًا/صفحة ضمن أدوار التطبيق.

## Webhook verification يعمل وPOST يفشل

- فعّل raw body في Webhook node.
- تحقق من `META_APP_SECRET` ومن header `X-Hub-Signature-256`.
- لا تعِد serialize للـJSON قبل HMAC؛ يجب استخدام bytes الأصلية.

## المنشور عالق processing

لا تعِد نشره تلقائيًا قبل فحص صفحة Facebook؛ قد يكون Meta نجح قبل تعطل حفظ النتيجة. صحح الحالة يدويًا أو ألغِه بعد التحقق لتجنب duplicate post.

## Local Agent offline

- شغّله من `apps/local-agent` حتى يجد `.env` وملفات الحالة في المكان المتوقع.
- تحقق من `api` schema وAgent token hash.
- ثبّت Chromium عبر Playwright.
- عند safety stop افتح Facebook يدويًا؛ لا تحذف profile بهدف تجاوز check.
