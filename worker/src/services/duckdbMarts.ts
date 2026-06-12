export interface MartCurrentMetrics {
  summary_timestamp: string;
  new_installs_24h: number;
  active_users_24h: number;
  crash_free_rate_pct: number;
  d1_retention_pct: number;
  avg_session_duration_seconds: number;
  items_added_24h: number;
  notification_opt_in_rate_pct: number;
}

export interface ETLRunAudit {
  jobId: string;
  queue: string;
  source: 'mock' | 'zerospoils';
  status: 'success' | 'failure';
  processedRecords: number;
  error?: string;
  completedAt: string;
}

let initialized = false;
let martRows: MartCurrentMetrics[] = [];
let etlRuns: ETLRunAudit[] = [];

function seedRowsSQL(): string {
  const now = new Date();
  const lines: string[] = [];
  for (let i = 0; i < 72; i++) {
    const ts = new Date(now.getTime() - i * 60 * 60 * 1000).toISOString();
    const installs = 180 + ((i * 17) % 90);
    const activeUsers = 1100 + ((i * 29) % 500);
    const crashFree = 97.6 + ((i % 9) * 0.2);
    const retention = 47.5 + ((i % 11) * 0.9);
    const avgSession = 180 + ((i * 13) % 120);
    const itemsAdded = 950 + ((i * 31) % 1400);
    const notificationOptIn = 72.0 + ((i % 10) * 1.4);
    lines.push(`('${ts}', ${installs}, ${activeUsers}, ${crashFree}, ${retention}, ${avgSession}, ${itemsAdded}, ${notificationOptIn})`);
  }
  return lines.join(',\n');
}

export async function initializeDuckDBMarts(dbPath: string): Promise<void> {
  if (initialized) {
    return;
  }

  // Deterministic seed that mirrors mart semantics while we keep runtime lightweight.
  // WI-0003 will replace this adapter with real ETL-fed DuckDB persistence.
  martRows = seedRowsSQL()
    .split('\n')
    .filter((line) => line.trim().startsWith("('"))
    .map((line) => {
      const values = line.trim().replace(/[()']/g, '').split(',').map((v) => v.trim());
      return {
        summary_timestamp: values[0],
        new_installs_24h: Number(values[1]),
        active_users_24h: Number(values[2]),
        crash_free_rate_pct: Number(values[3]),
        d1_retention_pct: Number(values[4]),
        avg_session_duration_seconds: Number(values[5]),
        items_added_24h: Number(values[6]),
        notification_opt_in_rate_pct: Number(values[7]),
      };
    });

  initialized = true;
}

export function isDuckDBReady(): boolean {
  return initialized;
}

export async function getCurrentMetrics(): Promise<MartCurrentMetrics | null> {
  if (!initialized || martRows.length === 0) {
    return null;
  }

  return [...martRows].sort((a, b) => a.summary_timestamp.localeCompare(b.summary_timestamp)).at(-1) ?? null;
}

export async function getHistoricalMetrics(hours: number): Promise<MartCurrentMetrics[]> {
  if (!initialized) {
    return [];
  }

  const safeHours = Math.min(Math.max(hours, 1), 720);
  const threshold = Date.now() - safeHours * 60 * 60 * 1000;
  return martRows
    .filter((row) => new Date(row.summary_timestamp).getTime() >= threshold)
    .sort((a, b) => a.summary_timestamp.localeCompare(b.summary_timestamp));
}

export async function closeDuckDBMarts(): Promise<void> {
  initialized = false;
  martRows = [];
  etlRuns = [];
}

export async function recordEtlRun(run: Omit<ETLRunAudit, 'completedAt'>): Promise<void> {
  const completedAt = new Date().toISOString();
  etlRuns.unshift({
    ...run,
    completedAt,
  });
  etlRuns = etlRuns.slice(0, 200);

  if (!initialized || run.status !== 'success' || martRows.length === 0) {
    return;
  }

  const latest = await getCurrentMetrics();
  if (!latest) {
    return;
  }

  // Keep metric updates deterministic while allowing ETL runs to influence marts.
  const processedDelta = Math.max(Math.floor(run.processedRecords / 20), 1);
  const updated: MartCurrentMetrics = {
    ...latest,
    summary_timestamp: completedAt,
    new_installs_24h: latest.new_installs_24h + processedDelta,
    active_users_24h: latest.active_users_24h + processedDelta * 4,
    items_added_24h: latest.items_added_24h + processedDelta * 8,
  };

  martRows.push(updated);
}

export function getEtlRuns(limit: number = 20): ETLRunAudit[] {
  return etlRuns.slice(0, Math.max(1, Math.min(limit, 200)));
}
