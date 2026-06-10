/**
 * DuckDB Service for API Layer
 *
 * Provides access to analytics data from DuckDB marts.
 * Used by API endpoints to replace mock data with real queries.
 */

import fetch from 'node-fetch';

const WORKER_URL = process.env.WORKER_URL || 'http://worker:3002';

export interface CurrentMetrics {
  newInstalls: number;
  reinstalls: number;
  activeUsers: number;
  itemsAdded: number;
  itemsWasted: number;
  totalWasteCost: number;
  camerAssistanceRate: number;
  d1Retention: number;
  crashFreeRate: number;
  avgSessionDuration: number;
  notificationOptInRate: number;
  timestamp: string;
}

export interface HistoricalMetric {
  timestamp: string;
  newInstalls: number;
  activeUsers: number;
  itemsAdded: number;
  d1Retention: number;
  crashFreeRate: number;
}

/**
 * Get current 24h aggregated metrics from DuckDB
 */
export async function getCurrentMetrics(): Promise<CurrentMetrics | null> {
  try {
    const response = await fetch(`${WORKER_URL}/metrics/current`);

    if (!response.ok) {
      console.error(`[DuckDB] Failed to fetch current metrics: ${response.status}`);
      return null;
    }

    const result = (await response.json()) as any;

    if (!result.data) {
      console.warn('[DuckDB] No metrics data returned');
      return null;
    }

    const data = result.data;

    // Transform from DuckDB column names to API format
    return {
      newInstalls: data.new_installs_24h || 0,
      reinstalls: data.reinstalls_24h || 0,
      activeUsers: data.active_users_24h || 0,
      itemsAdded: data.items_added_24h || 0,
      itemsWasted: data.items_wasted_24h || 0,
      totalWasteCost: (data.total_waste_cost_cents_24h || 0) / 100, // Convert cents to dollars
      camerAssistanceRate: (data.camera_assist_items_pct || 0) / 100, // Convert percentage to decimal
      d1Retention: (data.d1_retention_pct || 0) / 100,
      crashFreeRate: (data.crash_free_rate_pct || 0) / 100,
      avgSessionDuration: data.avg_session_duration_seconds || 0,
      notificationOptInRate: (data.notification_opt_in_rate_pct || 0) / 100,
      timestamp: data.summary_timestamp || new Date().toISOString(),
    };
  } catch (error) {
    console.error('[DuckDB] Error fetching current metrics:', error);
    return null;
  }
}

/**
 * Get historical metrics for the past N days
 */
export async function getHistoricalMetrics(days: number = 7): Promise<HistoricalMetric[]> {
  try {
    const response = await fetch(
      `${WORKER_URL}/metrics/history?days=${Math.min(Math.max(days, 1), 30)}`
    );

    if (!response.ok) {
      console.error(`[DuckDB] Failed to fetch historical metrics: ${response.status}`);
      return [];
    }

    const result = (await response.json()) as any;

    if (!result.data || !Array.isArray(result.data)) {
      console.warn('[DuckDB] No historical metrics data returned');
      return [];
    }

    // Transform from DuckDB format to API format
    return result.data.map((row: any) => ({
      timestamp: row.summary_timestamp || new Date().toISOString(),
      newInstalls: row.new_installs_24h || 0,
      activeUsers: row.active_users_24h || 0,
      itemsAdded: row.items_added_24h || 0,
      d1Retention: (row.d1_retention_pct || 0) / 100,
      crashFreeRate: (row.crash_free_rate_pct || 0) / 100,
    }));
  } catch (error) {
    console.error('[DuckDB] Error fetching historical metrics:', error);
    return [];
  }
}

/**
 * Get camera adoption statistics
 */
export async function getCameraAdoptionStats() {
  try {
    const response = await fetch(`${WORKER_URL}/metrics/camera-adoption`);

    if (!response.ok) {
      return null;
    }

    const result = (await response.json()) as any;
    return result.data;
  } catch (error) {
    console.error('[DuckDB] Error fetching camera adoption stats:', error);
    return null;
  }
}

/**
 * Get waste analysis by category
 */
export async function getWasteAnalysis() {
  try {
    const response = await fetch(`${WORKER_URL}/metrics/waste-analysis`);

    if (!response.ok) {
      return null;
    }

    const result = (await response.json()) as any;
    return result.data;
  } catch (error) {
    console.error('[DuckDB] Error fetching waste analysis:', error);
    return null;
  }
}

/**
 * Get ETL execution history
 */
export async function getETLHistory(limit: number = 10) {
  try {
    const response = await fetch(`${WORKER_URL}/etl/history?limit=${limit}`);

    if (!response.ok) {
      return [];
    }

    const result = (await response.json()) as any;
    return result.data || [];
  } catch (error) {
    console.error('[DuckDB] Error fetching ETL history:', error);
    return [];
  }
}

/**
 * Check if DuckDB is available and has data
 */
export async function isDuckDBReady(): Promise<boolean> {
  try {
    const metrics = await getCurrentMetrics();
    return metrics !== null;
  } catch (error) {
    return false;
  }
}
