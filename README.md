# Atmta — Facebook Automation Manager

MVP عربي لإدارة صفحات Facebook من Telegram. يستخدم n8n للتنسيق، Supabase كمصدر وحيد للحالة وStorage، وLocal Agent اختياريًا لقبول طلبات الصداقة من جهاز المشغّل ضمن ضوابط توقف أمني صارمة.

## ما يحتويه المستودع

- 9 n8n workflow exports: مزامنة الصفحات، Telegram router، النشر، الجدولة، Webhook التعليقات، قواعد الرد، حالة Agent، التقرير اليومي، والأخطاء.
- Supabase migrations مع RLS وexplicit grants وatomic claims وRPCs محدودة للـAgent.
- Local Agent بـNode.js/TypeScript/Playwright، persistent profile محلي، dual counters، daily/batch limits، heartbeat وsafety stop.
- CI يشغّل typecheck و11 unit tests وfixture/HMAC tests وworkflow graph validation وفحص الأسرار، ويطبق migrations على PostgreSQL 17.

## التشغيل الأسرع

1. أنشئ مشروع Supabase Cloud واتبع [docs/supabase-setup.md](docs/supabase-setup.md).
2. أنشئ Telegram Bot عبر BotFather وسجّل admin IDs.
3. أنشئ n8n Cloud workspace واستورد الملفات حسب [docs/n8n-setup.md](docs/n8n-setup.md).
4. أنشئ Meta Developer App واتبع [docs/meta-setup.md](docs/meta-setup.md).
5. شغّل Local Agent من جهازك حسب [docs/local-agent.md](docs/local-agent.md).

```bash
pnpm install --frozen-lockfile
pnpm validate
```

## المعمارية

Telegram وMeta يتصلان بـn8n عبر HTTPS. n8n يقرأ ويكتب Supabase. Local Agent لا يفتح أي port؛ يسحب الأوامر outbound من Supabase ويكتب النتيجة. لا يتضمن MVP Dashboard أو Redis أو custom worker.

## الحالة

حزمة المصدر واختبارات mock/CI جاهزة. تفعيل الإنتاج يحتاج credentials واستيراد workflows واختبارات اتصال حقيقية؛ راجع [PROGRESS.md](PROGRESS.md) و[docs/setup-checklist.md](docs/setup-checklist.md).

## قيود مهمة

- كل وظائف الصفحات تستخدم Meta APIs الرسمية حسب صلاحيات التطبيق والمراجعة.
- قبول طلبات الصداقة Browser Automation وليس Meta API؛ قد تتغير واجهة Facebook أو يتوقف الحساب عند security checks.
- لا يحاول النظام تجاوز CAPTCHA أو checkpoint أو anti-abuse controls.
- امتثل لشروط Meta والقوانين المحلية، وابدأ بحدود منخفضة واختبار يدوي.
