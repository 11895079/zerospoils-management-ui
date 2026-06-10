import { Router, Request, Response } from 'express';
import { mockDataStore } from '../mocks/data.js';
import { requireRole } from '../middleware/auth.js';

const router = Router();

/**
 * Get telemetry events
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/events',
  requireRole('admin', 'analyst'),
  (req: Request, res: Response) => {
    const platform = req.query.platform as string | undefined;
    const eventName = req.query.event as string | undefined;
    const limit = Math.min(parseInt(req.query.limit as string) || 100, 1000);

    let events = mockDataStore.telemetryEvents;

    if (platform) {
      events = events.filter((e) => e.platform === platform);
    }
    if (eventName) {
      events = events.filter((e) => e.eventName === eventName);
    }

    // Return most recent first
    const result = events
      .sort(
        (a, b) =>
          new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      )
      .slice(0, limit);

    res.json({
      data: result,
      count: result.length,
      total: mockDataStore.telemetryEvents.length,
      filters: { platform, eventName },
      timestamp: new Date().toISOString(),
    });
  }
);

/**
 * Get telemetry event summary
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/summary',
  requireRole('admin', 'analyst'),
  (req: Request, res: Response) => {
    const events = mockDataStore.telemetryEvents;

    // Group by event name
    const byEvent: Record<string, number> = {};
    events.forEach((e) => {
      byEvent[e.eventName] = (byEvent[e.eventName] || 0) + 1;
    });

    // Group by platform
    const byPlatform: Record<string, number> = {};
    events.forEach((e) => {
      byPlatform[e.platform] = (byPlatform[e.platform] || 0) + 1;
    });

    // Calculate schema validation stats
    const schemaRejects = Math.floor(events.length * 0.02); // Mock 2% reject rate
    const ingestionLag = Math.floor(Math.random() * 500) + 100; // 100-600ms

    res.json({
      totalEvents: events.length,
      byEventName: byEvent,
      byPlatform,
      validation: {
        accepted: events.length,
        rejected: schemaRejects,
        rejectRate: (schemaRejects / (events.length + schemaRejects)) * 100,
      },
      ingestion: {
        lagMs: ingestionLag,
        freshness: new Date(
          Date.now() - Math.random() * 60 * 1000
        ).toISOString(),
      },
      timestamp: new Date().toISOString(),
    });
  }
);

/**
 * Get telemetry platform split
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/platforms',
  requireRole('admin', 'analyst'),
  (req: Request, res: Response) => {
    const events = mockDataStore.telemetryEvents;

    const ios = events.filter((e) => e.platform === 'ios').length;
    const android = events.filter((e) => e.platform === 'android').length;
    const total = ios + android;

    res.json({
      data: [
        {
          platform: 'iOS',
          count: ios,
          percentage: ((ios / total) * 100).toFixed(1),
        },
        {
          platform: 'Android',
          count: android,
          percentage: ((android / total) * 100).toFixed(1),
        },
      ],
      total,
      timestamp: new Date().toISOString(),
    });
  }
);

export default router;
