import pino from "pino";

export const logger = pino({
  name: "atmta-local-agent",
  level: process.env.LOG_LEVEL ?? "info",
  redact: {
    paths: ["*.token", "*.apiToken", "*.key", "*.cookie", "*.cookies", "req.headers.authorization"],
    censor: "[REDACTED]"
  }
});
