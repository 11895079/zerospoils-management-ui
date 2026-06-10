# API-DuckDB Integration (Phase 2)

## Overview

Phase 2 integrates the DuckDB analytics database with the management API, replacing mock data with real telemetry metrics from the ETL pipeline.

**Key Changes:**
- ✅ API queries DuckDB marts via worker service
- ✅ Graceful fallback to mock data when DuckDB is unavailable
- ✅ Real-time metrics from aggregated analytics tables
- ✅ New telemetry analytics endpoints
- ✅ Worker URL configuration for distributed deployment

## Architecture

```
Frontend (React)
     ↓
API (Express)
  ├─ GET /api/metrics/current
  ├─ GET /api/metrics/history
  ├─ GET /api/metrics/summary
  ├─ GET /api/telemetry/camera-adoption
  ├─ GET /api/telemetry/waste-analysis
  └─ GET /api/telemetry/retention-cohorts
     ↓
DuckDB Service (Node.js HTTP client)
  └─ Fetch metrics from worker service
     ↓
Worker Service (BullMQ + DuckDB)
  └─ Query analytics marts
     ↓
DuckDB Database
  ├─ mart_24h_summary
  ├─ mart_camera_adoption
  ├─ mart_waste_analysis
  ├─ mart_retention_cohorts
  └─ ...other marts
```

## API Endpoints

### Metrics Endpoints (Real Data from DuckDB)

#### GET /api/metrics/current
**Returns:** Current 24-hour aggregated metrics

```javascript
// Request
curl -H "Authorization: Bearer token_admin_abc123" \
  http://localhost:3001/api/metrics/current

// Response
{
  "data": {
    "newInstalls": 150,
    "activeUsers": 2500,
    "itemsAdded": 12000,
    "itemsWasted": 800,
    "d1Retention": 0.75,
    "crashFreeRate": 0.998,
    "camerAssistanceRate": 0.655,
    "avgSessionDuration": 245,
    "notificationOptInRate": 0.823,
    "totalWasteCost": 450.00
  },
  "source": "duckdb",  // or "mock" if unavailable
  "timestamp": "2026-06-10T12:00:00Z"
}
```

**Fields:**
- `newInstalls` - New app installations in last 24h
- `activeUsers` - Daily active users
- `itemsAdded` - Items added to inventory
- `itemsWasted` - Items marked as wasted
- `d1Retention` - Day 1 retention rate (0-1)
- `crashFreeRate` - Crash-free percentage (0-1)
- `camerAssistanceRate` - % items added via camera (0-1)
- `avgSessionDuration` - Average session length (seconds)
- `notificationOptInRate` - % users who opted into notifications (0-1)
- `totalWasteCost` - Estimated cost of wasted items (USD)

#### GET /api/metrics/history?days=7
**Returns:** Historical metrics for time-series charts

```javascript
// Request
curl -H "Authorization: Bearer token_admin_abc123" \
  "http://localhost:3001/api/metrics/history?days=7"

// Response
{
  "data": [
    {
      "timestamp": "2026-06-09T12:00:00Z",
      "newInstalls": 140,
      "activeUsers": 2400,
      "itemsAdded": 11500,
      "d1Retention": 0.745,
      "crashFreeRate": 0.997
    },
    ...
  ],
  "source": "duckdb",
  "days": 7,
  "count": 7
}
```

#### GET /api/metrics/summary
**Returns:** Current metrics with trend analysis

```javascript
// Response
{
  "current": { ... },  // Same as /metrics/current
  "trends": {
    "installs24h": 8.5,      // % change vs previous period
    "retention7d": 75.0,     // % (D1 retention)
    "crashFreeRate": 99.8    // %
  },
  "source": "duckdb",
  "timestamp": "2026-06-10T12:00:00Z"
}
```

### New Telemetry Analytics Endpoints

#### GET /api/telemetry/camera-adoption
**Returns:** Camera adoption rates and quality metrics

```javascript
{
  "data": [
    {
      "source_name": "camera_barcode",
      "item_count": 4500,
      "avg_barcode_confidence": 0.96,
      "avg_expiry_confidence": 0.89,
      "barcode_accepted_pct": 98.5,
      "expiry_accepted_pct": 92.3
    }
  ],
  "metadata": {
    "description": "Camera adoption rates by entry source",
    "metrics": ["camera_adoption_pct", "barcode_accepted_pct", "expiry_accepted_pct"]
  }
}
```

**Metrics:**
- `barcode_confidence` - 0-1 ML model confidence for barcode detection
- `barcode_accepted_pct` - % of camera barcodes user accepted
- `expiry_confidence` - 0-1 ML model confidence for expiry detection
- `expiry_accepted_pct` - % of camera expiry dates user accepted

**Analysis Use Cases:**
- Which entry sources users prefer (manual vs camera variants)
- Where to improve camera recognition (low confidence → data tagging)
- User trust in camera (acceptance rate → UX trust signals)

#### GET /api/telemetry/waste-analysis
**Returns:** Waste patterns by category with cost impact

```javascript
{
  "data": [
    {
      "category": "Dairy",
      "totalWasted": 340,
      "totalCost": 1250.00,
      "avgDaysInInventory": 8
    },
    {
      "category": "Produce",
      "totalWasted": 680,
      "totalCost": 2100.00,
      "avgDaysInInventory": 6
    }
  ],
  "metadata": {
    "description": "Waste analysis by category (cost impact)",
    "period": "Last 30 days"
  }
}
```

**Analysis Use Cases:**
- Priority for waste reduction (highest cost categories)
- Category-specific recommendations (dairy spoils faster)
- Cost justification for inventory notifications

#### GET /api/telemetry/entry-sources
**Returns:** Distribution of item entry methods

```javascript
{
  "data": [
    {
      "source": "camera_barcode",
      "count": 4500,
      "percentage": 45.2,
      "avgBarcodeConfidence": 0.96,
      "avgExpiryConfidence": 0.89
    },
    {
      "source": "manual",
      "count": 3200,
      "percentage": 32.1,
      "avgBarcodeConfidence": null,
      "avgExpiryConfidence": null
    }
  ],
  "metadata": {
    "description": "Item entry method distribution and quality metrics",
    "total_items": 9950
  }
}
```

**Analysis Use Cases:**
- Camera adoption rate (camera_* / total)
- Manual entry prevalence
- Quality variance by method

#### GET /api/telemetry/retention-cohorts
**Returns:** User retention by install cohort

```javascript
{
  "data": [
    {
      "install_date": "2026-05-15",
      "d0_retention": 1.0,
      "d1_retention": 0.75,
      "d7_retention": 0.45,
      "d30_retention": 0.25
    }
  ],
  "metadata": {
    "description": "User retention by install cohort (D0, D1, D7, D30)",
    "note": "Null values indicate not yet measured"
  }
}
```

**Metrics:**
- `d0_retention` - Always 1.0 (install day)
- `d1_retention` - Returned on day 2
- `d7_retention` - Returned within 7 days
- `d30_retention` - Returned within 30 days

**Analysis Use Cases:**
- Retention funnel (identify where users drop off)
- Cohort comparison (recent vs older cohorts)
- Feature impact (release → compare cohorts before/after)

#### GET /api/telemetry/categories
**Returns:** Engagement and waste metrics by grocery category

```javascript
{
  "data": [
    {
      "name": "Dairy",
      "itemsAdded": 2450,
      "itemsWasted": 340,
      "wasteRate": 13.9,
      "avgDaysInStorage": 8,
      "totalWasteCost": 1250
    }
  ]
}
```

#### GET /api/telemetry/barcode-quality
**Returns:** Barcode recognition quality by source

```javascript
{
  "data": [
    {
      "source": "Seed Catalog",
      "itemCount": 4500,
      "avgBarcodeConfidence": 0.96,
      "avgExpiryConfidence": 0.89,
      "itemsWithExpiry": 3800
    },
    {
      "source": "Learned Mapping",
      "itemCount": 1200,
      "avgBarcodeConfidence": 0.82,
      "avgExpiryConfidence": 0.71,
      "itemsWithExpiry": 600
    }
  ],
  "metadata": {
    "description": "Barcode and expiry recognition accuracy by source",
    "note": "Manual entries have no confidence scores"
  }
}
```

#### GET /api/telemetry/etl-status
**Returns:** ETL pipeline execution history (admin only)

```javascript
{
  "last_run": {
    "load_id": "load_1718000000000_abc123",
    "load_timestamp": "2026-06-10T12:00:00Z",
    "raw_event_count": 50000,
    "deduplicated_count": 49500,
    "processing_duration_ms": 12500,
    "mart_refresh_duration_ms": 8200
  },
  "recent_runs": [ ... ]
}
```

**Use Cases:**
- Monitor ETL pipeline health
- Check data freshness
- Diagnose slow pipelines

## Configuration

### Environment Variables

```bash
# API configuration
API_PORT=3001
CORS_ORIGIN=http://localhost:3000

# DuckDB service (worker location)
WORKER_URL=http://worker:3002
```

### Docker Compose

```yaml
api:
  environment:
    - WORKER_URL=http://worker:3002
    - REDIS_URL=redis://redis:6379
```

## Fallback Strategy

When DuckDB is unavailable (worker service down, no data yet):

```typescript
// Try DuckDB first
const duckdbMetrics = await getCurrentMetrics();

if (duckdbMetrics) {
  return { data: duckdbMetrics, source: 'duckdb' };
}

// Fallback to mock data
const mockMetrics = generateMockMetrics();
return { data: mockMetrics, source: 'mock' };
```

The API includes a `source` field in responses indicating whether data came from `'duckdb'` or `'mock'`.

**Frontend should display:**
- "Live Data" badge when source is 'duckdb'
- "Demo Data" or "Loading..." when source is 'mock'

## Performance

### Query Latency

| Endpoint | DuckDB Latency | Notes |
|----------|---|---|
| /metrics/current | ~50-100ms | Single row mart query |
| /metrics/history | ~100-200ms | 7-30 day range scan |
| /telemetry/camera-adoption | ~150-300ms | Group by aggregation |
| /telemetry/waste-analysis | ~150-300ms | Multi-level join |

### API Response Time

Total API response = Query latency + Network overhead (~50ms)

- Expected: 100-350ms
- Acceptable: < 500ms (user-noticeable)

### Caching Strategy (Optional)

For slower queries, cache in Redis:

```typescript
const CACHE_TTL = 5 * 60; // 5 minutes

// Try cache first
const cached = await redis.get('metrics:waste-analysis');
if (cached) return JSON.parse(cached);

// Query DuckDB
const result = await queryWasteAnalysis();

// Cache result
await redis.set('metrics:waste-analysis', JSON.stringify(result), 'EX', CACHE_TTL);

return result;
```

## Testing

### Unit Tests

```bash
npm test -- src/__tests__/duckdb-integration.test.ts
```

### Integration Test (API + Worker)

```bash
# Start services
docker-compose up -d

# Run integration test
curl -H "Authorization: Bearer token_admin_abc123" \
  http://localhost:3001/api/metrics/current

# Check response includes "source": "duckdb"
```

### Fallback Test (Simulate Worker Down)

```bash
# Stop worker
docker-compose stop worker

# API should return mock data with source: "mock"
curl -H "Authorization: Bearer token_admin_abc123" \
  http://localhost:3001/api/metrics/current
```

## Debugging

### Check DuckDB Service Health

```bash
# Via worker health endpoint
curl http://localhost:3002/health

# Response should show duckdb: "healthy"
```

### Check API→Worker Communication

```bash
# Enable debug logging in API
DEBUG=*:duckdb npm run dev

# Make request
curl http://localhost:3001/api/metrics/current

# Should see HTTP request logs
```

### Verify Data in DuckDB

```bash
# Connect directly to DuckDB
duckdb ./data/zerospoils_analytics.db

# Check latest mart data
SELECT * FROM mart_24h_summary ORDER BY summary_timestamp DESC LIMIT 1;

# Count fact tables
SELECT COUNT(*) FROM fact_item_added;
SELECT COUNT(*) FROM fact_app_installed;
```

## Next Steps (Phase 3)

1. **BullMQ Job Scheduling:** Automated 10-minute ETL runs
2. **Dashboard Analytics Page:** UI components for telemetry views
3. **Real Data Integration:** Replace mock extract with ZeroSpoils API
4. **Performance Optimization:** Query caching, incremental loads
5. **Alerting:** Thresholds for crash-free rate, retention drops
