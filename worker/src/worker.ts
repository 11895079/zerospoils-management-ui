import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import {
  closeDuckDBMarts,
  getCurrentMetrics,
  getHistoricalMetrics,
  initializeDuckDBMarts,
  isDuckDBReady,
} from './services/duckdbMarts.js';

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

// Middleware
app.use(express.json());
app.use(cors());

// Health check
app.get('/health', (req, res) => {
  res.json({
    service: 'zerospoils-mgmt-worker',
    status: isDuckDBReady() ? 'healthy' : 'degraded',
    uptime: Math.floor((Date.now() - startTime) / 1000),
    timestamp: new Date().toISOString(),
    services: {
      duckdb: {
        status: isDuckDBReady() ? 'up' : 'down',
      },
    },
    jobs: {
      telemetry_etl: {
        status: 'idle',
        nextRun: new Date(Date.now() + 60000).toISOString(),
      },
      feedback_processor: {
        status: 'idle',
        nextRun: new Date(Date.now() + 30000).toISOString(),
      },
      telemetry_batch: {
        status: 'idle',
        nextRun: new Date(Date.now() + 90000).toISOString(),
      },
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
app.get('/queues', (req, res) => {
  res.json({
    queues: {
      telemetry_etl: {
        pending: Math.floor(Math.random() * 5),
        active: Math.floor(Math.random() * 2),
        completed: Math.floor(Math.random() * 100),
        failed: 0,
      },
      feedback_processing: {
        pending: Math.floor(Math.random() * 3),
        active: 0,
        completed: Math.floor(Math.random() * 50),
        failed: 0,
      },
      analytics_batch: {
        pending: 0,
        active: 0,
        completed: Math.floor(Math.random() * 200),
        failed: 0,
      },
    },
    timestamp: new Date().toISOString(),
  });
});

// Job history
app.get('/jobs', (req, res) => {
  const status = req.query.status as string | undefined;

  const mockJobs = [
    {
      id: 'job-001',
      type: 'telemetry_etl',
      status: 'completed',
      progress: 100,
      startedAt: new Date(Date.now() - 30000).toISOString(),
      completedAt: new Date(Date.now() - 20000).toISOString(),
      duration: 10000,
      result: { recordsProcessed: 1500, recordsLoaded: 1500 },
    },
    {
      id: 'job-002',
      type: 'feedback_processor',
      status: 'completed',
      progress: 100,
      startedAt: new Date(Date.now() - 60000).toISOString(),
      completedAt: new Date(Date.now() - 50000).toISOString(),
      duration: 10000,
      result: { feedbackTriaged: 3 },
    },
    {
      id: 'job-003',
      type: 'telemetry_etl',
      status: 'completed',
      progress: 100,
      startedAt: new Date(Date.now() - 120000).toISOString(),
      completedAt: new Date(Date.now() - 105000).toISOString(),
      duration: 15000,
      result: { recordsProcessed: 2000, recordsLoaded: 1998 },
    },
  ];

  let jobs = mockJobs;
  if (status) {
    jobs = jobs.filter((j) => j.status === status);
  }

  res.json({
    data: jobs,
    count: jobs.length,
    timestamp: new Date().toISOString(),
  });
});

async function startWorker() {
  await initializeDuckDBMarts(duckdbPath);

  app.listen(port, () => {
    console.log(`\n✅ Background Worker initialized`);
    console.log(`   Port: ${port}`);
    console.log(`   Profile: ${process.env.APP_PROFILE || 'local'}`);
    console.log(`   DuckDB: ${duckdbPath}`);
    console.log(`\n📚 Available endpoints:`);
    console.log(`   GET /health           - Worker health status`);
    console.log(`   GET /queues           - Job queue status`);
    console.log(`   GET /jobs             - Job history`);
    console.log(`   GET /metrics/current  - DuckDB current metrics mart`);
    console.log(`   GET /metrics/history  - DuckDB historical metrics mart\n`);
  });
}

startWorker().catch((error) => {
  console.error('Failed to initialize worker services:', error);
  process.exit(1);
});

process.on('SIGINT', async () => {
  await closeDuckDBMarts();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await closeDuckDBMarts();
  process.exit(0);
});

export default app;
