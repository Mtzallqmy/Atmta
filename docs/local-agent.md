# Local Agent

## المتطلبات

- Node.js 22+ (المختبر في CI: Node 24).
- pnpm 11+.
- مشروع Supabase مطبق migrations ومضاف فيه credential hash للـAgent.
- تسجيل دخول Facebook يدوي لأول مرة.

## macOS / Linux

```bash
git clone https://github.com/Mtzallqmy/Atmta.git
cd Atmta
git switch build/n8n-facebook-automation
pnpm install --frozen-lockfile
pnpm --filter @atmta/local-agent exec playwright install chromium
cp apps/local-agent/.env.example apps/local-agent/.env
cd apps/local-agent
pnpm build
pnpm start
```

## Windows PowerShell

```powershell
git clone https://github.com/Mtzallqmy/Atmta.git
Set-Location Atmta
git switch build/n8n-facebook-automation
pnpm install --frozen-lockfile
pnpm --filter @atmta/local-agent exec playwright install chromium
Copy-Item apps/local-agent/.env.example apps/local-agent/.env
Set-Location apps/local-agent
pnpm build
pnpm start
```

املأ `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AGENT_API_TOKEN`, و`AGENT_ID`. لا تستخدم service-role key.

## أول تشغيل

اجعل `agent_settings.enabled=false`، شغّل Agent وافتح المتصفح بأمر `open_browser`، ثم سجّل الدخول بنفسك. لا تدخل كلمة مرور Facebook في التطبيق. profile يبقى في `.local-data/facebook-profile/` والعداد في `.local-state/` وكلاهما gitignored.

## الحدود والتوقف

الافتراضي batch=20، interval=30 دقيقة، daily=100، لكن ابدأ بقيم أقل. يطابق العداد المحلي والسحابي ويستخدم القيمة الأعلى. عند CAPTCHA/checkpoint/restriction يوقف التشغيل، يعطل setting، ويسجل سببًا غير حساس. أعد التشغيل يدويًا فقط بعد حل التحقق من Facebook.
