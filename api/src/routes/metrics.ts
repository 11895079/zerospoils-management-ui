import { Router, Request, Response } from 'express';
import { generateMockMetrics, generateMetricsHistory } from '../mocks/data.js';
import { requireRole } from '../middleware/auth.js';
import {
  getCurrentMetricsFromDuckDB,
  getHistoricalMetricsFromDuckDB,
} from '../services/duckdb.js';

const router = Router();

/**
 * Get current metrics snapshot
 * Available to: analyst, admin
 */
router.get('/metrics/current', requireRole('admin', 'analyst'), async (req: Request, res: Response) => {
  const metrics = await getCurrentMetricsFromDuckDB();
  const usedFallback = !metrics;

  res.json({
    data: metrics ?? generateMockMetrics(),
    source: usedFallback ? 'mock-fallback' : 'duckdb',
    timestamp: new Date().toISOString(),
    profile: process.env.APP_PROFILE || 'local',
    fallbackReason: usedFallback
      ? 'DuckDB marts unavailable from worker; served deterministic mock fallback'
      : null,
  });
});

/**
 * Get historical metrics (24h by default)
 * Available to: analyst, admin
 */
router.get('/metrics/history', requireRole('admin', 'analyst'), async (req: Request, res: Response) => {
  const hoursParam = req.query.hours ? parseInt(req.query.hours as string) : 24;
  const hours = Math.min(Math.max(hoursParam, 1), 720); // Clamp 1-720 hours (30 days)

  const duckdbMetrics = await getHistoricalMetricsFromDuckDB(hours);
  const metrics = duckdbMetrics.length > 0 ? duckdbMetrics : generateMetricsHistory(hours);
  const usedFallback = duckdbMetrics.length === 0;

  res.json({
    data: metrics,
    source: usedFallback ? 'mock-fallback' : 'duckdb',
    hours,
    count: metrics.length,
    timestamp: new Date().toISOString(),
    fallbackReason: usedFallback
      ? 'DuckDB marts unavailable from worker; served deterministic mock fallback'
      : null,
  });
});

/**
 * Get key metrics summary
 * Available to: all authenticated users
 */
router.get('/metrics/summary', async (req: Request, res: Response) => {
  const current = await getCurrentMetricsFromDuckDB();
  const history = await getHistoricalMetricsFromDuckDB(24 * 7);
  const usedFallback = !current || history.length === 0;
  const safeCurrent = current ?? generateMockMetrics();
  const safeHistory = history.length > 0 ? history : generateMetricsHistory(7);

  // Calculate trend (compare last 7 days to previous week)
  const recentAvg =
    safeHistory.slice(-7).reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const previousAvg = safeHistory
    .slice(0, 7)
    .reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const installsTrend = previousAvg === 0 ? 0 : ((recentAvg - previousAvg) / previousAvg) * 100;

  res.json({
    current: safeCurrent,
    source: usedFallback ? 'mock-fallback' : 'duckdb',
    trends: {
      installs24h: installsTrend,
      retention7d: safeCurrent.d1Retention * 100,
      crashFreeRate: safeCurrent.crashFreeRate * 100,
    },
    timestamp: new Date().toISOString(),
    fallbackReason: usedFallback
      ? 'DuckDB marts unavailable from worker; served deterministic mock fallback'
      : null,
  });
});

export default router;
