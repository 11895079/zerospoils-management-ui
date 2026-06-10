# ZeroSpoils Telemetry ETL Pipeline

## Overview

The ETL (Extract, Transform, Load) pipeline processes raw telemetry events from the ZeroSpoils app into a DuckDB analytics database. This enables the management dashboard to display real metrics instead of mock data.

**Key Features:**
- ✅ 7-phase pipeline with validation and PII redaction
- ✅ Idempotent deduplication using stable fact IDs
- ✅ Scheduled runs every 10 minutes via BullMQ
- ✅ Pre-aggregated analytics marts for fast dashboard queries
- ✅ Compliance with ZeroSpoils redaction policies
- ✅ Audit trail for ETL execution and data lineage

## Architecture

```
ZeroSpoils Telemetry Events
         ↓
[1. Extract] → Raw events
         ↓
[2. Normalize] → Standard schema
         ↓
[3. Validate] → Schema validation + type checking
         ↓
[4. Redact] → Apply PII removal policies
    • Blocked: password, auth_token, credit_card, ssn, phone, email, ip, geo
    • Masked: user_id, household_id (hashed with SHA256)
         ↓
[5. Deduplicate] → Stable fact IDs (MD5 hash of event content)
         ↓
[6. Load] → DuckDB fact tables
    • fact_app_installed
    • fact_item_added
    • fact_item_wasted
    • fact_reminder_opened
    • fact_inventory_viewed
         ↓
[7. Refresh Marts] → Analytics tables for dashboard
    • mart_daily_installs
    • mart_camera_adoption
    • mart_waste_analysis
    • mart_24h_summary (used by dashboard)
         ↓
Dashboard Queries
```

## Telemetry Events Supported

### app_installed
User opened app for first time or after uninstall.

```json
{
  "event_type": "app_installed",
  "timestamp": 1718000000000,
  "platform": "ios",
  "app_version": "1.2.0",
  "release_channel": "stable",
  "user_id": "user_abc123",
  "session_id": "session_xyz",
  "is_first_install": true,
  "source": "app_store",
  "session_duration_seconds": 120
}
```

**Tracked Metrics:**
- Daily installs (new + reinstalls)
- Platform distribution (iOS vs Android)
- Release channel adoption
- D1 retention

### item_added
User saved an item to inventory.

```json
{
  "event_type": "item_added",
  "timestamp": 1718000000000,
  "platform": "ios",
  "app_version": "1.2.0",
  "release_channel": "stable",
  "user_id": "user_abc123",
  "session_id": "session_xyz",
  "entry_source": "camera_barcode",
  "category_id": 1,
  "location_id": 1,
  "barcode_source": "seed_catalog",
  "barcode_confidence": 0.95,
  "expiry_confidence": 0.87,
  "barcode_accepted": true,
  "expiry_accepted": true,
  "has_barcode": true,
  "has_expiry_date": true,
  "expiry_days_out": 30,
  "quantity": 1,
  "session_duration_seconds": 45
}
```

**Entry Sources (Camera Adoption Analysis):**
- `manual` - User typed item details
- `camera_barcode` - Camera recognized barcode only
- `camera_expiry` - Camera recognized expiry only
- `camera_barcode_and_expiry` - Camera recognized both
- `shopping_convert` - Converted from shopping list
- `receipt_batch_camera` - Scanned receipt with camera

**Tracked Metrics:**
- Items added per user (engagement)
- Camera adoption rates by entry source
- Barcode/expiry detection accuracy (confidence scores + user acceptance)
- Barcode source quality (seed catalog vs learned mappings)
- Category distribution
- Storage location distribution

### item_wasted
User marked item as wasted/consumed.

```json
{
  "event_type": "item_wasted",
  "timestamp": 1718000000000,
  "platform": "ios",
  "app_version": "1.2.0",
  "release_channel": "stable",
  "user_id": "user_abc123",
  "session_id": "session_xyz",
  "category_id": 1,
  "location_id": 1,
  "waste_reason": "expired",
  "days_since_added": 25,
  "was_camera_assisted": true,
  "estimated_cost_cents": 350,
  "user_reminder_count": 2,
  "user_acted_on_reminder": true
}
```

**Waste Reasons:**
- `expired` - Item past expiry date
- `spoiled` - Item went bad before expiry
- `overcrowded` - Inventory space issue
- `other` - Other reason

**Tracked Metrics:**
- Waste rate by category
- Total cost of wasted items
- Effectiveness of reminders
- Camera-assisted vs manual entry waste patterns

### reminder_opened
User opened a reminder notification.

```json
{
  "event_type": "reminder_opened",
  "timestamp": 1718000000000,
  "platform": "ios",
  "app_version": "1.2.0",
  "release_channel": "stable",
  "user_id": "user_abc123",
  "session_id": "session_xyz",
  "reminder_type": "expiry",
  "category_id": 1,
  "action_taken": "marked_wasted",
  "time_to_action_seconds": 300
}
```

**Tracked Metrics:**
- Notification engagement rates
- Action conversion rates
- Time to action
- Effectiveness by reminder type

### inventory_viewed
User viewed inventory list.

```json
{
  "event_type": "inventory_viewed",
  "timestamp": 1718000000000,
  "platform": "ios",
  "app_version": "1.2.0",
  "release_channel": "stable",
  "user_id": "user_abc123",
  "session_id": "session_xyz",
  "view_type": "full_inventory",
  "item_count": 15,
  "expired_item_count": 2,
  "days_until_next_expiry": 3,
  "scroll_depth": 85
}
```

**Tracked Metrics:**
- Engagement frequency
- Inventory size per user
- Expired item distribution

## Database Schema

### Dimensions (Reference Tables)

**dim_platform**
- platform_id: 1=iOS, 2=Android
- Used for time-series breakdown by platform

**dim_app_version**
- version, major, minor, patch, release_channel
- Tracks version adoption and crash-free rates per version

**dim_event_type**
- 5 core event types: app_installed, item_added, item_wasted, reminder_opened, inventory_viewed
- Plus extension types for future analysis

**dim_entry_source**
- 6 entry methods with camera_assisted flag
- Key for camera adoption analysis

**dim_category**
- 10 grocery categories (dairy, produce, meat, etc.)
- For category-level waste and engagement analysis

**dim_location**
- 5 storage locations (fridge, freezer, pantry, counter, other)
- For location-specific patterns

**dim_waste_reason**
- 4 reasons: expired, spoiled, overcrowded, other
- Root cause analysis for waste

**dim_barcode_source**
- seed_catalog, learned_mapping, unknown, none
- Quality indicator for barcode recognition

**dim_date**
- Time dimension for daily/weekly/monthly aggregation

### Fact Tables

**fact_app_installed**
- Rows: ~100-500/day per platform
- Key columns: is_first_install, source, session_duration_seconds

**fact_item_added**
- Rows: ~10K-50K/day
- Key columns: entry_source_id, barcode_confidence, expiry_confidence, barcode_accepted, expiry_accepted
- Used for camera adoption analysis

**fact_item_wasted**
- Rows: ~1K-5K/day
- Key columns: waste_reason_id, days_since_added, was_camera_assisted, estimated_cost_cents
- Cost impact analysis

**fact_reminder_opened**
- Rows: ~5K-20K/day
- Key columns: action_taken, time_to_action_seconds

**fact_inventory_viewed**
- Rows: ~20K-100K/day
- Key columns: item_count, expired_item_count, scroll_depth

### Analytics Marts (Pre-aggregated)

**mart_24h_summary**
- Single row per refresh cycle (~every 10 min)
- Used directly by dashboard
- Columns: new_installs_24h, active_users_24h, items_added_24h, d1_retention_pct, crash_free_rate_pct, camera_assist_items_pct

**mart_daily_installs**
- Platform + source breakdown by date
- For new installs chart

**mart_camera_adoption**
- Daily breakdown of camera adoption by entry source
- Key metric: camera_adoption_pct, barcode_accepted_pct, expiry_accepted_pct

**mart_waste_analysis**
- Daily waste by category and reason
- Key metric: total_cost_cents (cost of waste)

**mart_retention_cohorts**
- D0, D1, D7, D30 retention rates by install date
- For retention trend analysis

## Running the ETL Pipeline

### Prerequisites

1. **DuckDB installed** (bundled with `duckdb` npm package)
2. **Redis running** (Docker: `redis:7-alpine`)
3. **Node.js 18+**

### Configuration

Set environment variables in `.env.local`:

```bash
# Redis connection
REDIS_URL=redis://redis:6379

# DuckDB database path
DUCKDB_PATH=./data/zerospoils_analytics.db

# Telemetry source (mock or zerospoils - for production)
TELEMETRY_SOURCE=mock

# Worker port
WORKER_PORT=3002
```

### Starting the Worker

```bash
cd management-backend/worker

# Development mode (with hot reload)
npm run dev

# Production build
npm run build
npm run start
```

### Manually Trigger ETL

```bash
# Trigger via API
curl -X POST http://localhost:3002/etl/run \
  -H "Content-Type: application/json" \
  -d '{"source": "mock", "force_refresh": false}'

# Response
{
  "job_id": "etl-1718000000000",
  "status": "queued",
  "message": "ETL job queued for processing"
}
```

### Monitor Execution

```bash
# Health status
curl http://localhost:3002/health

# Job history
curl http://localhost:3002/jobs?status=completed&limit=10

# ETL audit trail
curl http://localhost:3002/etl/history?limit=20

# Current 24h metrics
curl http://localhost:3002/metrics/current

# Historical metrics (last 7 days)
curl http://localhost:3002/metrics/history?days=7
```

## Debugging

### DuckDB Queries

Connect to DuckDB directly:

```bash
duckdb ./data/zerospoils_analytics.db

# View fact table row counts
SELECT table_name, COUNT(*) as rows
FROM (
  SELECT * FROM fact_app_installed
  UNION ALL SELECT * FROM fact_item_added
  UNION ALL SELECT * FROM fact_item_wasted
) t
GROUP BY table_name;

# Check current metrics
SELECT * FROM v_current_metrics;

# View ETL history
SELECT load_id, load_timestamp, raw_event_count, processing_duration_ms
FROM fact_etl_metadata
ORDER BY load_timestamp DESC
LIMIT 10;
```

### Common Issues

**Issue: "DuckDB not initialized"**
- Worker failed to start ETL database
- Check: DUCKDB_PATH is writable, disk space available
- Solution: Delete database file and restart

**Issue: "Redis connection refused"**
- Redis service not running
- Solution: Ensure Redis container is up: `docker-compose ps`

**Issue: ETL jobs stuck in "active"**
- Worker crashed mid-job
- Solution: Clear Redis keys: `redis-cli DEL bull:etl-pipeline:*`

**Issue: No metrics in dashboard**
- ETL never completed successfully
- Solution: Check worker logs, ensure mock events are generated

### Testing ETL Offline

```bash
# Run tests with your implementation
npm test -- src/__tests__/etl.test.ts

# Test specific phase
npm test -- src/__tests__/etl.test.ts -t "Redact"

# Debug specific event
# Edit generateMockEvents() in src/etl/index.ts to test corner cases
```

## Performance Tuning

### DuckDB Query Optimization

```sql
-- Index key queries for dashboard performance
-- Already created in schema:
CREATE INDEX idx_item_added_timestamp ON fact_item_added(event_timestamp);
CREATE INDEX idx_item_added_platform ON fact_item_added(platform_id);
CREATE INDEX idx_item_added_entry_source ON fact_item_added(entry_source_id);

-- Run ANALYZE to update stats
ANALYZE fact_item_added;
ANALYZE fact_item_wasted;
ANALYZE fact_app_installed;
```

### ETL Performance Targets

| Phase | Target Duration | Notes |
|-------|-----------------|-------|
| Extract | < 1s | Minimal I/O |
| Normalize | < 0.5s | In-memory |
| Validate | < 2s | Schema checks |
| Redact | < 1s | Crypto (SHA256) |
| Deduplicate | < 1s | Hash map |
| Load | < 5s | DuckDB insert + transaction |
| Mart Refresh | < 10s | Aggregation queries |
| **Total** | **< 20s** | End-to-end 10-minute window |

### Scaling to Higher Volumes

For production with millions of daily events:

1. **Parallel ETL**: Run separate workers per event type
2. **Micro-batching**: Process events in 1-minute windows instead of 10-minute
3. **Parquet Export**: Archive old fact tables to Parquet for cold storage
4. **Incremental Marts**: Use upsert instead of truncate for non-key columns

## Compliance & Audit

### Redaction Policy

All PII is removed/masked per ZeroSpoils policies:

**Blocked Fields (Removed):**
- password, auth_token, credit_card, ssn
- phone, email_address
- ip_address, latitude, longitude

**Masked Fields (Hashed with SHA256):**
- user_id → anonymous hash (but consistent across events)
- household_id → anonymous hash

### Audit Trail

Every ETL run records:

```sql
SELECT
  load_id,
  load_timestamp,
  raw_event_count,
  redacted_fields_count,
  masked_fields_count,
  validation_failures,
  processing_duration_ms
FROM fact_etl_metadata
ORDER BY load_timestamp DESC;
```

### Data Lineage

Events have traceability to:
1. Original event_id (stable hash for deduplication)
2. Load batch (load_id)
3. Processing timestamp
4. Redaction applied (fact_redaction_audit)

## Integration with Dashboard

The dashboard queries only mart tables (never raw facts):

```typescript
// API endpoint
GET /api/metrics/current
// Returns: new_installs_24h, active_users_24h, items_added_24h, d1_retention_pct, crash_free_rate_pct, camera_assist_items_pct

GET /api/metrics/history?days=7
// Returns: historical breakdown for charts
```

Refresh interval: **30 seconds** (dashboard auto-refreshes every 30s, mart refreshes every 10 min)

## Next Steps

1. **Integration with ZeroSpoils**: Replace mock extract with real telemetry API
2. **Dashboards**: Build analytics dashboard using charts from mart tables
3. **Alerting**: Add thresholds for crash-free rate, retention drops
4. **Retention Cohorts**: Implement D0/D1/D7/D30 cohort analysis
5. **Custom Queries**: Enable analysts to run DuckDB queries directly
