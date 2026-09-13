# Atmta — Facebook Automation Manager

منصة أتمتة عربية لإدارة صفحات Facebook عبر Telegram، مع n8n كطبقة orchestration وSupabase كمصدر مركزي للحالة، وLocal Agent اختياري للعمليات المحلية المسموح بها.

> المشروع تحت البناء على الفرع `build/n8n-facebook-automation` وفق مراحل موثقة في [PROGRESS.md](PROGRESS.md).

## المعمارية المختصرة

- **Telegram Bot:** واجهة التحكم في MVP.
- **n8n:** استقبال الأحداث، النشر، الجدولة، التعليقات والتنبيهات.
- **Supabase:** PostgreSQL وStorage وحافلة أوامر Local Agent.
- **Meta Graph API:** التكامل الرسمي مع صفحات Facebook.
- **Local Agent:** Node.js + TypeScript + Playwright، بدون منفذ inbound أو تجاوزات أمنية.

لا يتضمن MVP لوحة ويب أو Redis أو worker مخصص.
