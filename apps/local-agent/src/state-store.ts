import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import type { FriendState } from "./friend-limits.js";

const stateSchema = z.object({ localDate: z.string(), acceptedCount: z.number().int().nonnegative(), failedCount: z.number().int().nonnegative(), lastBatchAt: z.string().nullable() });

export class StateStore {
  readonly #file = path.resolve(".local-state/friend-request-state.json");

  async read(): Promise<FriendState | null> {
    try { return stateSchema.parse(JSON.parse(await readFile(this.#file, "utf8"))); }
    catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return null; throw error; }
  }

  async write(state: FriendState): Promise<void> {
    await mkdir(path.dirname(this.#file), { recursive: true, mode: 0o700 });
    const temporary = `${this.#file}.tmp`;
    await writeFile(temporary, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
    await rename(temporary, this.#file);
  }
}
