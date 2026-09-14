export interface FriendState {
  localDate: string;
  acceptedCount: number;
  failedCount: number;
  lastBatchAt: string | null;
}

export function localDate(now: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-US", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(now);
  const value = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${value.year}-${value.month}-${value.day}`;
}

export function emptyState(date: string): FriendState {
  return { localDate: date, acceptedCount: 0, failedCount: 0, lastBatchAt: null };
}

export function normalizeForDate(state: FriendState | null, date: string): FriendState {
  return state?.localDate === date ? state : emptyState(date);
}

export function reconcileState(local: FriendState | null, cloud: FriendState | null, date: string): FriendState {
  const a = normalizeForDate(local, date);
  const b = normalizeForDate(cloud, date);
  return {
    localDate: date,
    acceptedCount: Math.max(a.acceptedCount, b.acceptedCount),
    failedCount: Math.max(a.failedCount, b.failedCount),
    lastBatchAt: [a.lastBatchAt, b.lastBatchAt].filter((value): value is string => Boolean(value)).sort().at(-1) ?? null
  };
}

export function batchLimit(batchSize: number, dailyLimit: number, acceptedToday: number): number {
  return Math.max(0, Math.min(batchSize, dailyLimit - acceptedToday));
}

export function nextRunAt(now: Date, intervalMinutes: 10 | 30 | 60): Date {
  return new Date(now.getTime() + intervalMinutes * 60_000);
}
