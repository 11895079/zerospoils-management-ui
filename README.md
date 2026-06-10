# ZeroSpoils Management Backend UI

**Issue 680**: Local runtime bootstrap for management operations dashboard.

Complete local-first management control plane for ZeroSpoils operators, with web frontend, REST API, background worker, and local analytics store.

## 🚀 Quick Start

```bash
# From management-backend/ directory
docker-compose up -d

# Open dashboard
open http://localhost:3000

# Log in with:
# Email: admin@zerospoils.local
# Token: token_admin_abc123
```

## 📁 Project Structure

```
management-backend/
├── frontend/              # React + Ant Design dashboard (port 3000)
│   ├── src/
│   │   ├── pages/        # Dashboard, Login, Feedback, Telemetry
│   │   ├── components/   # MetricCard, charts, tables
│   │   ├── layouts/      # MainLayout with sidebar
│   │   ├── hooks/        # useMetrics, API calls
│   │   └── utils/        # API client
│   ├── vite.config.ts
│   └── package.json
│
├── api/                   # Express.js REST API (port 3001)
│   ├── src/
│   │   ├── routes/       # /metrics, /feedback, /telemetry, /health
│   │   ├── middleware/   # Auth (RBAC), request logging, correlation IDs
│   │   ├── mocks/        # Mock data generators
│   │   └── types/        # TypeScript interfaces
│   └── package.json
│
├── worker/                # Background job processor (port 3002)
│   ├── src/
│   │   └── worker.ts     # Job queue & scheduled tasks
│   └── package.json
│
├── docs/
│   └── LOCAL_RUNTIME.md  # Detailed setup & API documentation
│
├── docker-compose.yml    # Full stack orchestration
└── README.md            # This file
```

## 🔐 Authentication

Three test accounts (with different roles):

```
Admin:    admin@zerospoils.local   (token: token_admin_abc123)
Analyst:  analyst@zerospoils.local (token: token_analyst_xyz789)
Support:  support@zerospoils.local (token: token_support_def456)
```

Roles:
- **Admin** — Full system access, create feedback, config
- **Analyst** — Read metrics, telemetry; can triage feedback
- **Support** — Read feedback, triage only

## 📊 Features (Implemented in Issue 680)

### Frontend Dashboard
- ✅ Login page with test accounts
- ✅ Sidebar navigation (Dashboard, Feedback, Telemetry, Settings)
- ✅ Metric cards with KPIs (installs, users, crash-free rate, retention)
- ✅ Charts (installs, retention, crash rate, active users)
- ✅ System health status (services up/down, response times)
- ✅ Professional Ant Design theme

### API
- ✅ REST endpoints for metrics, feedback, telemetry
- ✅ Mock data generation
- ✅ Role-based access control (RBAC)
- ✅ Correlation IDs for request tracing
- ✅ Health check endpoints
- ✅ Environment-based configuration

### Worker
- ✅ Health status endpoint
- ✅ Job queue status
- ✅ Job history logging
- ✅ Ready for BullMQ integration (issue 690)

### Infrastructure
- ✅ Docker Compose for local runtime
- ✅ Service orchestration with health checks
- ✅ Redis for job queue
- ✅ Hot reload for development

## 🔌 API Endpoints

### Public (No Auth)
```
GET /health             — Service health check
GET /status             — Status & configuration
```

### Metrics
```
GET /api/metrics/current   — Current metrics snapshot
GET /api/metrics/history   — Historical data (24h)
GET /api/metrics/summary   — Aggregated trends
```

### Feedback
```
GET /api/feedback                  — List feedback items
GET /api/feedback/:id              — Get single feedback
POST /api/feedback/:id/triage      — Triage a ticket
GET /api/feedback/stats/summary    — Feedback statistics
```

### Telemetry
```
GET /api/telemetry/events     — Raw telemetry events
GET /api/telemetry/summary    — Event aggregates
GET /api/telemetry/platforms  — iOS vs Android split
```

See `docs/LOCAL_RUNTIME.md` for full API reference with examples.

## 📋 Acceptance Criteria (Issue 680)

- [x] Local runtime topology documented (`docs/LOCAL_RUNTIME.md`)
- [x] Startup with one command (`docker-compose up -d`)
- [x] Services split into ui/api/worker with clear ports (3000/3001/3002)
- [x] Environment-based config (no hardcoded secrets)
- [x] Role-aware authentication (admin/analyst/support)
- [x] Correlation IDs propagated through API logs
- [x] Runtime status page with service health

## 🧪 Testing

### Manual Test Plan

1. **Local Startup**
   ```bash
   docker-compose up -d
   docker-compose ps              # Verify all services running
   curl http://localhost:3001/health
   ```

2. **Authentication**
   - Visit http://localhost:3000
   - Select "Admin" account
   - Verify dashboard loads with metrics

3. **Metrics API**
   ```bash
   curl -H "Authorization: Bearer token_admin_abc123" \
     http://localhost:3001/api/metrics/current
   ```

4. **Role-Based Access**
   ```bash
   # Admin can access everything
   curl -H "Authorization: Bearer token_admin_abc123" \
     http://localhost:3001/api/feedback

   # Support can access feedback
   curl -H "Authorization: Bearer token_support_def456" \
     http://localhost:3001/api/feedback

   # Support CANNOT access admin endpoints
   curl -H "Authorization: Bearer token_support_def456" \
     http://localhost:3001/api/feedback (create)  # Would return 403
   ```

5. **Stop & Restart**
   ```bash
   docker-compose down
   docker-compose up -d
   # Verify services restart and reconnect
   ```

## 🔧 Development

### Install Dependencies
```bash
cd api && npm install
cd ../worker && npm install
cd ../frontend && npm install
```

### Run Services Locally (No Docker)
```bash
# Terminal 1: Redis
redis-server

# Terminal 2: API
cd api && npm run dev

# Terminal 3: Worker
cd worker && npm run dev

# Terminal 4: Frontend
cd frontend && npm run dev
```

### Live Reload
- **Frontend**: Vite automatically reloads on file changes
- **API/Worker**: `npm run dev` uses `tsx watch`
- **Docker**: Volumes are mounted for hot reload

## 📈 Next Steps

**Issue 690** (Telemetry ETL + DuckDB):
- Implement data loading from Firebase/Supabase
- Create DuckDB analytics schema
- Wire worker jobs for scheduled ETL
- Dashboard will query DuckDB instead of mock data

**Issue 700** (Feature Flags Control Plane):
- Add feature flag management UI
- Remote config sync endpoints
- Toggle flags live without redeployment

**Issue 710** (Management Audit & Policy Engine):
- Admin action audit logging
- RBAC policy management UI
- Export compliance reports

## 📚 Documentation

- **Setup & API Reference**: `docs/LOCAL_RUNTIME.md`
- **Backend Architecture**: `../planning/docs/backend-architecture.md`
- **Issue Spec**: `../planning/issues/680-management-ui-local-runtime-bootstrap.md`

## 🐛 Troubleshooting

See `docs/LOCAL_RUNTIME.md` for:
- Port conflicts
- Redis connection issues
- Frontend/API connectivity
- Service logs & debugging
- Stale dependencies

## 📝 License

Proprietary — See root LICENSE file.
