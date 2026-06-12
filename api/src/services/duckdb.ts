import type { MetricsSnapshot } from '../types/index.js';

const WORKER_URL = process.env.WORKER_URL || 'http://localhost:3002';

interface WorkerCurrentMetrics {
  summary_timestamp: string;
  new_installs_24h: number;
  active_users_24h: number;
  crash_free_rate_pct: number;
  d1_retention_pct: number;
  avg_session_duration_seconds: number;
  items_added_24h: number;
  notification_opt_in_rate_pct: number;
}

interface WorkerMetricsResponse {
  data: WorkerCurrentMetrics;
}

interface WorkerHistoryResponse {
  data: WorkerCurrentMetrics[];
  count: number;
}

function toSnapshot(row: WorkerCurrentMetrics): MetricsSnapshot {
  return {
    timestamp: row.summary_timestamp,
    newInstalls: row.new_installs_24h,
    activeUsers: row.active_users_24h,
    crashFreeRate: row.crash_free_rate_pct / 100,
    d1Retention: row.d1_retention_pct / 100,
    avgSessionLength: row.avg_session_duration_seconds,
    itemsAdded: row.items_added_24h,
    notificationOptInRate: row.notification_opt_in_rate_pct / 100,
  };
}

export async function getCurrentMetricsFromDuckDB(): Promise<MetricsSnapshot | null> {
  try {
    const response = await fetch(`${WORKER_URL}/metrics/current`);
    if (!response.ok) {
      return null;
    }

    const payload = (await response.json()) as WorkerMetricsResponse;
    if (!payload.data) {
      return null;
    }

    return toSnapshot(payload.data);
  } catch {
    return null;
  }
}

export async function getHistoricalMetricsFromDuckDB(hours: number): Promise<MetricsSnapshot[]> {
  try {
    const clampedHours = Math.min(Math.max(hours, 1), 720);
    const response = await fetch(`${WORKER_URL}/metrics/history?hours=${clampedHours}`);
    if (!response.ok) {
      return [];
    }

    const payload = (await response.json()) as WorkerHistoryResponse;
    if (!Array.isArray(payload.data)) {
      return [];
    }

    return payload.data.map(toSnapshot);
  } catch {
    return [];
  }
}
