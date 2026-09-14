# n8n Setup

## الاستيراد

من n8n: **Workflows → Import from File**، واستورد ملفات `n8n/workflows` بهذا الترتيب:

1. `08-error-handler.json`
2. `02-publish-now.json`
3. `05-comment-automation.json`
4. `00-meta-page-sync.json`
5. `01-telegram-control-router.json`
6. `04-meta-comments-webhook.json`
7. `03-scheduled-publisher.json`
8. `06-local-agent-notifications.json`
9. `07-daily-summary.json`

## Credentials

- `Atmta Telegram Bot`: Telegram API credential.
- `Atmta Supabase`: Supabase credential بمفتاح service-role، داخل n8n فقط.
- `Meta User Token`: HTTP Header Auth، `Authorization: Bearer …`.
- `Meta Page Token`: HTTP Header Auth، `Authorization: OAuth …`.

استبدل credential IDs الوهمية في كل node من واجهة n8n ولا تعدّل JSON بتوكن خام.

## Variables / runtime secrets

أنشئ: `SUPABASE_URL`, `APP_TIMEZONE`, `META_GRAPH_API_VERSION`, `PUBLISH_WORKFLOW_ID`, `COMMENT_AUTOMATION_WORKFLOW_ID`. أضف `META_WEBHOOK_VERIFY_TOKEN` و`META_APP_SECRET` عبر External Secrets/runtime secret mechanism إن كانت خطتك تدعمها؛ لا تحفظها في Git.

## Activation

1. عيّن `08` كـError Workflow لبقية workflows.
2. شغّل `00` يدويًا وتأكد من مزامنة الصفحات.
3. اختبر `02` بصفحة Development Mode ومنشور اختبار.
4. اختبر GET challenge وsigned POST في `04` بالـproduction webhook URL.
5. فعّل بالترتيب: 08، 02، 05، 01، 04، 03، 06، 07. اترك 00 يدويًا.

## n8n API

إذا وفرت لاحقًا `N8N_BASE_URL` و`N8N_API_KEY` يمكن نشر/تحديث workflows عبر REST API بعد التحقق من إصدار n8n. لا توجد إضافة n8n مباشرة في جلسة البناء الحالية، لذلك الملفات مُعدة للاستيراد ولم يُدّع نشرها.
