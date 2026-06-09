## Context
Crash reporting exists, but there is no unified control plane for monitoring app health, telemetry freshness, and backend signal quality. This creates blind spots for launch, beta triage, and day-2 operations.

## Goal
Define and implement the baseline observability model for the management backend UI, including health metrics, alert routing, ownership, and operational runbooks.

## Expected behavior
- Operators can see app and pipeline health in one place within 5 minutes of new signal arrival.
- Alerts are routed to named owners with clear severity and escalation rules.
- The dashboard distinguishes app health failures (crash spikes) from data pipeline failures (ingestion lag, schema rejects).

## Acceptance criteria (Definition of Done)
- [ ] Define and document SLO-lite metrics in `docs/ops/observability.md`:
  - `crash_free_sessions_percent` (target >= 98.0% over rolling 60m)
  - `app_start_failure_rate` (target <= 0.5% over rolling 60m)
  - `reminder_delivery_failure_rate` (target <= 2.0% over rolling 24h)
  - `telemetry_ingestion_lag_seconds_p95` (target <= 300s)
  - `telemetry_schema_reject_rate` (target <= 0.5% over rolling 24h)
- [ ] Define severity thresholds and response matrix (SEV1/SEV2/SEV3) with paging ownership.
- [ ] Build observability dashboard spec with at least these panels:
  - App health (crashes, startup failures)
  - Messaging/notification health
  - Telemetry pipeline freshness and reject counts
  - Top failure signatures by app version/platform
- [ ] Configure alert routing to Slack/email with testable contact list and fallback owner.
- [ ] Add runbook section for each alert family: trigger meaning, first checks, rollback/mitigation, escalation path.
- [ ] Add telemetry event definitions for management actions:
  - `ops_alert_acknowledged`
  - `ops_alert_escalated`
  - `ops_dashboard_viewed`
- [ ] Add/update automated tests for metric calculation and threshold evaluation.
- [ ] Offline-first fallback documented: operators can inspect latest locally cached health snapshot if upstream data source is temporarily unavailable.

## Out of scope
- Full distributed tracing and span-level diagnostics.
- Long-term AI-driven anomaly detection.

## Implementation notes
- Keep observability contracts modular and backend-agnostic (Firebase/BigQuery today, adapter for alternate backend later).
- Separate source-of-truth operational metrics from product analytics charts to avoid inconsistent incident decisions.
- Ensure every alert has exactly one accountable owner role (`admin`, `analyst`, or `support`) and one backup.

## Test plan
**Automated:**
- Unit test: threshold evaluation produces expected severity for boundary values.
- Unit test: ingestion lag calculator handles clock skew and late-arriving events.
- Integration test: synthetic alert event is routed to configured Slack/email targets.
- Contract test: dashboard query adapters return complete metric payloads (no null critical fields).

**Manual:**
1. Trigger a test crash in non-debug build and verify dashboard updates and alert notification within 15 minutes.
2. Simulate telemetry ingestion pause and verify `telemetry_ingestion_lag_seconds_p95` breach alert appears with runbook link.
3. Acknowledge and escalate an alert from management UI, then verify audit trail entry is created.
4. Validate fallback behavior by disconnecting analytics source and confirming local cached snapshot is shown with staleness banner.

## Dependencies
- 360 (Firebase mobile integration baseline)
- 250 (telemetry instrumentation and schema governance)
- 625 (launch metrics dashboard wiring)
- 680 (management UI local runtime bootstrap)
- 710 (management audit and policy engine)
