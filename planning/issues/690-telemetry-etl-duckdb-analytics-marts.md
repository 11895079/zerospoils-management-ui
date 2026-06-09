# 690 — Telemetry ETL + DuckDB Analytics Marts (Local-First OLAP)

## Context
Telemetry contracts and policies exist, but there is no formal local ETL path that transforms operational signals into analytics-ready datasets for dashboards. Without this, launch and ongoing management dashboards are brittle and inconsistent.

## Goal
Implement a local-first ETL pipeline that extracts telemetry and operations signals, enforces schema/redaction policies, and loads analytics marts into DuckDB for fast OLAP queries.

## Expected behavior
- ETL runs on-demand or scheduled locally.
- Pipeline performs extract, normalize, redact, and load stages with observable run metadata.
- DuckDB marts serve dashboard queries with consistent metric definitions.
- Pipeline is idempotent and safe to re-run.

## Acceptance criteria (Definition of Done)
- [ ] Source connectors implemented for telemetry, feedback queue, and config change events.
- [ ] Normalization enforces telemetry envelope schema + allowlist policies.
- [ ] Redaction rules applied consistently before load.
- [ ] DuckDB schema and marts documented (`docs/ops/analytics-marts.md`).
- [ ] Incremental watermarking implemented per source stream.
- [ ] Idempotent merge/upsert strategy implemented using stable event keys.
- [ ] ETL run log captures run_id, source_count, loaded_count, reject_count, duration.
- [ ] Query interface supports dimensions: platform, app_version, locale, release_channel.

## Out of scope
- Real-time streaming ingestion.
- Enterprise data warehouse replacement.
- ML feature store generation.

## Implementation notes
- Treat Firebase and local files as source connectors behind adapter interfaces.
- Keep marts denormalized for dashboard responsiveness but preserve lineage back to source ids.
- Ship fixture datasets for deterministic metric tests.

## Test plan
**Automated:**
- Unit test: schema validation rejects invalid payloads and records reason codes.
- Unit test: redaction removes blocked keys without corrupting required fields.
- Integration test: duplicate source batches do not duplicate mart records.
- Integration test: watermark resume picks up only new records.
- Snapshot test: core query outputs match expected fixture values for 7-day and 30-day windows.

**Manual:**
1. Run ETL on fixture dataset and verify marts populate expected row counts.
2. Re-run ETL with same input and verify no duplicate fact rows.
3. Introduce malformed payload sample and verify reject appears in ETL run log.

## Dependencies
- 250 (telemetry instrumentation baseline)
- 390 (observability baseline)
- 625 (launch/ops metrics dashboard)
- 680 (management UI local runtime bootstrap)
