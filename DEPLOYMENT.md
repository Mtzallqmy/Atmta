# Deployment

The recommended production path is n8n Cloud + Supabase Cloud + Telegram Bot API + Meta Developer App. The Local Agent runs on the operator's computer and makes outbound connections only.

Detailed setup instructions are maintained under `docs/` and will be finalized before v1.0.0.

## Optional self-hosted n8n

Self-hosting on Railway, Docker, or a VPS is optional. Use PostgreSQL for n8n, persistent storage, a strong `N8N_ENCRYPTION_KEY`, HTTPS, and the correct public webhook base URL. Never commit deployment credentials.
