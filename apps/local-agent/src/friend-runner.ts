import type { AgentApi } from "./api.js";
import type { FacebookBrowser } from "./browser.js";
import { batchLimit, localDate, nextRunAt, reconcileState, type FriendState } from "./friend-limits.js";
import { logger } from "./logger.js";
import { inspectPageSafety } from "./safety.js";
import { StateStore } from "./state-store.js";
import type { AgentSettings } from "./types.js";

export class FriendRequestRunner {
  constructor(private readonly api: AgentApi, private readonly browser: FacebookBrowser, private readonly store = new StateStore()) {}

  async runIfDue(settings: AgentSettings, force = false): Promise<Record<string, unknown>> {
    const now = new Date();
    const date = localDate(now, settings.timezone);
    const cloud = await this.api.getDailyStats(date);
    let state = reconcileState(await this.store.read(), cloud, date);
    await this.store.write(state);
    const limit = batchLimit(settings.batch_size, settings.daily_limit, state.acceptedCount);
    if (limit === 0) return { skipped: "daily_limit", acceptedToday: state.acceptedCount };
    if (!force && settings.next_run_at && new Date(settings.next_run_at) > now) return { skipped: "not_due", nextRunAt: settings.next_run_at };

    const page = await this.browser.open();
    await page.goto("https://www.facebook.com/friends/requests", { waitUntil: "domcontentloaded" });
    const reason = await inspectPageSafety(page);
    if (reason) throw new Error(reason);

    let accepted = 0;
    let failed = 0;
    for (let i = 0; i < limit; i++) {
      const button = page.getByRole("button", { name: /^(Confirm|تأكيد)$/i }).first();
      if (await button.count() === 0) break;
      try {
        await button.click({ timeout: 10_000 });
        accepted += 1;
        state = { ...state, acceptedCount: state.acceptedCount + 1, lastBatchAt: new Date().toISOString() };
        await this.store.write(state);
        await this.api.recordFriendResult(date, true);
        await page.waitForTimeout(1_000);
        const safety = await inspectPageSafety(page);
        if (safety) throw new Error(safety);
      } catch (error) {
        failed += 1;
        state = { ...state, failedCount: state.failedCount + 1, lastBatchAt: new Date().toISOString() };
        await this.store.write(state);
        await this.api.recordFriendResult(date, false);
        throw error;
      }
    }
    const next = nextRunAt(now, settings.interval_minutes);
    await this.api.setNextRun(next);
    logger.info({ accepted, failed, acceptedToday: state.acceptedCount, nextRunAt: next.toISOString() }, accepted ? "Friend request batch completed" : "No friend requests available");
    return { accepted, failed, acceptedToday: state.acceptedCount, nextRunAt: next.toISOString() };
  }
}
