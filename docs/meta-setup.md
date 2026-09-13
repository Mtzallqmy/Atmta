# Meta Pages Setup

> راجع الوثائق الرسمية عند الإعداد ولا تنسخ إصدار Graph API من مثال قديم. عيّن الإصدار المدعوم حاليًا في n8n Variable باسم `META_GRAPH_API_VERSION`.

## الإعداد

1. أنشئ تطبيقًا من [Meta for Developers](https://developers.facebook.com/) واربطه بالـBusiness/Page الصحيحة.
2. أضف Facebook Login/Pages API وفق نوع التطبيق وحالة Business verification.
3. اطلب أقل صلاحيات مطلوبة فقط:
   - `pages_show_list` لعرض الصفحات التي يديرها المستخدم.
   - `pages_read_engagement` لقراءة المحتوى والتفاعل المطلوب.
   - `pages_manage_posts` لإنشاء منشورات الصفحة وإدارتها.
   - `pages_manage_engagement` للرد/إدارة التعليقات عندما تسمح الوظيفة.
   - `pages_manage_metadata` للاشتراك في Page webhooks.
4. أكمل App Review وAdvanced Access لكل صلاحية تتطلب ذلك قبل استخدام التطبيق خارج أدوار التطوير.
5. أنشئ credential من نوع HTTP Header Auth في n8n باسم `Meta User Token`، Header=`Authorization` والقيمة=`Bearer <token>`. لا تضع التوكن في JSON أو Variables.
6. عيّن `META_GRAPH_API_VERSION` ثم استورد وشغّل `00-meta-page-sync.json` يدويًا للتحقق من الاتصال ومزامنة الصفحات.

## Page access tokens

احتفظ بـPage access token داخل n8n Credentials Store. لا تحفظ القيمة الخام في Supabase؛ `meta_connections.token_reference` مخصص لاسم/مرجع credential غير الحساس فقط. راقب انتهاء/إلغاء التوكن، ولا تعِد المحاولة بلا نهاية عند أخطاء OAuth أو الصلاحيات.

## Webhooks

- Callback URL يأتي من production URL في `04-meta-comments-webhook` بعد الاستيراد.
- Verify token يُحفظ كـsecret runtime باسم `META_WEBHOOK_VERIFY_TOKEN`.
- App Secret يُحفظ كـsecret runtime باسم `META_APP_SECRET` للتحقق من `X-Hub-Signature-256` على الـraw body.
- اشترك في أحداث Page المطلوبة فقط، واعتبر كل payload غير موثوق حتى نجاح التحقق.

المراجع الرسمية: [Pages API](https://developers.facebook.com/documentation/pages-api)، [Posts](https://developers.facebook.com/documentation/pages-api/posts)، [Manage Pages](https://developers.facebook.com/documentation/pages-api/manage-pages)، [Permissions](https://developers.facebook.com/docs/permissions/)، [Webhooks](https://developers.facebook.com/docs/graph-api/webhooks/getting-started/).

## قيود Development Mode

أثناء Development Mode تعمل التجارب فقط مع المستخدمين/الصفحات المرتبطة بأدوار التطبيق حسب سياسات Meta. نجاح mock أو طلب لمستخدم مطوّر لا يعني أن App Review مكتمل للإنتاج.
