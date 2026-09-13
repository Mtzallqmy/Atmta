# Telegram Commands

| الأمر | الوظيفة |
|---|---|
| `/start` | القائمة الرئيسية |
| `/status` | حالة n8n وSupabase والصفحات والـLocal Agent |
| `/publish` | محادثة نشر فوري مع تأكيد |
| `/schedule` | جدولة منشور حسب `APP_TIMEZONE` |
| `/posts` | أحدث المنشورات وإجراءاتها |
| `/comments` | طابور مراجعة التعليقات |
| `/automation` | إدارة قواعد الرد |
| `/friends` | حالة وإعدادات طلبات الصداقة |
| `/pause` / `/resume` | إيقاف/تشغيل بعد تأكيد |
| `/settings` | الإعدادات |
| `/help` | المساعدة |

كل update يمر أولًا عبر تطبيع payload ثم استعلام `telegram_admins` المطابق لكل من user ID وchat ID. المستخدم غير المصرح له يتلقى رفضًا عامًا ولا يرى أي معلومات. أضف المشرف الأول يدويًا من SQL Editor قبل تفعيل Workflow:

```sql
insert into public.telegram_admins (telegram_user_id, chat_id)
values (YOUR_USER_ID, YOUR_CHAT_ID);
```

حالات المحادثات متعددة الخطوات تحفظ في `telegram_sessions` وتنتهي تلقائيًا وفق `expires_at`. جميع الإجراءات الحساسة تستخدم callback confirmation قبل التنفيذ في Workflows المختصة.
