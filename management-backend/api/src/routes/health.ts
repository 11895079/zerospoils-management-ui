import { Router, Request, Response } from 'express';
import type { HealthStatus } from '../types/index.js';

const router = Router();

const startTime = Date.now();

/**
 * Health check endpoint - used for service discovery and monitoring
 */
router.get('/health', (req: Request, res: Response) => {
  const uptime = Math.floor((Date.now() - startTime) / 1000);

  const health: HealthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      api: {
        status: 'up',
        responseTime: 5,
        lastCheck: new Date().toISOString(),
        version: '0.1.0',
      },
      worker: {
        status: 'up',
        responseTime: 10,
        lastCheck: new Date().toISOString(),
        version: '0.1.0',
      },
      duckdb: {
        status: 'up',
        responseTime: 2,
        lastCheck: new Date().toISOString(),
        version: '0.8.0',
      },
    },
    uptime,
  };

  res.json(health);
});

/**
 * Status endpoint - service configuration and diagnostics
 */
router.get('/status', (req: Request, res: Response) => {
  res.json({
    service: 'zerospoils-mgmt-api',
    version: '0.1.0',
    profile: process.env.APP_PROFILE || 'local',
    uptime: Math.floor((Date.now() - startTime) / 1000),
    timestamp: new Date().toISOString(),
    config: {
      apiPort: process.env.API_PORT || 3001,
      corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:3000',
      profile: process.env.APP_PROFILE || 'local',
    },
    // In production, don't expose full config
    hint: 'This is development mode - config is exposed for debugging',
  });
});

export default router;
