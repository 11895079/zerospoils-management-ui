import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { Queue, Worker, QueueEvents } from 'bullmq';
import IORedis from 'ioredis';
import { Database } from 'duckdb';
import path from 'path';
import {
  initializeDuckDB,
  getDatabase,
  closeDuckDB,
  testConnection,
  getCurrentMetrics,
  getHistoricalMetrics,
  getETLHistory,
} from './services/duckdb.service';
import { processETLJob, ETLJobData } from './jobs/etlJob';

dotenv.config({ path: '../api/.env.local' });

const app = express();
const port = parseInt(process.env.WORKER_PORT || '3002');
const startTime = Date.now();
const redisURL = process.env.REDIS_URL || 'redis://redis:6379';
const dbPath = process.env.DUCKDB_PATH || './data/zerospoils_analytics.db';

// Middleware
app.use(express.json());
app.use(cors());

// Global state
let db: Database | null = null;
let etlQueue: Queue<ETLJobData> | null = null;
let etlWorker: Worker<ETLJobData> | null = null;
let queueEvents: QueueEvents | null = null;
let isHealthy = false;
let lastETLRun: { timestamp: Date; success: boolean; result?: any } | null = null;

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

    // Initialize BullMQ queue
    console.log('[Services] Initializing BullMQ queue...');
    etlQueue = new Queue<ETLJobData>('etl-pipeline', {
      connection: redis,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
        removeOnComplete: false,
      },
    });

    // Set up queue events for monitoring
    queueEvents = new QueueEvents('etl-pipeline', {
      connection: redis,
    });

    queueEvents.on('completed', ({ jobId, returnvalue }) => {
      console.log(`[ETL] Job ${jobId} completed:`, returnvalue);
      lastETLRun = {
        timestamp: new Date(),
        success: true,
        result: returnvalue,
      };
    });

    queueEvents.on('failed', ({ jobId, failedReason }) => {
      console.error(`[ETL] Job ${jobId} failed:`, failedReason);
      lastETLRun = {
        timestamp: new Date(),
        success: false,
      };
    });

    // Register ETL job processor
    console.log('[Services] Registering ETL job processor...');
    etlWorker = new Worker<ETLJobData>(
      'etl-pipeline',
      async (job) => {
        try {
          if (!db) {
            throw new Error('DuckDB not initialized');
          }
          return await processETLJob(job, db);
        } catch (error) {
          console.error('[ETL Worker] Error processing job:', error);
          throw error;
        }
      },
      {
        connection: redis,
        concurrency: 1, // Process one job at a time
      }
    );

    etlWorker.on('progress', (job, progress) => {
      console.log(`[ETL Worker] Job ${job.id} progress: ${progress}%`);
    });

    // Schedule ETL to run every 10 minutes
    console.log('[Services] Scheduling ETL pipeline...');
    await scheduleETLPipeline();

    isHealthy = true;
    console.log('[Services] All services initialized successfully');
  } catch (error) {
    console.error('[Services] Initialization failed:', error);
    isHealthy = false;
    throw error;
  }
}

/**
 * Schedule ETL pipeline to run every 10 minutes
 */
async function scheduleETLPipeline() {
  if (!etlQueue) {
    throw new Error('ETL queue not initialized');
  }

  // Add recurring job (every 10 minutes)
  // In production, would use BullMQ's repeat options or a cron scheduler
  const scheduleETL = async () => {
    try {
      await etlQueue!.add(
        'run',
        {
          source: process.env.TELEMETRY_SOURCE === 'zerospoils' ? 'zerospoils' : 'mock',
          force_refresh: false,
        },
        {
          jobId: `etl-${Date.now()}`,
          repeat: {
            every: 10 * 60 * 1000, // 10 minutes
          },
        }
      );
    } catch (error) {
      console.error('[ETL] Failed to schedule:', error);
    }
  };

  // Initial schedule
  await scheduleETL();
}

/**
 * Health check endpoint
 */
app.get('/health', async (req, res) => {
  try {
    const duckdbHealth = db ? await testConnection(db) : false;
    const redisHealth = redis.status === 'ready';

    const health = {
      service: 'zerospoils-mgmt-worker',
      status: isHealthy && duckdbHealth && redisHealth ? 'healthy' : 'degraded',
      uptime: Math.floor((Date.now() - startTime) / 1000),
      timestamp: new Date().toISOString(),
      services: {
        duckdb: { status: duckdbHealth ? 'healthy' : 'unhealthy' },
        redis: { status: redisHealth ? 'healthy' : 'unhealthy' },
        etl: {
          status: etlQueue ? 'running' : 'stopped',
          lastRun: lastETLRun?.timestamp || null,
          lastSuccess: lastETLRun?.success || null,
        },
      },
      jobs: {
        telemetry_etl: {
          status: 'scheduled',
          interval: '10 minutes',
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
 * Queue status endpoint
 */
app.get('/queues', async (req, res) => {
  try {
    if (!etlQueue) {
      return res.status(503).json({ error: 'ETL queue not initialized' });
    }

    const counts = await etlQueue.getCountsPerStatus();

    res.json({
      queues: {
        etl_pipeline: {
          ...counts,
          timestamp: new Date().toISOString(),
        },
      },
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
    if (!etlQueue) {
      return res.status(503).json({ error: 'ETL queue not initialized' });
    }

    const status = (req.query.status as string) || 'completed';
    const limit = parseInt((req.query.limit as string) || '20', 10);

    const jobs = await etlQueue.getJobs([status as any], 0, limit - 1);

    res.json({
      data: jobs.map(job => ({
        id: job.id,
        name: job.name,
        status: job._status,
        progress: job.progress(),
        data: job.data,
        result: (job as any).returnvalue,
        failedReason: job.failedReason,
        attempts: job.attemptsMade,
        maxAttempts: job.opts.attempts,
        timestamp: new Date(job.timestamp).toISOString(),
      })),
      count: jobs.length,
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
    if (!etlQueue) {
      return res.status(503).json({ error: 'ETL queue not initialized' });
    }

    const job = await etlQueue.add('run', {
      source: req.body.source || 'mock',
      force_refresh: req.body.force_refresh || false,
    });

    res.json({
      job_id: job.id,
      status: 'queued',
      message: 'ETL job queued for processing',
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

  if (etlWorker) {
    await etlWorker.close();
  }

  if (queueEvents) {
    await queueEvents.close();
  }

  if (etlQueue) {
    await etlQueue.close();
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
      console.log(`\n📚 Available endpoints:`);
      console.log(`  GET /health                    - Worker health status`);
      console.log(`  GET /queues                    - Job queue status`);
      console.log(`  GET /jobs?status=completed     - Job history`);
      console.log(`  GET /etl/history               - ETL execution history`);
      console.log(`  POST /etl/run                  - Manually trigger ETL`);
      console.log(`  GET /metrics/current           - Current 24h metrics`);
      console.log(`  GET /metrics/history?days=7    - Historical metrics\n`);
    });
  } catch (error) {
    console.error('[Worker] Failed to start:', error);
    process.exit(1);
  }
}

startWorker();

export default app;
