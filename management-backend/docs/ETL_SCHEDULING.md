# ETL Job Scheduling (Phase 3)

## Overview

Phase 3 implements persistent, reliable ETL job scheduling using BullMQ. The scheduler ensures the telemetry ETL pipeline runs automatically every 10 minutes, survives worker restarts, and provides complete operational visibility.

**Key Features:**
- ✅ Persistent recurring jobs (survive restarts)
- ✅ 10-minute scheduling interval (configurable)
- ✅ BullMQ with Redis backing
- ✅ Job lifecycle tracking (success/failure/progress)
- ✅ Manual trigger capability
- ✅ Pause/resume scheduler control
- ✅ Comprehensive monitoring endpoints
- ✅ Exponential backoff on failure (3 retry attempts)

## Architecture

```
Worker Process
├─ ETLScheduler
│  ├─ BullMQ Queue (Redis-backed, persistent)
│  │  └─ Recurring Job: etl-pipeline-recurring
│  │     └─ Runs every 10 minutes
│  │        └─ Data: { source: 'mock|zerospoils', force_refresh: boolean }
│  │
│  ├─ BullMQ Worker
│  │  └─ Processes 1 job at a time (concurrency: 1)
│  │     └─ Calls processETLJob()
│  │        └─ Returns: { status, raw_events, processed_events, ... }
│  │
│  ├─ QueueEvents (listener)
│  │  ├─ completed → update job history
│  │  ├─ failed → update job history with error
│  │  └─ progress → log progress updates
│  │
│  └─ Job History (in-memory, limit: 1000 entries)
│     └─ Tracks all job executions for monitoring

Redis (Persistent Storage)
├─ bull:etl-pipeline:* (queue data)
├─ bull:etl-pipeline:repeat:* (recurring job metadata)
└─ Job state & progress tracking
```

## Scheduling Implementation

### Recurring Job Configuration

```typescript
// BullMQ repeat options
{
  repeat: {
    every: 10 * 60 * 1000,  // 10 minutes in milliseconds
  }
}
```

**How it works:**
1. Job added to queue with `repeat` option
2. BullMQ creates repeating pattern in Redis
3. Worker processes job when scheduled time arrives
4. Job completes → BullMQ automatically schedules next occurrence
5. Pattern survives Redis/worker restarts

### Retry Strategy

Failed jobs are retried with exponential backoff:

```typescript
defaultJobOptions: {
  attempts: 3,              // Retry up to 3 times
  backoff: {
    type: 'exponential',    // Exponential backoff
    delay: 2000,            // 2s, 4s, 8s delays
  }
}
```

**Failure Scenarios:**
- **Network error (temporary)** → Retried (usually succeeds)
- **DuckDB schema error** → Failed (requires fix, manual retry)
- **Out of memory** → Retried (temporary condition)

### Job Persistence

Job state is stored in Redis and survives:
- ✅ Worker process restart
- ✅ Redis container restart (if data volume persists)
- ✅ Network interruption (jobs resume on reconnect)

**Limitations:**
- ❌ Not preserved if Redis data is lost
- ❌ Requires Redis for operation

## API Endpoints

### Health Check

```bash
GET /health
```

Returns overall worker health including scheduler status.

**Response:**
```json
{
  "service": "zerospoils-mgmt-worker",
  "status": "healthy",
  "uptime": 3600,
  "services": {
    "duckdb": { "status": "healthy" },
    "redis": { "status": "healthy" },
    "etl": {
      "status": "running",
      "intervalMinutes": 10,
      "nextRun": "2026-06-10T12:10:00Z"
    }
  }
}
```

### Scheduler Status

```bash
GET /scheduler/status
```

Detailed scheduler state including job counts and next run time.

**Response:**
```json
{
  "isInitialized": true,
  "isRunning": true,
  "intervalMinutes": 10,
  "nextScheduledRun": "2026-06-10T12:10:00Z",
  "jobCounts": {
    "active": 0,
    "completed": 150,
    "failed": 2,
    "pending": 0
  },
  "recentJobs": [
    {
      "id": "etl-pipeline-recurring",
      "status": "completed",
      "progress": 100,
      "data": { "source": "mock", "force_refresh": false },
      "timestamp": "2026-06-10T12:00:15Z"
    }
  ]
}
```

### Queue Status

```bash
GET /queues
```

High-level queue statistics.

**Response:**
```json
{
  "queues": {
    "etl_pipeline": {
      "active": 0,
      "completed": 150,
      "failed": 2,
      "pending": 0
    }
  },
  "nextScheduledRun": "2026-06-10T12:10:00Z"
}
```

### Job History

```bash
GET /jobs?limit=20
```

Recent job executions.

**Response:**
```json
{
  "data": [
    {
      "id": "etl-manual-1718000000000",
      "status": "completed",
      "progress": 100,
      "data": { "source": "mock", "force_refresh": true },
      "result": {
        "status": "success",
        "raw_events": 50000,
        "processed_events": 49500,
        "validation_failures": 500,
        "load_id": "load_1718000000000_abc123"
      },
      "timestamp": "2026-06-10T11:55:00Z"
    }
  ],
  "count": 20
}
```

### Manual Trigger

```bash
POST /etl/run
Content-Type: application/json

{
  "source": "mock",
  "force_refresh": true
}
```

Manually trigger an ETL run (doesn't affect recurring schedule).

**Response:**
```json
{
  "job_id": "etl-manual-1718000000000",
  "status": "queued",
  "message": "ETL job queued for processing"
}
```

### Pause Scheduler

```bash
POST /scheduler/pause
```

Stop new jobs from being scheduled (running jobs complete).

**Response:**
```json
{
  "status": "paused",
  "message": "ETL scheduler paused"
}
```

### Resume Scheduler

```bash
POST /scheduler/resume
```

Resume automatic job scheduling.

**Response:**
```json
{
  "status": "running",
  "message": "ETL scheduler resumed"
}
```

### Clear Queue

```bash
POST /scheduler/clear
Authorization: Bearer admin-secret-token
```

Clear all jobs from queue (admin only, requires token).

## Configuration

### Environment Variables

```bash
# ETL scheduling interval (minutes, default: 10)
ETL_INTERVAL_MINUTES=10

# Telemetry data source (mock or zerospoils, default: mock)
TELEMETRY_SOURCE=mock

# Redis connection
REDIS_URL=redis://redis:6379

# DuckDB database path
DUCKDB_PATH=./data/zerospoils_analytics.db

# Worker service port
WORKER_PORT=3002
```

### Docker Compose Example

```yaml
services:
  worker:
    environment:
      - ETL_INTERVAL_MINUTES=10
      - TELEMETRY_SOURCE=mock
      - REDIS_URL=redis://redis:6379
      - DUCKDB_PATH=/data/zerospoils_analytics.db
      - WORKER_PORT=3002
    depends_on:
      - redis
    volumes:
      - analytics_data:/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  analytics_data:
  redis_data:
```

## Monitoring

### Check Scheduler Health

```bash
curl http://localhost:3002/health | jq '.services.etl'

# Output
{
  "status": "running",
  "intervalMinutes": 10,
  "nextRun": "2026-06-10T12:10:00Z"
}
```

### Watch Job Execution

```bash
# Get detailed status
curl http://localhost:3002/scheduler/status | jq '.recentJobs[0]'

# Get just completed count
curl http://localhost:3002/queues | jq '.queues.etl_pipeline.completed'
```

### Monitor Redis Queue

```bash
redis-cli

# List all queues
> KEYS 'bull:*'

# Get queue status
> HGETALL bull:etl-pipeline:counts

# Get recent jobs
> LRANGE bull:etl-pipeline:completed 0 -1
```

### Check DuckDB Metrics

```bash
duckdb ./data/zerospoils_analytics.db

-- Check latest ETL metadata
SELECT load_id, load_timestamp, raw_event_count, processing_duration_ms
FROM fact_etl_metadata
ORDER BY load_timestamp DESC
LIMIT 5;

-- Check how often data refreshes
SELECT
  COUNT(*) as etl_runs,
  MIN(load_timestamp) as first_run,
  MAX(load_timestamp) as last_run,
  (MAX(load_timestamp) - MIN(load_timestamp)) as total_duration
FROM fact_etl_metadata
WHERE load_timestamp > NOW() - INTERVAL 1 HOUR;
```

## Operations

### Normal Startup

```
[Services] Initializing DuckDB...
[Services] DuckDB initialized successfully
[Services] Initializing ETL scheduler...
[ETL Scheduler] Initializing with 10min interval
[ETL Scheduler] Created recurring job: etl-pipeline-recurring
[ETL Scheduler] Job will run every 10 minutes
[ETL Scheduler] Initialized successfully
[Services] All services initialized successfully

🔄 Background Worker running on http://localhost:3002
⏱️  ETL Interval: 10 minutes
```

### First Run (5 seconds after startup)

```
[ETL Scheduler] Job etl-pipeline-recurring started
[ETL Job] Starting ETL pipeline (source: mock)
[ETL Job] Phase 1: Extracting events
[ETL Job] Extracted 50000 raw events
[ETL Job] Phase 2: Normalizing events
...
[ETL Job] ETL pipeline completed in 12534ms
[ETL Job] Load ID: load_1718000000000_abc123
[ETL Scheduler] Job etl-pipeline-recurring completed
```

### Subsequent Runs (every 10 minutes)

```
[ETL Scheduler] Job etl-pipeline-recurring started
[ETL Job] Starting ETL pipeline (source: mock)
...
[ETL Scheduler] Job etl-pipeline-recurring completed
```

### Manual Trigger

```bash
curl -X POST http://localhost:3002/etl/run -d '{"source":"mock"}' -H "Content-Type: application/json"

# Response
{"job_id":"etl-manual-1718000000000","status":"queued"}

# Worker logs
[ETL Scheduler] Triggered manual ETL: etl-manual-1718000000000
[ETL Scheduler] Job etl-manual-1718000000000 started
[ETL Job] Starting ETL pipeline (source: mock)
...
[ETL Scheduler] Job etl-manual-1718000000000 completed
```

### Pause/Resume

```bash
# Pause
curl -X POST http://localhost:3002/scheduler/pause
# {"status":"paused","message":"ETL scheduler paused"}

# Resume
curl -X POST http://localhost:3002/scheduler/resume
# {"status":"running","message":"ETL scheduler resumed"}
```

## Troubleshooting

### Jobs Not Running

**Check scheduler status:**
```bash
curl http://localhost:3002/scheduler/status | jq '.isRunning'
# Should be true
```

**Check Redis connection:**
```bash
redis-cli PING
# Should return PONG
```

**Check recent jobs for errors:**
```bash
curl http://localhost:3002/jobs | jq '.data[] | select(.status=="failed")'
```

### Scheduler Restarting

**Symptom:** Jobs marked as "pending" indefinitely

**Solution:** Check if worker crashed:
```bash
# Worker logs for errors
docker logs zerospoils-mgmt-worker

# If crashed, restart
docker-compose restart worker
```

### High Redis Memory

**Symptom:** Redis taking too much memory

**Check queue size:**
```bash
redis-cli

# Size of queue data
> DBSIZE

# Get queue keys
> KEYS 'bull:etl-pipeline:*' | wc -l

# Clear old completed jobs
> redis-cli EVAL "return redis.call('del', unpack(redis.call('keys', ARGV[1])))" 0 'bull:etl-pipeline:completed:*'
```

**Configuration:**
```typescript
removeOnComplete: {
  age: 3600,  // Keep completed jobs for 1 hour
  ...
}

removeOnFail: false,  // Keep failed jobs for debugging
```

## Performance

### Typical ETL Job Duration

| Phase | Duration | Notes |
|-------|----------|-------|
| Extract | ~1s | Fetch events |
| Normalize | ~0.5s | Transform |
| Validate | ~2s | Schema check |
| Redact | ~1s | SHA256 hashing |
| Deduplicate | ~1s | Hash map |
| Load | ~5s | DuckDB insert |
| Mart Refresh | ~8s | Aggregations |
| **Total** | **~18s** | Well within 10-min interval |

### Job Queue Headroom

With 10-minute interval and ~18-second execution:
- Queue depth: ~0 (one job per interval)
- Backpressure: None expected
- Retry success rate: 95%+ (exponential backoff)

## Testing

### Manual Trigger

```bash
# Trigger and watch
curl -X POST http://localhost:3002/etl/run -d '{}' -H "Content-Type: application/json"

# Monitor progress
watch -n 1 'curl -s http://localhost:3002/scheduler/status | jq ".recentJobs[0] | {id, status, progress}"'
```

### Load Testing

```bash
# Trigger 5 sequential jobs
for i in {1..5}; do
  curl -X POST http://localhost:3002/etl/run -d '{}' -H "Content-Type: application/json"
  sleep 2
done

# Check queue
curl http://localhost:3002/queues | jq '.queues.etl_pipeline'
```

### Failure Injection

```bash
# Stop Redis (simulate network error)
docker-compose stop redis

# Job will be retried on reconnect
sleep 5
docker-compose start redis

# Check job recovered
curl http://localhost:3002/jobs | jq '.data[0] | {id, status}'
```

## Integration with Dashboard

The dashboard auto-refreshes metrics every 30 seconds from:
- `/api/metrics/current` (from API → worker → DuckDB)
- Fresh data available 10-30 seconds after ETL completes

**Pipeline latency:**
- ETL completes at T+18s
- DuckDB marts updated at T+18s
- API query latency: ~100-150ms
- Dashboard update: T+18s to T+20s

## Next Steps

1. **Real Telemetry Integration:** Replace mock extract with ZeroSpoils API
2. **Dashboard Analytics:** Build UI components for telemetry views
3. **Alerting:** Implement thresholds for monitoring metrics
4. **Performance Optimization:** Add Redis caching for fast queries
5. **Multi-tenant:** Support scheduling per tenant/app
