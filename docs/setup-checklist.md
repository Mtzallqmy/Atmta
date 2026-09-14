# Production Setup Checklist

- [ ] إنشاء/ربط Supabase project وتطبيق migrations وseed.
- [ ] إضافة `api` إلى exposed schemas وتشغيل RLS/atomic claim tests وadvisors.
- [ ] إنشاء private `facebook-media` bucket والتأكد أنه غير public.
- [ ] إنشاء Telegram Bot وإضافة admin user/chat IDs.
- [ ] إنشاء n8n workspace وcredentials وVariables واستيراد workflows.
- [ ] إنشاء Meta Developer App، ربط Page، تحديد Graph API version، وتجهيز App Review.
- [ ] تشغيل Meta page sync يدويًا بنجاح.
- [ ] اختبار text/photo/video/Reel على صفحة اختبار حسب الدعم الحالي.
- [ ] اختبار Webhook challenge وsigned comment payload.
- [ ] تشغيل Local Agent وهو disabled، وتسجيل الدخول يدويًا.
- [ ] اختبار heartbeat وpause/resume وsafety stop.
- [ ] خفض friend limits مبدئيًا ثم تفعيلها يدويًا إن رغبت.
- [ ] تعيين Error Workflow ثم تفعيل triggers/schedulers.
- [ ] مراجعة logs ليوم كامل قبل توسيع الاستخدام.
