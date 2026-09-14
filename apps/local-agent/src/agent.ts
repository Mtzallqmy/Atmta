import { setTimeout as delay } from "node:timers/promises";
import type { AgentConfig } from "./config.js";
import { AgentApi } from "./api.js";
import { FacebookBrowser, SafetyStopError } from "./browser.js";
import { logger } from "./logger.js";
import type { AgentCommand, AgentState } from "./types.js";

export class LocalAgent {
  readonly #config: AgentConfig;
  readonly #api: AgentApi;
  readonly #browser: FacebookBrowser;
  #state: AgentState = "idle";

  constructor(config: AgentConfig) {
    this.#config = config;
    this.#api = new AgentApi(config);
    this.#browser = new FacebookBrowser(config);
  }

  async run(signal: AbortSignal): Promise<void> {
    logger.info({ agentId: this.#config.AGENT_ID }, "Local Agent started");
    while (!signal.aborted) {
      try {
        const settings = await this.#api.getSettings();
        this.#state = settings.enabled ? "idle" : "paused";
        await this.#api.heartbeat(this.#state);
        if (settings.enabled) for (const command of await this.#api.claimCommands()) await this.#handleCommand(command);
      } catch (error) {
        this.#state = error instanceof SafetyStopError ? "safety_stopped" : "error";
        logger.error({ err: error, state: this.#state }, "Agent loop failed");
        await this.#api.heartbeat(this.#state, null, { reason: error instanceof Error ? error.message : "unknown" }).catch(() => undefined);
        if (error instanceof SafetyStopError) break;
      }
      await delay(this.#config.AGENT_POLL_INTERVAL_SECONDS * 1_000, undefined, { signal }).catch(() => undefined);
    }
    await this.#browser.close();
    await this.#api.heartbeat("offline").catch(() => undefined);
    logger.info("Local Agent stopped");
  }

  async #handleCommand(command: AgentCommand): Promise<void> {
    try {
      this.#state = "running";
      await this.#api.heartbeat("running", command.type);
      if (command.type === "open_browser") await this.#browser.open();
      if (command.type === "pause") this.#state = "paused";
      if (command.type === "resume" || command.type === "health_check") this.#state = "idle";
      if (command.type === "run_friend_batch") throw new Error("Friend request module is not enabled in the foundation stage");
      await this.#api.completeCommand(command.id, true, { state: this.#state });
    } catch (error) {
      await this.#api.completeCommand(command.id, false, null, error instanceof Error ? error.message : "Unknown command error");
      throw error;
    }
  }
}
