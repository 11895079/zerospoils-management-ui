import { Router, Request, Response } from 'express';
import fetch from 'node-fetch';
import { generateMockMetrics, generateMetricsHistory } from '../mocks/data.js';
import { requireRole } from '../middleware/auth.js';
import {
  getCurrentMetrics,
  getHistoricalMetrics,
  isDuckDBReady,
} from '../services/duckdb.js';

const router = Router();

/**
 * Get current metrics snapshot
 * Queries DuckDB if available, falls back to mock data for development
 * Available to: analyst, admin
 */
router.get('/metrics/current', requireRole('admin', 'analyst'), async (req: Request, res: Response) => {
  try {
    // Try to fetch from DuckDB
    const duckdbMetrics = await getCurrentMetrics();

    if (duckdbMetrics) {
      return res.json({
        data: duckdbMetrics,
        source: 'duckdb',
        timestamp: duckdbMetrics.timestamp,
        profile: process.env.APP_PROFILE || 'local',
      });
    }
  } catch (error) {
    console.warn('[Metrics] DuckDB query failed, falling back to mock:', error);
  }

  // Fallback to mock data for development/when DuckDB is unavailable
  const metrics = generateMockMetrics();

  res.json({
    data: metrics,
    source: 'mock',
    timestamp: new Date().toISOString(),
    profile: process.env.APP_PROFILE || 'local',
  });
});

/**
 * Get historical metrics
 * Queries DuckDB if available, falls back to mock data for development
 * Available to: analyst, admin
 */
router.get(
  '/metrics/history',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    const daysParam = req.query.days ? parseInt(req.query.days as string) : 7;
    const days = Math.min(Math.max(daysParam, 1), 30); // Clamp 1-30 days

    try {
      // Try to fetch from DuckDB
      const duckdbMetrics = await getHistoricalMetrics(days);

      if (duckdbMetrics && duckdbMetrics.length > 0) {
        return res.json({
          data: duckdbMetrics,
          source: 'duckdb',
          days,
          count: duckdbMetrics.length,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (error) {
      console.warn('[Metrics] DuckDB query failed, falling back to mock:', error);
    }

    // Fallback to mock data
    const hoursParam = days * 24; // Convert days to hours for mock data generator
    const metrics = generateMetricsHistory(hoursParam);

    res.json({
      data: metrics,
      source: 'mock',
      days,
      count: metrics.length,
      timestamp: new Date().toISOString(),
    });
  }
);

/**
 * Get key metrics summary with trends
 * Available to: all authenticated users
 */
router.get('/metrics/summary', async (req: Request, res: Response) => {
  try {
    const current = await getCurrentMetrics();
    const history = await getHistoricalMetrics(7);

    if (current && history && history.length > 0) {
      // Calculate trend from actual data
      const recentAvg =
        history.slice(-Math.ceil(history.length / 2)).reduce((sum, m) => sum + m.newInstalls, 0) /
        Math.ceil(history.length / 2);
      const previousAvg =
        history.slice(0, Math.floor(history.length / 2)).reduce((sum, m) => sum + m.newInstalls, 0) /
        Math.floor(history.length / 2);
      const installsTrend = previousAvg > 0 ? ((recentAvg - previousAvg) / previousAvg) * 100 : 0;

      return res.json({
        current,
        trends: {
          installs24h: installsTrend,
          retention7d: current.d1Retention * 100,
          crashFreeRate: current.crashFreeRate * 100,
        },
        source: 'duckdb',
        timestamp: new Date().toISOString(),
      });
    }
  } catch (error) {
    console.warn('[Metrics] DuckDB query failed, falling back to mock:', error);
  }

  // Fallback to mock data
  const current = generateMockMetrics();
  const history = generateMetricsHistory(7);

  const recentAvg = history.slice(-7).reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const previousAvg = history.slice(0, 7).reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const installsTrend = ((recentAvg - previousAvg) / previousAvg) * 100;

  res.json({
    current,
    trends: {
      installs24h: installsTrend,
      retention7d: current.d1Retention * 100,
      crashFreeRate: current.crashFreeRate * 100,
    },
    source: 'mock',
    timestamp: new Date().toISOString(),
  });
});

/**
 * Get ETL pipeline status and history
 * Available to: admin
 */
router.get('/metrics/etl-status', requireRole('admin'), async (req: Request, res: Response) => {
  try {
    const response = await fetch(`${process.env.WORKER_URL || 'http://worker:3002'}/health`);

    if (!response.ok) {
      return res.status(503).json({
        status: 'unavailable',
        error: 'Worker service not responding',
      });
    }

    const health = (await response.json()) as any;

    res.json({
      worker_status: health.status,
      services: health.services,
      etl_status: health.jobs?.telemetry_etl,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: 'unavailable',
      error: String(error),
    });
  }
});

/**
 * Check DuckDB readiness
 * Available to: admin
 */
router.get('/metrics/health', requireRole('admin'), async (req: Request, res: Response) => {
  const ready = await isDuckDBReady();

  res.json({
    duckdb_ready: ready,
    timestamp: new Date().toISOString(),
  });
});

export default router;
