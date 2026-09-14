import { setTimeout as delay } from "node:timers/promises";
import type { AgentConfig } from "./config.js";
import { AgentApi } from "./api.js";
import { FacebookBrowser, SafetyStopError } from "./browser.js";
import { logger } from "./logger.js";
import { FriendRequestRunner } from "./friend-runner.js";
import type { AgentCommand, AgentState } from "./types.js";

export class LocalAgent {
  readonly #config: AgentConfig;
  readonly #api: AgentApi;
  readonly #browser: FacebookBrowser;
  readonly #friends: FriendRequestRunner;
  #state: AgentState = "idle";

  constructor(config: AgentConfig) {
    this.#config = config;
    this.#api = new AgentApi(config);
    this.#browser = new FacebookBrowser(config);
    this.#friends = new FriendRequestRunner(this.#api, this.#browser);
  }

  async run(signal: AbortSignal): Promise<void> {
    logger.info({ agentId: this.#config.AGENT_ID }, "Local Agent started");
    while (!signal.aborted) {
      try {
        const settings = await this.#api.getSettings();
        this.#state = settings.enabled ? "idle" : "paused";
        await this.#api.heartbeat(this.#state);
        if (settings.enabled) {
          for (const command of await this.#api.claimCommands()) await this.#handleCommand(command, settings);
          await this.#friends.runIfDue(settings);
        }
      } catch (error) {
        this.#state = error instanceof SafetyStopError ? "safety_stopped" : "error";
        logger.error({ err: error, state: this.#state }, "Agent loop failed");
        const reason = error instanceof Error ? error.message : "unknown";
        await this.#api.heartbeat(this.#state, null, { reason }).catch(() => undefined);
        if (error instanceof SafetyStopError || /Facebook safety signal/.test(reason)) {
          await this.#api.safetyStop(reason).catch(() => undefined);
          break;
        }
      }
      await delay(this.#config.AGENT_POLL_INTERVAL_SECONDS * 1_000, undefined, { signal }).catch(() => undefined);
    }
    await this.#browser.close();
    await this.#api.heartbeat("offline").catch(() => undefined);
    logger.info("Local Agent stopped");
  }

  async #handleCommand(command: AgentCommand, settings: Awaited<ReturnType<AgentApi["getSettings"]>>): Promise<void> {
    try {
      this.#state = "running";
      await this.#api.heartbeat("running", command.type);
      if (command.type === "open_browser") await this.#browser.open();
      if (command.type === "pause") this.#state = "paused";
      if (command.type === "resume" || command.type === "health_check") this.#state = "idle";
      const result = command.type === "run_friend_batch" ? await this.#friends.runIfDue(settings, true) : { state: this.#state };
      await this.#api.completeCommand(command.id, true, result);
    } catch (error) {
      await this.#api.completeCommand(command.id, false, null, error instanceof Error ? error.message : "Unknown command error");
      throw error;
    }
  }
}
