import { Router, Request, Response } from 'express';
import { generateMockMetrics, generateMetricsHistory } from '../mocks/data.js';
import { requireRole } from '../middleware/auth.js';

const router = Router();

/**
 * Get current metrics snapshot
 * Available to: analyst, admin
 */
router.get('/metrics/current', requireRole('admin', 'analyst'), (req: Request, res: Response) => {
  const metrics = generateMockMetrics();

  res.json({
    data: metrics,
    timestamp: new Date().toISOString(),
    profile: process.env.APP_PROFILE || 'local',
  });
});

/**
 * Get historical metrics (24h by default)
 * Available to: analyst, admin
 */
router.get('/metrics/history', requireRole('admin', 'analyst'), (req: Request, res: Response) => {
  const hoursParam = req.query.hours ? parseInt(req.query.hours as string) : 24;
  const hours = Math.min(Math.max(hoursParam, 1), 720); // Clamp 1-720 hours (30 days)

  const metrics = generateMetricsHistory(hours);

  res.json({
    data: metrics,
    hours,
    count: metrics.length,
    timestamp: new Date().toISOString(),
  });
});

/**
 * Get key metrics summary
 * Available to: all authenticated users
 */
router.get('/metrics/summary', (req: Request, res: Response) => {
  const current = generateMockMetrics();
  const history = generateMetricsHistory(7);

  // Calculate trend (compare last 7 days to previous week)
  const recentAvg =
    history.slice(-7).reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const previousAvg = history
    .slice(0, 7)
    .reduce((sum, m) => sum + m.newInstalls, 0) / 7;
  const installsTrend = ((recentAvg - previousAvg) / previousAvg) * 100;

  res.json({
    current,
    trends: {
      installs24h: installsTrend,
      retention7d: current.d1Retention * 100,
      crashFreeRate: current.crashFreeRate * 100,
    },
    timestamp: new Date().toISOString(),
  });
});

export default router;
