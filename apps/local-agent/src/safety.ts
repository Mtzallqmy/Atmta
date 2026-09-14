import type { Page } from "playwright";

export const safetyPatterns = [
  /checkpoint/i,
  /captcha/i,
  /security (?:check|verification)/i,
  /confirm your identity/i,
  /account (?:locked|restricted)/i,
  /suspicious activity/i,
  /unusual activity/i,
  /تأكيد هويتك/,
  /نشاط مريب/,
  /تم تقييد حسابك/,
  /نقطة تحقق/
];

export function detectSafetyReason(input: string): string | null {
  const match = safetyPatterns.find((pattern) => pattern.test(input));
  return match ? `Facebook safety signal matched: ${match.source}` : null;
}

export async function inspectPageSafety(page: Page): Promise<string | null> {
  const snapshot = `${page.url()}\n${await page.title()}\n${(await page.locator("body").innerText({ timeout: 5_000 }).catch(() => "")).slice(0, 20_000)}`;
  return detectSafetyReason(snapshot);
}
