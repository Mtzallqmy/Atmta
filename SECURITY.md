# Security Policy

## Secrets

Never commit Telegram tokens, Meta secrets/tokens, Supabase service-role keys, n8n keys, passwords, cookies, private keys, or Playwright profiles. n8n secrets belong in its Credentials Store. Copy `.env.example` to `.env` only on the machine that runs the component.

## Trust boundaries

- Telegram commands are denied unless both user and chat are allowlisted.
- Supabase `service_role` is allowed only in trusted n8n infrastructure.
- The Local Agent uses only its scoped RPC token/anon key and never uploads browser state.
- Meta webhook bodies must be verified before parsing or persistence.
- SQL inputs are parameterized through Supabase/RPC calls.
- Logs must be sanitized and must not contain credentials, cookies, headers, or full webhook secrets.

## Browser automation

The Local Agent never bypasses CAPTCHA, checkpoints, rate limits, fingerprinting, or account security. It stops on any safety signal and requires manual recovery.

## Reporting

Report vulnerabilities privately to the repository owner. Do not open a public issue containing credentials or exploit details.
