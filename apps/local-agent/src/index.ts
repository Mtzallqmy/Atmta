import { loadEnvFile } from "node:process";
import { LocalAgent } from "./agent.js";
import { loadConfig } from "./config.js";
import { logger } from "./logger.js";

try { loadEnvFile(".env"); } catch { /* Environment may be injected by the process manager. */ }

const abortController = new AbortController();
for (const event of ["SIGINT", "SIGTERM"] as const) process.once(event, () => abortController.abort());

const agent = new LocalAgent(loadConfig());
agent.run(abortController.signal).catch((error) => {
  logger.fatal({ err: error }, "Local Agent terminated unexpectedly");
  process.exitCode = 1;
});
