import { describe, expect, it } from "vitest";
import { batchLimit, localDate, nextRunAt, reconcileState } from "../src/friend-limits.js";

describe("friend request limits", () => {
  it("caps a batch by the remaining daily allowance", () => {
    expect(batchLimit(20, 100, 95)).toBe(5);
    expect(batchLimit(20, 100, 100)).toBe(0);
  });

  it("uses the higher persisted counter after restart", () => {
    const date = "2026-09-14";
    const state = reconcileState(
      { localDate: date, acceptedCount: 40, failedCount: 1, lastBatchAt: null },
      { localDate: date, acceptedCount: 38, failedCount: 2, lastBatchAt: null },
      date
    );
    expect(state.acceptedCount).toBe(40);
    expect(state.failedCount).toBe(2);
  });

  it("resets only after the configured local date changes", () => {
    const state = reconcileState({ localDate: "2026-09-13", acceptedCount: 99, failedCount: 0, lastBatchAt: null }, null, "2026-09-14");
    expect(state.acceptedCount).toBe(0);
  });

  it("calculates dates and next run deterministically", () => {
    expect(localDate(new Date("2026-09-13T22:30:00Z"), "Asia/Aden")).toBe("2026-09-14");
    expect(nextRunAt(new Date("2026-09-14T00:00:00Z"), 30).toISOString()).toBe("2026-09-14T00:30:00.000Z");
  });
});
