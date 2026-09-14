import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { AgentConfig } from "./config.js";
import type { FriendState } from "./friend-limits.js";
import type { AgentCommand, AgentSettings, AgentState } from "./types.js";

export class AgentApi {
  readonly #client: SupabaseClient;
  readonly #agentId: string;
  readonly #token: string;

  constructor(config: AgentConfig) {
    this.#client = createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { headers: { "X-Client-Info": "atmta-local-agent/0.1.0" } }
    });
    this.#agentId = config.AGENT_ID;
    this.#token = config.AGENT_API_TOKEN;
  }

  async getSettings(): Promise<AgentSettings> {
    const { data, error } = await this.#client.schema("api").rpc("agent_get_settings", { p_agent_id: this.#agentId, p_token: this.#token });
    if (error) throw error;
    return data as unknown as AgentSettings;
  }

  async claimCommands(limit = 10): Promise<AgentCommand[]> {
    const { data, error } = await this.#client.schema("api").rpc("agent_claim_commands", { p_agent_id: this.#agentId, p_token: this.#token, p_limit: limit });
    if (error) throw error;
    return (data ?? []) as AgentCommand[];
  }

  async heartbeat(state: AgentState, currentTask: string | null = null, metadata: Record<string, unknown> = {}): Promise<void> {
    const { error } = await this.#client.schema("api").rpc("agent_heartbeat", { p_agent_id: this.#agentId, p_token: this.#token, p_state: state, p_current_task: currentTask, p_version: "0.1.0", p_metadata: metadata });
    if (error) throw error;
  }

  async completeCommand(id: string, succeeded: boolean, result: Record<string, unknown> | null = null, errorMessage: string | null = null): Promise<void> {
    const { error } = await this.#client.schema("api").rpc("agent_complete_command", { p_agent_id: this.#agentId, p_token: this.#token, p_command_id: id, p_succeeded: succeeded, p_result: result, p_error: errorMessage });
    if (error) throw error;
  }

  async getDailyStats(date: string): Promise<FriendState | null> {
    const { data, error } = await this.#client.schema("api").rpc("agent_get_daily_stats", { p_agent_id: this.#agentId, p_token: this.#token, p_local_date: date });
    if (error) throw error;
    if (!data) return null;
    const row = data as unknown as { local_date: string; accepted_count: number; failed_count: number; last_batch_at: string | null };
    return { localDate: row.local_date, acceptedCount: row.accepted_count, failedCount: row.failed_count, lastBatchAt: row.last_batch_at };
  }

  async recordFriendResult(date: string, accepted: boolean): Promise<void> {
    const { error } = await this.#client.schema("api").rpc("agent_record_friend_result", { p_agent_id: this.#agentId, p_token: this.#token, p_local_date: date, p_accepted: accepted });
    if (error) throw error;
  }

  async setNextRun(next: Date): Promise<void> {
    const { error } = await this.#client.schema("api").rpc("agent_set_next_run", { p_agent_id: this.#agentId, p_token: this.#token, p_next_run_at: next.toISOString() });
    if (error) throw error;
  }

  async safetyStop(reason: string): Promise<void> {
    const { error } = await this.#client.schema("api").rpc("agent_safety_stop", { p_agent_id: this.#agentId, p_token: this.#token, p_reason: reason.slice(0, 500) });
    if (error) throw error;
  }
}
