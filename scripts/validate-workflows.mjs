import { readdir, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const directory = path.resolve("n8n/workflows");
if (!existsSync(directory)) {
  console.log("No workflows to validate yet.");
  process.exit(0);
}

const files = (await readdir(directory)).filter((file) => file.endsWith(".json"));
for (const file of files) {
  const data = JSON.parse(await readFile(path.join(directory, file), "utf8"));
  if (!data.name || !Array.isArray(data.nodes) || !data.connections) {
    throw new Error(`${file}: expected name, nodes, and connections`);
  }
  const serialized = JSON.stringify(data);
  const forbidden = [/\b\d{8,10}:[A-Za-z0-9_-]{30,}\b/, /service_role\s*[=:]\s*["'][^"']+/i, /access_token\s*[=:]\s*["'][^"'{]+/i];
  if (forbidden.some((pattern) => pattern.test(serialized))) {
    throw new Error(`${file}: possible embedded credential`);
  }
}
console.log(`Validated ${files.length} n8n workflow(s).`);
