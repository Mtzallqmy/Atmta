import { describe, expect, it } from "vitest";
import { detectSafetyReason } from "../src/safety.js";

describe("Facebook safety detection", () => {
  it.each(["/checkpoint/123", "Please complete this CAPTCHA", "تم تقييد حسابك مؤقتًا"])("stops on %s", (text) => {
    expect(detectSafetyReason(text)).not.toBeNull();
  });

  it("does not stop on a normal page", () => {
    expect(detectSafetyReason("Friends Home Notifications")).toBeNull();
  });
});
