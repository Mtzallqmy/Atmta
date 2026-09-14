import { readdir, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const directory = path.resolve("n8n/workflows");
if (!existsSync(directory)) {
  console.log("No workflows to validate yet.");
  process.exit(0);
}

const files = (await readdir(directory)).filter((file) => file.endsWith(".json"));
const expected = ["00-meta-page-sync.json", "01-telegram-control-router.json", "02-publish-now.json", "03-scheduled-publisher.json", "04-meta-comments-webhook.json", "05-comment-automation.json", "06-local-agent-notifications.json", "07-daily-summary.json", "08-error-handler.json"];
for (const required of expected) if (!files.includes(required)) throw new Error(`Missing workflow: ${required}`);
for (const file of files) {
  const data = JSON.parse(await readFile(path.join(directory, file), "utf8"));
  if (!data.name || !Array.isArray(data.nodes) || !data.connections) {
    throw new Error(`${file}: expected name, nodes, and connections`);
  }
  if (data.active !== false) throw new Error(`${file}: repository exports must be inactive`);
  const names = new Set(data.nodes.map((node) => node.name));
  const ids = new Set(data.nodes.map((node) => node.id));
  if (names.size !== data.nodes.length || ids.size !== data.nodes.length) throw new Error(`${file}: duplicate node name or id`);
  for (const [source, outputs] of Object.entries(data.connections)) {
    if (!names.has(source)) throw new Error(`${file}: connection source not found: ${source}`);
    for (const channel of Object.values(outputs)) for (const branch of channel) for (const edge of branch) {
      if (!names.has(edge.node)) throw new Error(`${file}: connection target not found: ${edge.node}`);
    }
  }
  const serialized = JSON.stringify(data);
  const forbidden = [/\b\d{8,10}:[A-Za-z0-9_-]{30,}\b/, /service_role\s*[=:]\s*["'][^"']+/i, /access_token\s*[=:]\s*["'][^"'{]+/i];
  if (forbidden.some((pattern) => pattern.test(serialized))) {
    throw new Error(`${file}: possible embedded credential`);
  }
}
console.log(`Validated ${files.length} n8n workflow(s).`);
