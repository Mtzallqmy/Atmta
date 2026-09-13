# Supabase Setup

## إنشاء المشروع

1. أنشئ مشروع Supabase Cloud.
2. من **API Settings → Exposed schemas** أضف schema باسم `api` بجانب `public` حتى يستطيع Local Agent استدعاء RPCs المحدودة.
3. اربط CLI ثم طبّق migrations:

   ```bash
   npx supabase login
   npx supabase link --project-ref YOUR_PROJECT_REF
   npx supabase db push
   ```

4. نفّذ `supabase/seed.sql` من SQL Editor أو عبر البيئة المحلية.
5. تأكد أن bucket الخاص `facebook-media` موجود وغير public.

## Local Agent credential

أنشئ توكنًا عشوائيًا طويلًا لكل agent. خزّن القيمة الخام في `.env` المحلي فقط باسم `AGENT_API_TOKEN`، ثم سجّل hash من SQL Editor بصلاحية إدارية:

```sql
select private.register_agent_credential('primary', 'PASTE_RANDOM_TOKEN_ONCE');
```

Local Agent يستخدم `SUPABASE_ANON_KEY` مع schema `api` ويمرر التوكن لكل RPC. لا يملك `anon` أي صلاحيات مباشرة على الجداول. n8n وحده يستخدم `service_role` داخل Credentials Store.

## اختبارات ما بعد التطبيق

```sql
select * from public.claim_due_posts(10);
select relname, relrowsecurity from pg_class where relnamespace = 'public'::regnamespace and relkind = 'r';
```

يجب أن تكون `relrowsecurity = true` لكل جدول تطبيق في `public`، وأن يرجع claim صفر صفوف في قاعدة جديدة.

## ملاحظات أمنية حالية

في مشاريع Supabase الحديثة لا ينبغي افتراض أن الجداول الجديدة exposed تلقائيًا؛ `GRANT` وRLS طبقتان منفصلتان. Migration تمنح وصول الجداول صراحةً إلى `service_role` فقط، وتمنح `anon` تنفيذ RPCs المحددة فقط.

لا يمكن اعتبار اتصال Supabase حيًا مختبرًا حتى تُضاف بيانات المشروع ويتم تشغيل `db push` واختبارات SQL أعلاه.
