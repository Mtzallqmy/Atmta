export type AgentState = "offline" | "idle" | "running" | "paused" | "safety_stopped" | "daily_limit_reached" | "error";

export interface AgentSettings {
  agent_id: string;
  enabled: boolean;
  batch_size: number;
  interval_minutes: 10 | 30 | 60;
  daily_limit: number;
  timezone: string;
  next_run_at: string | null;
}

export interface AgentCommand {
  id: string;
  agent_id: string;
  type: "run_friend_batch" | "pause" | "resume" | "open_browser" | "health_check";
  payload: Record<string, unknown>;
  status: "running";
}
