import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import {
  closeDuckDBMarts,
  getEtlRuns,
  getCurrentMetrics,
  getHistoricalMetrics,
  initializeDuckDBMarts,
  isDuckDBReady,
} from './services/duckdbMarts.js';
import {
  closeQueueInfrastructure,
  enqueueJob,
  getJobHistory,
  getQueueHealthStatus,
  getQueueSnapshot,
  initializeQueueInfrastructure,
  isQueueName,
  retryFailedJob,
  type QueueName,
} from './services/etlQueue.js';

dotenv.config({ path: '../api/.env.local' });

// Validate required environment variables
const requiredEnvVars = ['APP_PROFILE', 'WORKER_PORT'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar] && envVar !== 'WORKER_PORT') {
    console.warn(`⚠️  Environment variable ${envVar} not set, using default`);
  }
}

const app = express();
const port = parseInt(process.env.WORKER_PORT || '3002');
const startTime = Date.now();
const duckdbPath = process.env.DUCKDB_PATH || '/tmp/zerospoils_analytics.duckdb';
const redisUrl = process.env.REDIS_URL || 'redis://redis:6379';

// Middleware
app.use(express.json());
app.use(cors());

// Health check
app.get('/health', async (_req, res) => {
  const queueStatus = await getQueueHealthStatus();
  const queueSnapshot = await getQueueSnapshot();

  res.json({
    service: 'zerospoils-mgmt-worker',
    status:
      isDuckDBReady() && queueStatus === 'up'
        ? 'healthy'
        : isDuckDBReady() || queueStatus === 'up'
          ? 'degraded'
          : 'unhealthy',
    uptime: Math.floor((Date.now() - startTime) / 1000),
    timestamp: new Date().toISOString(),
    services: {
      duckdb: {
        status: isDuckDBReady() ? 'up' : 'down',
      },
      redis: {
        status: queueStatus,
      },
    },
    queues: queueSnapshot,
    jobs: {
      telemetry_etl: queueSnapshot.telemetry_etl,
      feedback_processor: queueSnapshot.feedback_processor,
      telemetry_batch: queueSnapshot.telemetry_batch,
    },
  });
});

// DuckDB-backed marts for dashboard metrics
app.get('/metrics/current', async (_req, res) => {
  try {
    if (!isDuckDBReady()) {
      return res.status(503).json({ error: 'DuckDB marts not initialized' });
    }

    const data = await getCurrentMetrics();
    if (!data) {
      return res.status(404).json({ error: 'No metrics data available' });
    }

    return res.json({ data });
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

app.get('/metrics/history', async (req, res) => {
  try {
    if (!isDuckDBReady()) {
      return res.status(503).json({ error: 'DuckDB marts not initialized' });
    }

    const hoursParam = req.query.hours ? parseInt(req.query.hours as string, 10) : 24;
    const data = await getHistoricalMetrics(hoursParam);
    return res.json({ data, count: data.length });
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

// Queue status
app.get('/queues', async (_req, res) => {
  const queues = await getQueueSnapshot();
  res.json({ queues, timestamp: new Date().toISOString() });
});

// Job history
app.get('/jobs', async (req, res) => {
  const status = req.query.status as
    | 'completed'
    | 'failed'
    | 'active'
    | 'wait'
    | 'delayed'
    | 'paused'
    | undefined;
  const queue = req.query.queue as QueueName | undefined;
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
  const jobs = await getJobHistory({ status, queue, limit });

  res.json({
    data: jobs,
    count: jobs.length,
    etlAudit: getEtlRuns(limit),
    timestamp: new Date().toISOString(),
  });
});

app.post('/jobs/enqueue', async (req, res) => {
  const queueCandidate = req.body?.queue as string | undefined;
  if (!queueCandidate || !isQueueName(queueCandidate)) {
    return res.status(400).json({ error: 'queue is required' });
  }
  const queue = queueCandidate as QueueName;

  const jobId = await enqueueJob({
    queue,
    payload: req.body?.payload,
  });

  return res.status(202).json({
    queue,
    jobId,
    status: 'queued',
    timestamp: new Date().toISOString(),
  });
});

app.post('/jobs/:queue/:jobId/retry', async (req, res) => {
  const queueCandidate = req.params.queue;
  if (!isQueueName(queueCandidate)) {
    return res.status(400).json({
      retried: false,
      reason: 'invalid queue name',
    });
  }

  const queue = queueCandidate as QueueName;
  const jobId = req.params.jobId;

  const retried = await retryFailedJob(queue, jobId);
  if (!retried.retried) {
    return res.status(409).json({
      queue,
      jobId,
      retried: false,
      reason: retried.reason,
    });
  }

  return res.json({
    queue,
    jobId,
    retried: true,
    timestamp: new Date().toISOString(),
  });
});

async function startWorker() {
  await initializeDuckDBMarts(duckdbPath);
  await initializeQueueInfrastructure(redisUrl);

  app.listen(port, () => {
    console.log(`\n✅ Background Worker initialized`);
    console.log(`   Port: ${port}`);
    console.log(`   Profile: ${process.env.APP_PROFILE || 'local'}`);
    console.log(`   DuckDB: ${duckdbPath}`);
    console.log(`   Redis: ${redisUrl}`);
    console.log(`\n📚 Available endpoints:`);
    console.log(`   GET /health           - Worker health status`);
    console.log(`   GET /queues           - Job queue status`);
    console.log(`   GET /jobs             - Job history`);
    console.log(`   POST /jobs/enqueue    - Enqueue manual job`);
    console.log(`   POST /jobs/:queue/:jobId/retry - Retry failed job`);
    console.log(`   GET /metrics/current  - DuckDB current metrics mart`);
    console.log(`   GET /metrics/history  - DuckDB historical metrics mart\n`);
  });
}

startWorker().catch((error) => {
  console.error('Failed to initialize worker services:', error);
  process.exit(1);
});

process.on('SIGINT', async () => {
  await closeQueueInfrastructure();
  await closeDuckDBMarts();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await closeQueueInfrastructure();
  await closeDuckDBMarts();
  process.exit(0);
});

export default app;
