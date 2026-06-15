import IORedis from 'ioredis';
import { Job, JobsOptions, Queue, QueueEvents, Worker } from 'bullmq';
import { recordEtlRun } from './duckdbMarts.js';

export type QueueName = 'telemetry_etl' | 'feedback_processor' | 'telemetry_batch';

export interface EnqueueJobRequest {
  queue: QueueName;
  payload?: Record<string, unknown>;
}

export interface QueueJobSummary {
  id: string;
  queue: QueueName;
  name: string;
  state: string;
  attemptsMade: number;
  progress: number | object;
  timestamp: string;
  processedOn?: string;
  finishedOn?: string;
  failedReason?: string;
  returnvalue?: unknown;
}

interface QueueStore {
  queue: Queue;
  worker: Worker;
  events: QueueEvents;
}

const queueAliases: Record<QueueName, string> = {
  telemetry_etl: 'zs:telemetry-etl',
  feedback_processor: 'zs:feedback-processor',
  telemetry_batch: 'zs:telemetry-batch',
};

let redisConnection: IORedis | null = null;
let stores: Partial<Record<QueueName, QueueStore>> = {};

export function isQueueName(value: string): value is QueueName {
  return value === 'telemetry_etl' || value === 'feedback_processor' || value === 'telemetry_batch';
}

function defaultJobOptions(): JobsOptions {
  return {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2_000,
    },
    removeOnComplete: {
      age: 3_600,
      count: 200,
    },
    removeOnFail: false,
  };
}

function getStore(queueName: QueueName): QueueStore {
  const store = stores[queueName];
  if (!store) {
    throw new Error(`Queue infrastructure not initialized for ${queueName}`);
  }
  return store;
}

async function processTelemetryJob(job: Job): Promise<Record<string, unknown>> {
  const source = job.data?.source === 'zerospoils' ? 'zerospoils' : 'mock';
  const forceFail = job.data?.forceFail === true;
  const failOnce = job.data?.failOnce === true;

  if (forceFail || (failOnce && job.attemptsMade === 0)) {
    throw new Error('Simulated telemetry ETL failure for retry validation');
  }

  const processedRecords = Number(job.data?.records ?? 1200);
  await recordEtlRun({
    jobId: String(job.id),
    queue: 'telemetry_etl',
    source,
    status: 'success',
    processedRecords,
  });

  return {
    status: 'success',
    source,
    processedRecords,
    loadId: `etl-${job.id}`,
  };
}

async function processFeedbackJob(job: Job): Promise<Record<string, unknown>> {
  const triagedCount = Number(job.data?.triagedCount ?? 3);
  return {
    status: 'success',
    triagedCount,
    queue: 'feedback_processor',
  };
}

async function processBatchJob(job: Job): Promise<Record<string, unknown>> {
  const batchSize = Number(job.data?.batchSize ?? 500);
  return {
    status: 'success',
    batchSize,
    queue: 'telemetry_batch',
  };
}

async function makeQueueStore(queueName: QueueName): Promise<QueueStore> {
  if (!redisConnection) {
    throw new Error('Redis connection not initialized');
  }

  const queue = new Queue(queueAliases[queueName], {
    connection: redisConnection,
    defaultJobOptions: defaultJobOptions(),
  });

  const events = new QueueEvents(queueAliases[queueName], {
    connection: redisConnection,
  });

  events.on('failed', async ({ jobId, failedReason }) => {
    if (queueName === 'telemetry_etl') {
      const job = await queue.getJob(String(jobId));
      const source = job?.data?.source === 'zerospoils' ? 'zerospoils' : 'mock';
      await recordEtlRun({
        jobId: String(jobId),
        queue: 'telemetry_etl',
        source,
        status: 'failure',
        processedRecords: 0,
        error: failedReason,
      });
    }
  });

  const worker = new Worker(
    queueAliases[queueName],
    async (job) => {
      if (queueName === 'telemetry_etl') {
        return processTelemetryJob(job);
      }
      if (queueName === 'feedback_processor') {
        return processFeedbackJob(job);
      }
      return processBatchJob(job);
    },
    {
      connection: redisConnection,
      concurrency: 1,
    }
  );

  return { queue, worker, events };
}

export async function initializeQueueInfrastructure(redisUrl: string): Promise<void> {
  if (redisConnection) {
    return;
  }

  redisConnection = new IORedis(redisUrl, {
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
  });

  redisConnection.on('error', (error) => {
    console.error('[queue] redis error:', error);
  });

  stores.telemetry_etl = await makeQueueStore('telemetry_etl');
  stores.feedback_processor = await makeQueueStore('feedback_processor');
  stores.telemetry_batch = await makeQueueStore('telemetry_batch');

  await enqueueDefaultJobs();
}

export async function enqueueDefaultJobs(): Promise<void> {
  const telemetryStore = getStore('telemetry_etl');
  const feedbackStore = getStore('feedback_processor');
  const batchStore = getStore('telemetry_batch');

  await telemetryStore.queue.add(
    'scheduled-telemetry-etl',
    { source: 'mock', records: 1200 },
    {
      jobId: 'telemetry-etl-recurring',
      repeat: {
        every: 10 * 60 * 1000,
      },
    }
  );

  await feedbackStore.queue.add(
    'scheduled-feedback-triage',
    { triagedCount: 3 },
    {
      jobId: 'feedback-triage-recurring',
      repeat: {
        every: 5 * 60 * 1000,
      },
    }
  );

  await batchStore.queue.add(
    'scheduled-telemetry-batch',
    { batchSize: 500 },
    {
      jobId: 'telemetry-batch-recurring',
      repeat: {
        every: 15 * 60 * 1000,
      },
    }
  );
}

export async function enqueueJob(request: EnqueueJobRequest): Promise<string> {
  const target = getStore(request.queue);
  const job = await target.queue.add(
    `manual-${request.queue}`,
    {
      ...(request.payload ?? {}),
      source: request.payload?.source ?? 'mock',
    },
    {
      jobId: `${request.queue}-${Date.now()}`,
      priority: 10,
    }
  );

  return String(job.id);
}

export async function getQueueSnapshot(): Promise<Record<QueueName, Record<string, number>>> {
  const keys: QueueName[] = ['telemetry_etl', 'feedback_processor', 'telemetry_batch'];
  const snapshot = {} as Record<QueueName, Record<string, number>>;

  for (const key of keys) {
    const store = getStore(key);
    snapshot[key] = await store.queue.getJobCounts(
      'wait',
      'active',
      'completed',
      'failed',
      'delayed',
      'paused'
    );
  }

  return snapshot;
}

function toQueueJobSummary(queueName: QueueName, job: Job, state: string): QueueJobSummary {
  return {
    id: String(job.id),
    queue: queueName,
    name: job.name,
    state,
    attemptsMade: job.attemptsMade,
    progress: job.progress,
    timestamp: new Date(job.timestamp).toISOString(),
    processedOn: job.processedOn ? new Date(job.processedOn).toISOString() : undefined,
    finishedOn: job.finishedOn ? new Date(job.finishedOn).toISOString() : undefined,
    failedReason: job.failedReason,
    returnvalue: job.returnvalue,
  };
}

export async function getJobHistory(options?: {
  queue?: QueueName;
  status?: 'completed' | 'failed' | 'active' | 'wait' | 'delayed' | 'paused';
  limit?: number;
}): Promise<QueueJobSummary[]> {
  const limitParam = options?.limit ?? 20;
  const limit = Number.isFinite(limitParam) ? Math.max(1, Math.min(limitParam, 100)) : 20;
  const statuses = options?.status ? [options.status] : ['completed', 'failed', 'active', 'wait', 'delayed'];
  const queues: QueueName[] = options?.queue
    ? [options.queue]
    : ['telemetry_etl', 'feedback_processor', 'telemetry_batch'];

  const jobs: QueueJobSummary[] = [];

  for (const queueName of queues) {
    const store = getStore(queueName);
    const pulled = await store.queue.getJobs(statuses as any, 0, limit - 1, true);
    for (const job of pulled) {
      const state = await job.getState();
      jobs.push(toQueueJobSummary(queueName, job, state));
    }
  }

  return jobs
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    .slice(0, limit);
}

export async function retryFailedJob(queue: QueueName, jobId: string): Promise<{ retried: boolean; reason?: string }> {
  const store = getStore(queue);
  const job = await store.queue.getJob(jobId);

  if (!job) {
    return { retried: false, reason: 'job not found' };
  }

  const state = await job.getState();
  if (state !== 'failed') {
    return { retried: false, reason: `job is ${state}; only failed jobs are retryable` };
  }

  await job.retry();
  return { retried: true };
}

export async function getQueueHealthStatus(): Promise<'up' | 'down'> {
  try {
    if (!redisConnection) {
      return 'down';
    }
    const pong = await redisConnection.ping();
    return pong === 'PONG' ? 'up' : 'down';
  } catch {
    return 'down';
  }
}

export async function closeQueueInfrastructure(): Promise<void> {
  const keys: QueueName[] = ['telemetry_etl', 'feedback_processor', 'telemetry_batch'];

  for (const key of keys) {
    const store = stores[key];
    if (!store) {
      continue;
    }

    await store.worker.close();
    await store.events.close();
    await store.queue.close();
  }

  stores = {};

  if (redisConnection) {
    redisConnection.disconnect();
    redisConnection = null;
  }
}
