import { z } from "zod";

const booleanString = z.enum(["true", "false"]).transform((value) => value === "true");

export const configSchema = z.object({
  APP_TIMEZONE: z.string().min(1).default("Asia/Aden"),
  SUPABASE_URL: z.url(),
  SUPABASE_ANON_KEY: z.string().min(20),
  AGENT_API_TOKEN: z.string().min(32),
  AGENT_ID: z.string().regex(/^[a-zA-Z0-9_-]{1,64}$/).default("primary"),
  AGENT_POLL_INTERVAL_SECONDS: z.coerce.number().int().min(10).max(300).default(30),
  AGENT_BROWSER_HEADLESS: booleanString.default(false)
});

export type AgentConfig = z.infer<typeof configSchema>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AgentConfig {
  return configSchema.parse(env);
}
