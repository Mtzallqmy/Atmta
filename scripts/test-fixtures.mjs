import { createHmac, timingSafeEqual } from "node:crypto";
import { readFile } from "node:fs/promises";

const telegram = JSON.parse(await readFile("n8n/fixtures/telegram-start.json", "utf8"));
if (telegram.message?.text !== "/start" || !telegram.message?.from?.id || !telegram.message?.chat?.id) throw new Error("Telegram routing fixture is invalid");

const metaRaw = await readFile("n8n/fixtures/meta-comment-event.json", "utf8");
const meta = JSON.parse(metaRaw);
const comment = meta.entry?.[0]?.changes?.[0]?.value;
if (comment?.item !== "comment" || comment?.verb !== "add" || !comment?.comment_id) throw new Error("Meta comment fixture is invalid");

const secret = "fixture-only-secret";
const expected = `sha256=${createHmac("sha256", secret).update(metaRaw).digest("hex")}`;
const actual = `sha256=${createHmac("sha256", secret).update(metaRaw).digest("hex")}`;
if (!timingSafeEqual(Buffer.from(expected), Buffer.from(actual))) throw new Error("Valid Meta signature was rejected");
const tampered = `${metaRaw} `;
const invalid = `sha256=${createHmac("sha256", secret).update(tampered).digest("hex")}`;
if (timingSafeEqual(Buffer.from(expected), Buffer.from(invalid))) throw new Error("Tampered Meta payload was accepted");

console.log("Telegram routing and Meta webhook fixtures passed.");
