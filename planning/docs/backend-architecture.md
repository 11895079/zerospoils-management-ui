# Backend Architecture Document

## Purpose
Define Pro tier backend services, tech stack, API design, cloud sync strategy, and FinOps cost model. Enables estimate of infrastructure costs for business planning.

## Tech Stack Decision

**Primary Backend: Supabase** (chosen for cost predictability, vendor lock-in mitigation, and PostgreSQL portability)

### Core Services
- **Authentication:** Supabase Auth (OAuth2/OIDC: Google, Apple; email/password)
- **Database:** Supabase PostgreSQL (standard Postgres 15+, no proprietary extensions)
- **Serverless Functions:** Supabase Edge Functions (Deno runtime, free up to 500K invocations/month)
- **Object Storage:** Supabase Storage (S3-compatible API, 30-day lifecycle policies for receipt deletion)
- **OCR Service:** Google Cloud Vision API ($1.50 per 1,000 images; 85-95% accuracy on grocery receipts)
- **Hosting:** Vercel Edge Functions for landing page/admin portal (optional)

### Why Supabase Over Firebase
- **PostgreSQL portability:** Standard SQL; can migrate to AWS RDS, Google Cloud SQL, or self-hosted Postgres with minimal code changes
- **Predictable costs:** Fixed-tier pricing vs. Firebase's per-read/write billing (Supabase Pro $25/mo includes 8GB DB, 100GB storage, 250GB bandwidth)
- **Row-level security:** Built-in Postgres RLS (not vendor-specific); policies enforce data isolation at database level
- **Open-source stack:** Supabase = Postgres + PostgREST + GoTrue (Auth) + Kong (API Gateway)—all self-hostable
- **S3-compatible storage:** Can migrate to AWS S3, MinIO, Cloudflare R2 without changing app code

### Vendor Lock-In Mitigation Strategy

**1. Database Layer Abstraction:**
- Use **repository pattern** in Flutter app: all database access goes through `IInventoryRepository`, `IShoppingListRepository` interfaces
- Implement Supabase adapter (`SupabaseInventoryRepository`) that wraps Supabase Dart SDK
- Write all SQL using **standard PostgreSQL syntax** (no Supabase-specific functions or extensions)
- Design schema with explicit foreign keys, standard types, and Postgres 15+ compatibility

**2. Authentication Abstraction:**
- Wrap Supabase Auth behind `IAuthProvider` interface in app
- Store JWTs in Flutter Secure Storage; verify with standard `dart:jwt` library
- Use OAuth2/OIDC exclusively (Supabase implements these standards)
- Migration path: swap to Firebase Auth, Auth0, or self-hosted Keycloak by implementing new `IAuthProvider` adapter

**3. Storage Abstraction:**
- Use S3-compatible API calls (Supabase Storage supports S3 protocol)
- Wrap storage operations in `IReceiptStorageProvider` interface
- Migration path: point to AWS S3, MinIO, or Cloudflare R2 with credential change only

**4. Edge Functions Portability:**
- Write business logic in standalone TypeScript modules (not Deno-specific)
- Keep Supabase SDK calls isolated to thin adapter layer
- Migration path: redeploy to Cloudflare Workers, AWS Lambda@Edge, or Vercel Edge Functions (all support standard Fetch API)

**5. PostgREST Direct Access:**
- For read-heavy queries (insights dashboard), use PostgREST HTTP API directly instead of Supabase SDK
- PostgREST is open-source and can be self-hosted in front of any Postgres database

**6. Migration Path to Self-Hosted (if needed):**
- **Database:** Export Postgres dump → restore to AWS RDS/Cloud SQL/self-hosted
- **Auth:** Deploy GoTrue (Supabase's open-source auth server) or migrate to Keycloak
- **Storage:** Migrate S3 buckets to MinIO (S3-compatible, self-hosted)
- **Edge Functions:** Redeploy to Cloudflare Workers or AWS Lambda
- **Estimated migration effort:** 2-4 weeks engineering (assuming proper abstraction layers in place)

## API Design

**Authentication Endpoints (Supabase Auth Native):**
   - `POST /auth/v1/signup` - Create account (email/password)
   - `POST /auth/v1/token?grant_type=password` - Login (returns JWT access + refresh tokens)
   - `POST /auth/v1/token?grant_type=refresh_token` - Refresh access token
   - `GET /auth/v1/user` - Get authenticated user metadata
   
   **Sync Endpoints (Supabase Edge Functions):**
   - `POST /functions/v1/sync-inventory` - Incremental sync with conflict resolution
     - Request: `{ household_id, since_timestamp, items: [{ id, name, category, expiry_date, updated_at, device_id }] }`
     - Response: `{ server_items: [...], conflicts: [...] }`
     - Logic: Compare `updated_at` timestamps; last-write-wins; return server changes since `since_timestamp`
   - `GET /functions/v1/sync-changes?household_id={id}&since={timestamp}` - Poll for changes
   
   **Receipt OCR Endpoints (Supabase Storage + Edge Functions):**
   - `POST /storage/v1/object/receipts/{household_id}/{filename}` - Upload receipt image
     - Returns: `{ path, public_url }`
   - `POST /functions/v1/ocr-receipt` - Trigger OCR processing
     - Request: `{ receipt_path, household_id }`
     - Background job: Download from Storage → Google Vision API → parse line items → insert to DB
     - Response: `{ job_id, status: "queued" }`
   - `GET /functions/v1/ocr-status/{job_id}` - Check OCR job status
     - Response: `{ status: "processing" | "completed" | "failed", line_items: [...] }`
   
   **Insights Endpoints (PostgREST + Edge Functions):**
   - `GET /rest/v1/rpc/get_household_insights?household_id={id}&period=week` - Aggregated metrics
     - PostgreSQL function: `SELECT COUNT(*) items_saved, SUM(estimated_cost) cost_avoided FROM event_log WHERE ...`
     - Response: `{ items_saved, items_wasted, cost_avoided_usd, top_waste_categories: [...] }`
   
   **IoT Webhooks (M7 - Future):**
   - `POST /functions/v1/webhook-iot` - Receive IoT device events (NFC tag scans, smart shelf sensors)

## Data Sync Strategy
   
   **Conflict Resolution (Last-Write-Wins):**
   - Compare `updated_at` timestamps: server vs. client
   - If `client.updated_at > server.updated_at`: accept client update
   - If `server.updated_at > client.updated_at`: reject client update, return server version
   - Edge case (simultaneous edits within 1 second): use `device_id` tiebreaker (lexicographic sort)
   - Conflict UI: Show toast "Device X made recent changes" with "Refresh" button
   - Acceptable conflict rate: <5% for household trust model (upgrade to CRDT if exceeded)
   
   **Optimistic UI Updates:**
   - Mobile app updates local DB immediately on user action
   - Background sync queue retries failed syncs with exponential backoff (1s, 2s, 4s, 8s...max 60s)
   - If sync fails after 5 retries: show "Sync pending" indicator; retry on next app open
   
   **Incremental Sync:**
   - Client sends `since_timestamp` (last successful sync)
   - Server returns only items with `updated_at > since_timestamp`
   - Reduces bandwidth and Edge Function execution time
   - PostgreSQL index: `CREATE INDEX idx_items_updated_at ON items(household_id, updated_at)`
   
   **Event Log for Audit Trail:**
   - All item state changes (added, consumed, wasted) append to `event_log` table
   - Never deleted; used for insights aggregation and conflict debugging
   - Schema: `{ id, household_id, item_id, event_type, category, location, timestamp, device_id }`
   
   **Schema Versioning:**
   - Client sends `X-Schema-Version: 1.0.0` header
   - Server supports graceful degradation (ignore unknown fields; set defaults for new required fields)
   - Breaking changes (e.g., rename column) require new API version: `/functions/v2/sync-inventory`

## Database Schema (Pro Tier Additions)
   
   Base schema defined in `docs/data-model.md`. Pro tier adds:
   
   **Household Table:**
   ```sql
   CREATE TABLE households (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     name TEXT NOT NULL,
     owner_user_id UUID NOT NULL REFERENCES auth.users(id),
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```
   
   **Household Members Table:**
   ```sql
   CREATE TABLE household_members (
     household_id UUID REFERENCES households(id) ON DELETE CASCADE,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
     role TEXT CHECK (role IN ('owner', 'member')),
     joined_at TIMESTAMPTZ DEFAULT NOW(),
     PRIMARY KEY (household_id, user_id)
   );
   ```
   
   **Items Table (add sync fields):**
   ```sql
   ALTER TABLE items ADD COLUMN household_id UUID REFERENCES households(id);
   ALTER TABLE items ADD COLUMN synced_at TIMESTAMPTZ;
   ALTER TABLE items ADD COLUMN device_id TEXT;
   
   -- Index for incremental sync queries
   CREATE INDEX idx_items_updated_at ON items(household_id, updated_at);
   CREATE INDEX idx_items_device_id ON items(device_id) WHERE device_id IS NOT NULL;
   ```
   
   **Event Log Table:**
   ```sql
   CREATE TABLE event_log (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     household_id UUID REFERENCES households(id),
     item_id UUID REFERENCES items(id) ON DELETE SET NULL,
     event_type TEXT CHECK (event_type IN ('added', 'consumed', 'wasted', 'edited')),
     category TEXT,
     location TEXT,
     waste_reason TEXT,
     estimated_cost_usd NUMERIC(10, 2),
     timestamp TIMESTAMPTZ DEFAULT NOW(),
     device_id TEXT
   );
   
   CREATE INDEX idx_event_log_household ON event_log(household_id, timestamp DESC);
   ```
   
   **Receipt OCR Jobs Table:**
   ```sql
   CREATE TABLE ocr_jobs (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     household_id UUID REFERENCES households(id),
     receipt_path TEXT NOT NULL,
     status TEXT CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
     line_items JSONB,
     error_message TEXT,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     completed_at TIMESTAMPTZ
   );
   ```
   
   **Subscription Entitlements Table:**
   ```sql
   CREATE TABLE subscriptions (
     user_id UUID PRIMARY KEY REFERENCES auth.users(id),
     tier TEXT CHECK (tier IN ('free', 'pro')),
     status TEXT CHECK (status IN ('active', 'canceled', 'expired')),
     started_at TIMESTAMPTZ,
     expires_at TIMESTAMPTZ
   );
   ```

## Row-Level Security Policies (Standard PostgreSQL)
   
   Enforce data isolation at database level using Postgres RLS:
   
   ```sql
   -- Enable RLS on all tables
   ALTER TABLE items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;
   ALTER TABLE households ENABLE ROW LEVEL SECURITY;
   
   -- Users can only access items from their household
   CREATE POLICY "Users access own household items" ON items
     FOR ALL USING (
       household_id IN (
         SELECT household_id FROM household_members WHERE user_id = auth.uid()
       )
     );
   
   -- Users can only read their household metadata
   CREATE POLICY "Users read own household" ON households
     FOR SELECT USING (
       id IN (
         SELECT household_id FROM household_members WHERE user_id = auth.uid()
       )
     );
   
   -- Only household owners can update household
   CREATE POLICY "Owners update household" ON households
     FOR UPDATE USING (owner_user_id = auth.uid());
   
   -- Event log read-only for insights
   CREATE POLICY "Users read household events" ON event_log
     FOR SELECT USING (
       household_id IN (
         SELECT household_id FROM household_members WHERE user_id = auth.uid()
       )
     );
   ```
   
   **Why RLS:** Standard Postgres feature (9.5+), not vendor-specific; enforces security even if Edge Function has bug; portable to any Postgres provider.

## Security & Privacy
   - **Encryption at rest:** Supabase Pro includes database encryption (AES-256)
   - **Encryption in transit:** TLS 1.3 for all API calls (Supabase default)
   - **Secrets management:** Supabase Dashboard for API keys; Flutter uses environment variables (never commit secrets)
   - **Row-level security:** PostgreSQL RLS policies (see section above); enforced at database level
   - **JWT token security:** Short-lived access tokens (1 hour expiry); refresh tokens rotated on use; stored in Flutter Secure Storage
   - **Rate limiting:** Supabase built-in (60 requests/min per API key for free tier; configurable on Pro)
   - **PII handling:** 
     - No email/phone in telemetry events
     - Receipt images auto-deleted after 30 days (Supabase Storage lifecycle policy)
     - OCR results stored as normalized line items only (no raw text)
   - **Camera permission:** Requested just-in-time (not at app launch); clear rationale shown
   - **GDPR compliance:** Data export via `GET /functions/v1/export-data`; data deletion via `DELETE /functions/v1/delete-account`

## FinOps Cost Model (Monthly Active Users) - Supabase Pro
   
   **100 MAU (Early Launch):**
   - **Supabase:** Free tier ($0)
     - 500 MB database, 1 GB storage, 2 GB bandwidth/month
     - 2 GB Edge Function invocations
   - **Google Vision OCR:** ~$10
     - Assumption: 10 receipts/user/month × 100 users = 1,000 receipts
     - Cost: $1.50 per 1,000 images = $1.50 (actual)
     - Rounding buffer for other Vision API features: ~$10
   - **Total: ~$10/month** (within free tier for Supabase)
   
   **1,000 MAU:**
   - **Supabase Pro:** $25/month (includes)
     - 8 GB database, 100 GB storage, 250 GB bandwidth
     - 500K Edge Function invocations (free)
     - Daily backups, point-in-time recovery
   - **Google Vision OCR:** ~$15
     - 10 receipts/user/month × 1,000 users = 10,000 receipts
     - Cost: $1.50 per 1,000 images = $15
   - **Storage overage:** $0 (within 100 GB included)
   - **Total: ~$40/month (~$0.04/user)**
   
   **10,000 MAU:**
   - **Supabase Pro + Compute Scaling:** ~$75/month
     - Base Pro: $25/month
     - Compute add-on (4 GB RAM for connection scaling): ~$50/month estimate
   - **Google Vision OCR:** ~$150
     - 10 receipts/user/month × 10,000 users = 100,000 receipts
     - Cost: $1.50 per 1,000 images = $150
   - **Storage overage:** ~$10
     - Assumption: 150 GB usage (50 GB over included 100 GB)
     - Overage: $0.021/GB = ~$10
   - **Total: ~$235/month (~$0.02/user)**
   
   **Cost Optimization Tactics:**
   1. **OCR Throttling:** Limit to 10 receipts/user/day (prevents abuse; reduces costs)
   2. **On-Device OCR Priority:** Use ML Kit for expiry dates (free); reserve cloud OCR for full receipts
   3. **Edge Functions for Sync:** Free up to 500K invocations/month on Pro tier (vs. Lambda $0.20 per 1M requests)
   4. **Connection Pooling:** Supabase Pro includes PgBouncer; configure max 50 connections (prevents overprovisioning compute)
   5. **Incremental Sync:** Send only changed records (reduces bandwidth and function execution time)
   6. **Receipt Lifecycle:** Auto-delete images after 30 days (Supabase Storage lifecycle policy; keeps storage costs bounded)
   7. **Read Replicas (if needed at 50K+ MAU):** Offload insights queries to replica (~$25/month additional)
   
   **Scalability Thresholds:**
   - **500 MAU:** Monitor connection pool saturation (alert if >80%); consider compute add-on
   - **5,000 MAU:** Enable Edge Function logging to Sentry; monitor OCR error rate
   - **50,000 MAU:** Add read replica for insights dashboard; consider separate analytics database
   - **100,000+ MAU:** Evaluate self-hosted Postgres + PostgREST (cost ~$200/month for dedicated server vs. ~$500/month Supabase)
   
   **Budget Alerts:**
   - Supabase: Set dashboard alert for database size >7 GB, bandwidth >200 GB/month
   - Google Cloud: Budget notification if OCR costs exceed $200/month (indicates abuse or bot traffic)

## Monitoring & Observability
   
   **Supabase Built-In Metrics (Dashboard):**
   - Database CPU/memory usage (alert if >80% sustained)
   - Connection pool saturation (alert if >40 active connections on free tier, >80 on Pro)
   - Storage usage (alert at 90% of tier limit)
   - API requests per minute (detect abuse patterns)
   - Query performance (slow query log; optimize with indexes)
   
   **Edge Function Logging:**
   - Supabase logs: View in Dashboard (retention: 7 days on Pro)
   - Sentry integration: Capture errors, stack traces (scrub PII from context)
   - Key metrics: 
     - Sync conflict rate (alert if >5%)
     - OCR job failure rate (alert if >5%)
     - Average sync latency (alert if p95 >2 seconds)
   
   **OCR Pipeline Monitoring:**
   - Google Cloud Console: Track Vision API requests, error rate, cost per day
   - OCR job queue: Monitor `ocr_jobs` table for stuck jobs (status='processing' >5 minutes)
   - Alert conditions:
     - OCR error rate >5% (indicates Vision API issue or malformed requests)
     - Daily OCR cost spike >2x average (indicates abuse or bot)
   
   **Mobile App Telemetry:**
   - Crash reporting: Sentry (scrub user data)
   - Performance monitoring: Track app launch time, sync latency, OCR capture time
   - Network monitoring: Detect repeated sync failures (app bug or network issue)
   
   **Key Alerts (PagerDuty/Slack Integration):**
   - Database CPU >80% sustained for 10 minutes
   - Connection pool saturation (>80% connections active)
   - OCR error rate >10% (page on-call engineer)
   - Sync conflict rate >10% (indicates multi-user bug)
   - Daily cost spike >2x average (potential abuse)
   
   **FinOps Dashboards:**
   - Weekly cost review: Supabase invoice + Google Cloud OCR costs
   - Cost per user trend: Track as MAU scales (target <$0.05/user at 10K MAU)
   - Storage growth rate: Project when to upgrade tier or enable lifecycle policies

## How It Will Be Used
- **Pro tier planning (M5/M6):** Scope backend work (issues 410-520)
- **Subscription pricing:** Inform pricing model based on cost per user
- **Technical review:** Architecture validation with senior engineers
- **Infrastructure setup:** Terraform/CloudFormation templates
- **FinOps forecasting:** Budget planning for user growth scenarios
- **AI coding agents:** Backend API reference; consistent integration patterns

## Source Material
Extract from PRD Section 8 (Technical Architecture) and Pro tier issues (410-490, 510-590).

## Status
✅ **COMPLETED** - Supabase-first architecture with vendor lock-in mitigation and cost optimization. Ready for M6 (Pro tier) implementation.
