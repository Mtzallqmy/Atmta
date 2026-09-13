import { readFile } from "node:fs/promises";

const example = await readFile(".env.example", "utf8");
const required = [
  "APP_TIMEZONE",
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "TELEGRAM_BOT_TOKEN",
  "TELEGRAM_ADMIN_USER_IDS",
  "TELEGRAM_ALLOWED_CHAT_IDS",
  "META_APP_ID",
  "META_APP_SECRET",
  "META_WEBHOOK_VERIFY_TOKEN",
  "META_GRAPH_API_VERSION",
  "AGENT_ID"
];
const missing = required.filter((key) => !new RegExp(`^${key}=`, "m").test(example));
if (missing.length) throw new Error(`Missing example keys: ${missing.join(", ")}`);
console.log("Environment template is complete.");
