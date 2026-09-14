import path from "node:path";
import { chromium, type BrowserContext, type Page } from "playwright";
import type { AgentConfig } from "./config.js";
import { inspectPageSafety } from "./safety.js";

export class FacebookBrowser {
  #context: BrowserContext | null = null;
  readonly #headless: boolean;
  readonly #profilePath: string;

  constructor(config: AgentConfig) {
    this.#headless = config.AGENT_BROWSER_HEADLESS;
    this.#profilePath = path.resolve(".local-data/facebook-profile");
  }

  async open(): Promise<Page> {
    this.#context ??= await chromium.launchPersistentContext(this.#profilePath, { headless: this.#headless, viewport: { width: 1280, height: 900 } });
    const page = this.#context.pages()[0] ?? await this.#context.newPage();
    if (!page.url().startsWith("https://www.facebook.com")) await page.goto("https://www.facebook.com/", { waitUntil: "domcontentloaded" });
    const reason = await inspectPageSafety(page);
    if (reason) throw new SafetyStopError(reason);
    return page;
  }

  async close(): Promise<void> {
    await this.#context?.close();
    this.#context = null;
  }
}

export class SafetyStopError extends Error {
  override name = "SafetyStopError";
}
