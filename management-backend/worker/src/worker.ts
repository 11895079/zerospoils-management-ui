import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import IORedis from 'ioredis';
import { Database } from 'duckdb';
import {
  initializeDuckDB,
  closeDuckDB,
  testConnection,
  getCurrentMetrics,
  getHistoricalMetrics,
  getETLHistory,
} from './services/duckdb.service';
import ETLScheduler from './scheduler/etl-scheduler';

dotenv.config({ path: '../api/.env.local' });

const app = express();
const port = parseInt(process.env.WORKER_PORT || '3002');
const startTime = Date.now();
const redisURL = process.env.REDIS_URL || 'redis://redis:6379';
const dbPath = process.env.DUCKDB_PATH || './data/zerospoils_analytics.db';
const etlIntervalMinutes = parseInt(process.env.ETL_INTERVAL_MINUTES || '10', 10);

// Middleware
app.use(express.json());
app.use(cors());

// Global state
let db: Database | null = null;
let scheduler: ETLScheduler | null = null;
let isHealthy = false;

// Initialize Redis connection
const redis = new IORedis(redisURL, {
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
});

redis.on('connect', () => {
  console.log('[Redis] Connected');
});

redis.on('error', (err) => {
  console.error('[Redis] Connection error:', err);
});

/**
 * Initialize DuckDB and ETL infrastructure
 */
async function initializeServices() {
  try {
    console.log('[Services] Initializing DuckDB...');
    db = await initializeDuckDB(dbPath);

    // Test connection
    const connected = await testConnection(db);
    if (!connected) {
      throw new Error('Failed to connect to DuckDB');
    }

    console.log('[Services] DuckDB initialized successfully');

    // Initialize ETL scheduler
    console.log('[Services] Initializing ETL scheduler...');
    scheduler = new ETLScheduler({
      redis,
      queueName: 'etl-pipeline',
      intervalMinutes: etlIntervalMinutes,
    });

    await scheduler.initialize(db);

    isHealthy = true;
    console.log('[Services] All services initialized successfully');
  } catch (error) {
    console.error('[Services] Initialization failed:', error);
    isHealthy = false;
    throw error;
  }
}

/**
 * Health check endpoint
 */
app.get('/health', async (req, res) => {
  try {
    const duckdbHealth = db ? await testConnection(db) : false;
    const redisHealth = redis.status === 'ready';
    const schedulerStatus = scheduler ? await scheduler.getStatus() : null;

    const health = {
      service: 'zerospoils-mgmt-worker',
      status: isHealthy && duckdbHealth && redisHealth ? 'healthy' : 'degraded',
      uptime: Math.floor((Date.now() - startTime) / 1000),
      timestamp: new Date().toISOString(),
      services: {
        duckdb: { status: duckdbHealth ? 'healthy' : 'unhealthy' },
        redis: { status: redisHealth ? 'healthy' : 'unhealthy' },
        etl: {
          status: schedulerStatus?.isRunning ? 'running' : 'stopped',
          intervalMinutes: etlIntervalMinutes,
          nextRun: schedulerStatus?.nextScheduledRun || null,
        },
      },
    };

    res.json(health);
  } catch (error) {
    res.status(500).json({
      service: 'zerospoils-mgmt-worker',
      status: 'unhealthy',
      error: String(error),
    });
  }
});

/**
 * Scheduler status endpoint
 */
app.get('/scheduler/status', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    const status = await scheduler.getStatus();
    res.json(status);
  } catch (error) {
    res.status(500).json({
      error: String(error),
    });
  }
});

/**
 * Queue status endpoint
 */
app.get('/queues', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    const status = await scheduler.getStatus();

    res.json({
      queues: {
        etl_pipeline: status.jobCounts,
      },
      nextScheduledRun: status.nextScheduledRun,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      error: String(error),
    });
  }
});

/**
 * Job history endpoint
 */
app.get('/jobs', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    const status = await scheduler.getStatus();
    const limit = parseInt((req.query.limit as string) || '20', 10);

    res.json({
      data: status.recentJobs.slice(0, limit),
      count: status.recentJobs.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      error: String(error),
    });
  }
});

/**
 * Metrics endpoint (from DuckDB marts)
 */
app.get('/metrics/current', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: 'DuckDB not initialized' });
    }

    const metrics = await getCurrentMetrics(db);
    res.json({ data: metrics });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Historical metrics endpoint
 */
app.get('/metrics/history', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: 'DuckDB not initialized' });
    }

    const days = parseInt((req.query.days as string) || '7', 10);
    const metrics = await getHistoricalMetrics(db, days);

    res.json({
      data: metrics,
      count: metrics.length,
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * ETL audit history endpoint
 */
app.get('/etl/history', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: 'DuckDB not initialized' });
    }

    const limit = parseInt((req.query.limit as string) || '20', 10);
    const history = await getETLHistory(db, limit);

    res.json({
      data: history,
      count: history.length,
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Manually trigger ETL run
 */
app.post('/etl/run', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    const jobId = await scheduler.triggerManual(
      (req.body.source as 'mock' | 'zerospoils') || 'mock'
    );

    res.json({
      job_id: jobId,
      status: 'queued',
      message: 'ETL job queued for processing',
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Pause scheduler
 */
app.post('/scheduler/pause', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    await scheduler.pause();

    res.json({
      status: 'paused',
      message: 'ETL scheduler paused',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Resume scheduler
 */
app.post('/scheduler/resume', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    await scheduler.resume();

    res.json({
      status: 'running',
      message: 'ETL scheduler resumed',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Clear queue (admin only)
 */
app.post('/scheduler/clear', async (req, res) => {
  try {
    if (!scheduler) {
      return res.status(503).json({ error: 'Scheduler not initialized' });
    }

    // Require authorization header with admin token
    const auth = req.headers.authorization;
    if (auth !== 'Bearer admin-secret-token') {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    await scheduler.clearQueue();

    res.json({
      status: 'cleared',
      message: 'ETL queue cleared',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Shutdown handler
 */
async function shutdown() {
  console.log('[Services] Shutting down...');

  if (scheduler) {
    await scheduler.close();
  }

  if (db) {
    await closeDuckDB();
  }

  redis.disconnect();

  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

/**
 * Start worker
 */
async function startWorker() {
  try {
    await initializeServices();

    app.listen(port, () => {
      console.log(`\n🔄 Background Worker running on http://localhost:${port}`);
      console.log(`📝 Profile: ${process.env.APP_PROFILE || 'local'}`);
      console.log(`📊 Database: ${dbPath}`);
      console.log(`🗳️  Redis: ${redisURL}`);
      console.log(`⏱️  ETL Interval: ${etlIntervalMinutes} minutes`);
      console.log(`\n📚 Available endpoints:`);
      console.log(`\n  Health & Status:`);
      console.log(`  GET  /health                   - Worker health status`);
      console.log(`  GET  /scheduler/status         - Detailed scheduler status`);
      console.log(`\n  Queue Management:`);
      console.log(`  GET  /queues                   - Job queue counts`);
      console.log(`  GET  /jobs?limit=20            - Job history`);
      console.log(`\n  ETL Control:`);
      console.log(`  POST /etl/run                  - Manually trigger ETL`);
      console.log(`  POST /scheduler/pause          - Pause scheduler`);
      console.log(`  POST /scheduler/resume         - Resume scheduler`);
      console.log(`  POST /scheduler/clear          - Clear queue (admin)`);
      console.log(`\n  Metrics:`);
      console.log(`  GET  /metrics/current          - Current 24h metrics`);
      console.log(`  GET  /metrics/history?days=7   - Historical metrics`);
      console.log(`  GET  /etl/history?limit=20     - ETL execution history\n`);
    });
  } catch (error) {
    console.error('[Worker] Failed to start:', error);
    process.exit(1);
  }
}

startWorker();

export default app;
