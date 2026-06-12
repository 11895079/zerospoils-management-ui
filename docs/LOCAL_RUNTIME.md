# Management Backend UI — Local Runtime Setup

**Issue:** 680  
**Status:** ✅ Initial scaffold  
**Last Updated:** June 9, 2026

## Overview

The local runtime foundation allows operators to run the complete management backend UI stack on their development machine with a single command. All services are containerized and orchestrated via Docker Compose.

## Services

| Service | Port | Purpose | Tech Stack |
|---------|------|---------|-----------|
| **Frontend** | 3000 | Management dashboard UI | React + Ant Design + Vite |
| **API** | 3001 | REST API for operations | Express.js + TypeScript |
| **Worker** | 3002 | Background job processor | Node.js + BullMQ |
| **Redis** | 6379 | Job queue & cache | Redis 7 |

## Prerequisites

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Node.js** 18+ (optional, if running services locally without containers)

## Quick Start

### 1. Start the Stack

From the `management-backend/` directory:

```bash
docker-compose up -d
```

This will:
- Start Redis
- Start the API server (waits for Redis health check)
- Start the worker (waits for Redis health check)
- Start the frontend dev server

### 2. Verify Services Are Running

```bash
# Check container status
docker-compose ps

# Check API health
curl http://localhost:3001/health

# Check Worker health
curl http://localhost:3002/health

# Check status endpoint (includes config dump)
curl http://localhost:3001/status
```

### 3. Open the Dashboard

Navigate to **http://localhost:3000** in your browser.

### 4. Log In

Use one of the test accounts:
- **Admin**: `admin@zerospoils.local` (token: `token_admin_abc123`)
- **Analyst**: `analyst@zerospoils.local` (token: `token_analyst_xyz789`)
- **Support**: `support@zerospoils.local` (token: `token_support_def456`)

## Configuration

### Environment Variables

Each service reads from `.env.local` (checked into git for local dev):

**API** (`api/.env.local`)
```
API_PORT=3001
CORS_ORIGIN=http://localhost:3000
APP_PROFILE=local
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-key-do-not-use-in-production
```

**Worker** (`worker/.env.local`)
```
WORKER_PORT=3002
APP_PROFILE=local
REDIS_URL=redis://localhost:6379
```

**Docker Compose** (`docker-compose.yml`)
```yaml
# Services inherit APP_PROFILE, NODE_ENV, etc.
# Overrides in docker-compose.yml take precedence
```

### Profiles

Three deployment profiles are supported:

| Profile | Use Case | Config |
|---------|----------|--------|
| **local** | Development on single machine | .env.local, Redis in-process |
| **staging** | Pre-production testing | .env.staging, cloud Redis |
| **cloud** | Production deployment | .env.cloud, full cloud stack |

To use a different profile:

```bash
# Edit docker-compose.yml
APP_PROFILE: staging

# Then restart
docker-compose down
docker-compose up -d
```

## API Endpoints

### Health & Status (No Auth)

```bash
# Health check (used for container readiness probes)
GET /health
→ { status: 'healthy', services: {...}, uptime: 1234 }

# Status & configuration (debug info)
GET /status
→ { service, version, profile, config: {...} }
```

### Metrics (Requires Auth)

```bash
# Current metrics
GET /api/metrics/current
Authorization: Bearer token_admin_abc123
→ { newInstalls, activeUsers, crashFreeRate, ... }

# Historical metrics (24h by default)
GET /api/metrics/history?hours=24
→ [{ timestamp, newInstalls, ... }, ...]

# Metrics summary
GET /api/metrics/summary
→ { current, trends: { installs24h, retention7d, ... } }

Note: Metrics endpoints expose `source` (`duckdb` or `mock-fallback`) and
`fallbackReason` when DuckDB marts are unavailable from the worker.
```

### Feedback (Requires Auth)

```bash
# Get feedback items
GET /api/feedback
GET /api/feedback?status=untriaged&severity=high
→ { data: [...], count, untriaged, timestamp }

# Triage feedback
POST /api/feedback/:id/triage
Body: { note: "Assigned to team X" }
→ { message, data, correlationId }

# Feedback stats
GET /api/feedback/stats/summary
→ { total, byStatus: {...}, bySeverity: {...}, ... }
```

### Telemetry (Requires Auth)

```bash
# Telemetry events
GET /api/telemetry/events
GET /api/telemetry/events?platform=ios&limit=50
→ { data: [...], count, total }

# Telemetry summary
GET /api/telemetry/summary
→ { byEventName, byPlatform, validation, ingestion, ... }

# Platform split
GET /api/telemetry/platforms
→ { data: [{ platform, count, percentage }, ...] }
```

### Worker Queue Operations (No Auth in local profile)

```bash
# Queue depth/status by queue name
GET /queues
→ { queues: { telemetry_etl, feedback_processor, telemetry_batch }, timestamp }

# Job history with filters
GET /jobs?queue=telemetry_etl&status=failed&limit=20
→ { data: [...], count, etlAudit: [...], timestamp }

# Enqueue manual processing job
POST /jobs/enqueue
Body: { "queue": "telemetry_etl", "payload": { "source": "mock", "records": 500 } }
→ { queue, jobId, status: "queued" }

# Retry failed job by queue and job id
POST /jobs/:queue/:jobId/retry
→ { queue, jobId, retried: true }
```

## Correlation IDs

All requests and responses include a `X-Correlation-ID` header for request tracing:

```bash
curl -i http://localhost:3001/health
# → X-Correlation-ID: 550e8400-e29b-41d4-a716-446655440000
```

The correlation ID is:
1. **Generated** if not provided (UUID format)
2. **Propagated** through API → Worker → logs
3. **Returned** in response headers and JSON bodies

Use this to trace a request across all services in logs.

## Role-Based Access Control

Three roles are supported:

| Role | Permissions |
|------|-------------|
| **admin** | Full access to all endpoints, create feedback, system config |
| **analyst** | Read metrics, telemetry, feedback; can triage feedback |
| **support** | Read feedback; can triage feedback |

The role is determined by the bearer token (configured in `api/src/mocks/data.ts`).

## Database (DuckDB)

Local analytics store (created in M5/690):

- **Path**: `./data/analytics.duckdb` (persisted volume in Docker)
- **Status**: Placeholder (not yet implemented)
- **Used by**: Worker for ETL, API for insights queries

Future: Will load telemetry → DuckDB via worker ETL job.

## Logs & Debugging

### View Logs

```bash
# All services
docker-compose logs -f

# Single service
docker-compose logs -f api
docker-compose logs -f worker
docker-compose logs -f frontend

# Last 50 lines
docker-compose logs --tail=50 api
```

### View Redis Commands (Development)

```bash
docker-compose exec redis redis-cli

# Inside redis-cli:
MONITOR          # Watch all commands in real-time
KEYS *           # List all keys
GET key_name     # View key value
FLUSHDB          # Clear (careful!)
```

### Request Tracing

All API requests include correlation IDs in logs:

```
[550e8400-e29b-41d4-a716-446655440000] GET /api/metrics/current - 200 (45ms) - admin@zerospoils.local
```

Use the correlation ID to grep logs across containers:

```bash
docker-compose logs | grep "550e8400-e29b-41d4-a716-446655440000"
```

## Common Tasks

### Restart a Single Service

```bash
# Restart API without stopping others
docker-compose restart api

# Stop and rebuild API (if Dockerfile changed)
docker-compose up -d --build api
```

### Stop the Stack

```bash
# Stop containers (preserve data)
docker-compose stop

# Remove containers (data persists in volumes)
docker-compose down

# Remove everything including data
docker-compose down -v
```

### Run Services Locally (Without Docker)

If Docker isn't available:

```bash
# Terminal 1: Redis
redis-server

# Terminal 2: API
cd api
npm install
npm run dev

# Terminal 3: Worker
cd worker
npm install
npm run dev

# Terminal 4: Frontend
cd frontend
npm install
npm run dev
```

Then access http://localhost:3000.

### Test Auth Flow

```bash
# Login as analyst
curl -H "Authorization: Bearer token_analyst_xyz789" \
  http://localhost:3001/api/metrics/current

# Invalid token → 401
curl -H "Authorization: Bearer invalid_token" \
  http://localhost:3001/api/metrics/current

# No auth → 401
curl http://localhost:3001/api/metrics/current

# No auth but health is public → 200
curl http://localhost:3001/health
```

## Troubleshooting

### Ports Already in Use

```bash
# Find process using port 3001
lsof -i :3001

# Kill it (macOS/Linux)
kill -9 <PID>

# Or use a different port
docker-compose -e API_PORT=3003 up -d api
```

### Redis Connection Failed

```bash
# Check Redis is running
docker-compose ps redis

# Restart Redis
docker-compose restart redis

# Check connectivity
docker-compose exec api redis-cli -h redis ping
```

### Frontend Can't Reach API

```bash
# Check CORS_ORIGIN in docker-compose.yml
# Should be: http://localhost:3000

# Check frontend proxy config (vite.config.ts)
# Should target: http://localhost:3001

# Check API is running
curl http://localhost:3001/health
```

### Stale Node Modules

```bash
# Clean and reinstall
docker-compose down -v
docker-compose up -d --build
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                              │
│                  http://localhost:3000                       │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │   Frontend (React)      │
        │   - Ant Design UI       │
        │   - Vite dev server     │
        │   - Port: 3000          │
        └────────────┬────────────┘
                     │
         ┌───────────▼───────────┐
         │  API Gateway/CORS     │
         │  (vite proxy)         │
         └───────────┬───────────┘
                     │
        ┌────────────▼────────────┐
        │   API (Express.js)      │
        │   - Mock data           │
        │   - RBAC middleware     │
        │   - Port: 3001          │
        └────────┬────────────────┘
                 │
        ┌────────▼────────┐
        │  Redis          │
        │  - Job queue    │
        │  - Cache        │
        │  - Port: 6379   │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Worker         │
        │  - Job processor│
        │  - Port: 3002   │
        └─────────────────┘
```

## Next Steps

After issue 680 is verified:

1. **Issue 690** — Telemetry ETL + DuckDB
   - Implement actual data loading from Firebase
   - Create DuckDB analytics schema
   - Wire worker jobs for scheduled ETL

2. **Issue 700** — Feature flags control plane
   - Add feature flag UI
   - Remote config sync endpoints

3. **Issue 710** — Audit & policy engine
   - Admin action logging
   - RBAC policy management

## References

- API Tech Stack: `../planning/docs/backend-architecture.md`
- Issue 680 Spec: `../planning/issues/680-management-ui-local-runtime-bootstrap.md`
- Docker Compose Docs: https://docs.docker.com/compose/
- Express.js Docs: https://expressjs.com/
- React + Vite: https://vitejs.dev/
