import { describe, expect, it } from "vitest";
import { loadConfig } from "../src/config.js";

const valid = { SUPABASE_URL: "https://example.supabase.co", SUPABASE_ANON_KEY: "a".repeat(30), AGENT_API_TOKEN: "b".repeat(32) };

describe("configuration", () => {
  it("applies safe defaults", () => {
    const config = loadConfig(valid);
    expect(config.AGENT_ID).toBe("primary");
    expect(config.AGENT_POLL_INTERVAL_SECONDS).toBe(30);
    expect(config.AGENT_BROWSER_HEADLESS).toBe(false);
  });

  it("rejects short agent tokens", () => {
    expect(() => loadConfig({ ...valid, AGENT_API_TOKEN: "short" })).toThrow();
  });
});
