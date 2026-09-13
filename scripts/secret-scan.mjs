import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const forbiddenPaths = [/(^|\/)\.env$/, /\.local-(data|state)\//, /facebook-profile\//, /cookies.*\.json$/i];
const secretPatterns = [
  /\b\d{8,10}:[A-Za-z0-9_-]{30,}\b/,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
  /(?:SUPABASE_SERVICE_ROLE_KEY|META_APP_SECRET|N8N_API_KEY)[ \t]*=[ \t]*[^\s#]+/
];

const files = execFileSync("git", ["ls-files"], { encoding: "utf8" }).trim().split("\n").filter(Boolean);
const badPath = files.find((file) => forbiddenPaths.some((pattern) => pattern.test(file)));
if (badPath) throw new Error(`Forbidden tracked path: ${badPath}`);

for (const file of files) {
  const content = readFileSync(file, "utf8");
  if (secretPatterns.some((pattern) => pattern.test(content))) {
    throw new Error(`Possible credential in tracked file: ${file}`);
  }
}
console.log(`Scanned ${files.length} tracked file(s); no credential pattern found.`);
