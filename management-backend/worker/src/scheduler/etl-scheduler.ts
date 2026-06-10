/**
 * ETL Job Scheduler
 *
 * Manages recurring ETL pipeline execution using BullMQ.
 * Ensures ETL runs every 10 minutes, survives worker restarts,
 * and provides monitoring endpoints for job execution history.
 */

import { Queue, Worker, QueueEvents, SchedulerOptions } from 'bullmq';
import IORedis from 'ioredis';
import { processETLJob, ETLJobData } from '../jobs/etlJob';

export interface SchedulerConfig {
  redis: IORedis;
  queueName: string;
  intervalMinutes: number;
}

export interface JobSchedule {
  jobId: string;
  nextRun: Date;
  lastRun?: Date;
  lastStatus?: 'success' | 'failure';
  lastError?: string;
}

class ETLScheduler {
  private queue: Queue<ETLJobData> | null = null;
  private worker: Worker<ETLJobData> | null = null;
  private queueEvents: QueueEvents | null = null;
  private redis: IORedis;
  private queueName: string;
  private intervalMinutes: number;
  private isInitialized = false;
  private jobHistory: Map<string, JobSchedule> = new Map();

  constructor(config: SchedulerConfig) {
    this.redis = config.redis;
    this.queueName = config.queueName;
    this.intervalMinutes = config.intervalMinutes;
  }

  /**
   * Initialize the scheduler with queue, worker, and recurring job
   */
  async initialize(db: any): Promise<void> {
    if (this.isInitialized) {
      console.warn('[ETL Scheduler] Already initialized');
      return;
    }

    try {
      console.log(`[ETL Scheduler] Initializing with ${this.intervalMinutes}min interval`);

      // Create queue
      this.queue = new Queue<ETLJobData>(this.queueName, {
        connection: this.redis,
        defaultJobOptions: {
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 2000,
          },
          removeOnComplete: {
            age: 3600, // Keep completed jobs for 1 hour
          },
          removeOnFail: false, // Keep failed jobs for debugging
        },
      });

      // Set up queue events
      this.queueEvents = new QueueEvents(this.queueName, {
        connection: this.redis,
      });

      this.queueEvents.on('completed', ({ jobId, returnvalue }) => {
        console.log(`[ETL Scheduler] Job ${jobId} completed`);
        this.updateJobHistory(jobId, 'success', returnvalue);
      });

      this.queueEvents.on('failed', ({ jobId, failedReason }) => {
        console.error(`[ETL Scheduler] Job ${jobId} failed: ${failedReason}`);
        this.updateJobHistory(jobId, 'failure', undefined, failedReason);
      });

      this.queueEvents.on('progress', ({ jobId, progress }) => {
        console.log(`[ETL Scheduler] Job ${jobId} progress: ${progress}%`);
      });

      // Register worker
      this.worker = new Worker<ETLJobData>(
        this.queueName,
        async (job) => {
          try {
            if (!db) {
              throw new Error('DuckDB not initialized');
            }
            return await processETLJob(job, db);
          } catch (error) {
            console.error(`[ETL Scheduler] Error processing job ${job.id}:`, error);
            throw error;
          }
        },
        {
          connection: this.redis,
          concurrency: 1, // Only one ETL job at a time
        }
      );

      // Add or update the recurring job
      await this.scheduleRecurringJob();

      this.isInitialized = true;
      console.log('[ETL Scheduler] Initialized successfully');
    } catch (error) {
      console.error('[ETL Scheduler] Initialization failed:', error);
      throw error;
    }
  }

  /**
   * Schedule the recurring ETL job
   *
   * Uses BullMQ's repeat option to create a persistent recurring job.
   * The job will run every N minutes and survive worker restarts.
   */
  async scheduleRecurringJob(): Promise<void> {
    if (!this.queue) {
      throw new Error('Queue not initialized');
    }

    try {
      // Check if recurring job already exists
      const existingJobs = await this.queue.getRepeatableJobs();
      const existingRecurring = existingJobs.find(
        (job) =>
          job.key.includes(`repeat:${this.intervalMinutes * 60 * 1000}`) &&
          job.key.includes('etl-pipeline-recurring')
      );

      if (existingRecurring) {
        console.log('[ETL Scheduler] Recurring job already exists, skipping');
        return;
      }

      // Create recurring job
      // First, add it with a slight delay to give the system time to start
      const nextRunTime = new Date(Date.now() + 5000); // Run in 5 seconds

      const job = await this.queue.add(
        'run',
        {
          source: process.env.TELEMETRY_SOURCE === 'zerospoils' ? 'zerospoils' : 'mock',
          force_refresh: false,
        },
        {
          jobId: 'etl-pipeline-recurring',
          repeat: {
            every: this.intervalMinutes * 60 * 1000, // Convert minutes to milliseconds
          },
          priority: 1, // Normal priority
        }
      );

      console.log(`[ETL Scheduler] Created recurring job: ${job.id}`);
      console.log(`[ETL Scheduler] Job will run every ${this.intervalMinutes} minutes`);

      // Initialize job history entry
      this.jobHistory.set(job.id, {
        jobId: job.id,
        nextRun: nextRunTime,
      });
    } catch (error) {
      console.error('[ETL Scheduler] Failed to schedule recurring job:', error);
      throw error;
    }
  }

  /**
   * Manually trigger ETL job (doesn't affect recurring schedule)
   */
  async triggerManual(source: 'mock' | 'zerospoils' = 'mock'): Promise<string> {
    if (!this.queue) {
      throw new Error('Queue not initialized');
    }

    const job = await this.queue.add(
      'run',
      {
        source,
        force_refresh: true,
      },
      {
        jobId: `etl-manual-${Date.now()}`,
        priority: 10, // Higher priority for manual runs
      }
    );

    console.log(`[ETL Scheduler] Triggered manual ETL: ${job.id}`);
    return job.id;
  }

  /**
   * Get scheduler status
   */
  async getStatus(): Promise<{
    isInitialized: boolean;
    isRunning: boolean;
    intervalMinutes: number;
    nextScheduledRun: Date | null;
    jobCounts: any;
    recentJobs: any[];
  }> {
    if (!this.queue) {
      return {
        isInitialized: false,
        isRunning: false,
        intervalMinutes: this.intervalMinutes,
        nextScheduledRun: null,
        jobCounts: {},
        recentJobs: [],
      };
    }

    const counts = await this.queue.getCountsPerStatus();
    const jobs = await this.queue.getJobs(['completed', 'failed', 'active'], 0, 20);

    // Find next scheduled run
    let nextRun: Date | null = null;
    const repeatableJobs = await this.queue.getRepeatableJobs();
    if (repeatableJobs.length > 0) {
      const nextExecution = repeatableJobs[0].next;
      if (nextExecution) {
        nextRun = new Date(nextExecution);
      }
    }

    return {
      isInitialized: this.isInitialized,
      isRunning: this.worker !== null,
      intervalMinutes: this.intervalMinutes,
      nextScheduledRun: nextRun,
      jobCounts: counts,
      recentJobs: jobs.map((j) => ({
        id: j.id,
        status: j._status,
        progress: j.progress(),
        data: j.data,
        failedReason: j.failedReason,
        timestamp: new Date(j.timestamp).toISOString(),
      })),
    };
  }

  /**
   * Get job execution history
   */
  getJobHistory(limit: number = 50): JobSchedule[] {
    const history = Array.from(this.jobHistory.values());
    return history.slice(-limit).reverse();
  }

  /**
   * Update job history entry
   */
  private updateJobHistory(
    jobId: string,
    status: 'success' | 'failure',
    result?: any,
    error?: string
  ): void {
    const existing = this.jobHistory.get(jobId) || {
      jobId,
      nextRun: new Date(),
    };

    this.jobHistory.set(jobId, {
      ...existing,
      lastRun: new Date(),
      lastStatus: status,
      lastError: error,
    });

    // Limit history size to 1000 entries
    if (this.jobHistory.size > 1000) {
      const entries = Array.from(this.jobHistory.entries());
      const toDelete = entries.slice(0, 100);
      for (const [key] of toDelete) {
        this.jobHistory.delete(key);
      }
    }
  }

  /**
   * Close scheduler and cleanup resources
   */
  async close(): Promise<void> {
    try {
      if (this.worker) {
        await this.worker.close();
      }

      if (this.queueEvents) {
        await this.queueEvents.close();
      }

      if (this.queue) {
        await this.queue.close();
      }

      this.isInitialized = false;
      console.log('[ETL Scheduler] Closed');
    } catch (error) {
      console.error('[ETL Scheduler] Error closing:', error);
    }
  }

  /**
   * Pause scheduler (prevents new jobs from running)
   */
  async pause(): Promise<void> {
    if (!this.queue) {
      throw new Error('Queue not initialized');
    }

    await this.queue.pause();
    console.log('[ETL Scheduler] Paused');
  }

  /**
   * Resume scheduler
   */
  async resume(): Promise<void> {
    if (!this.queue) {
      throw new Error('Queue not initialized');
    }

    await this.queue.resume();
    console.log('[ETL Scheduler] Resumed');
  }

  /**
   * Clear all jobs from queue (useful for testing)
   */
  async clearQueue(): Promise<void> {
    if (!this.queue) {
      throw new Error('Queue not initialized');
    }

    const counts = await this.queue.getCountsPerStatus();
    console.log(`[ETL Scheduler] Clearing ${counts.failed + counts.completed + counts.active} jobs`);

    await this.queue.clean(0, 'completed');
    await this.queue.clean(0, 'failed');

    this.jobHistory.clear();
    console.log('[ETL Scheduler] Queue cleared');
  }
}

export default ETLScheduler;
