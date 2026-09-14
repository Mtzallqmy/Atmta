# Neon / Lakebase Postgres Alternative

المعمارية الحالية تستخدم Supabase لأن workflows تعتمد Data API وSupabase Storage وcredential type الخاص به. لا تشغّل Supabase وNeon كقاعدتي حالة متزامنتين.

Neon Lakebase Postgres مناسب كبديل في Phase لاحقة مع branch-first development وpooled URL للتطبيق وdirect URL للمigrations. لكن الانتقال يتطلب:

- استبدال Supabase REST calls باتصال Postgres/ORM أو Data API مكافئ.
- توفير object storage بديل للوسائط.
- تكييف roles/RLS و`storage.buckets` الخاصة بـSupabase.
- اختبار migrations على Neon branch عبر direct/unpooled connection ثم استخدام pooled connection لحركة التطبيق.

لذلك Neon ليس dependency للتشغيل الحالي ولا قاعدة ثانية. هذا قرار مقصود لتقليل التعقيد.
