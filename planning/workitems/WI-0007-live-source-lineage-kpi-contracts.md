# WI-0007: Verify live source lineage, KPI definitions and mock isolation

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0002`
- Linked Issue: [#10](https://github.com/11895079/zerospoils-management-ui/issues/10)

## Context

The UI has DuckDB metrics and telemetry scaffolding, but ZeroSpoils M5/861 records real beta telemetry/feedback endpoints still using mockDataStore. M5/800, M5/970 and M5/625 define the real measurement sources. No launch decision may rely on synthetic metrics.

## Goal / user outcome

As a ZeroSpoils launch operator, I can verify live source lineage, KPI definitions and mock isolation with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Inventory actual Firestore telemetry_events/dev, feedback_submissions, DuckDB mart jobs and API routes; distinguish verified available connectors from intended ones.
- Define one versioned metric registry: event/source, numerator, denominator, timezone/cohort/build filters, dedupe identity, delayed-event policy, consent category and owner; re-use M5/970 definitions where consistent.
- For every read API tile return source_kind, observed_at, calculated_at, freshness, sample_size, completeness and status (live/mock/unknown/stale/unsupported).
- Fail deployed environments closed against mockDataStore, demo tokens and default examples; explicit sandbox fixture mode only.
- Verify at least one consent-appropriate real beta telemetry event and feedback record reaches a management API query; reconcile counts with read-only source evidence.

## Acceptance criteria

- [ ] Inventory actual Firestore telemetry_events/dev, feedback_submissions, DuckDB mart jobs and API routes; distinguish verified available connectors from intended ones.
- [ ] Define one versioned metric registry: event/source, numerator, denominator, timezone/cohort/build filters, dedupe identity, delayed-event policy, consent category and owner; re-use M5/970 definitions where consistent.
- [ ] For every read API tile return source_kind, observed_at, calculated_at, freshness, sample_size, completeness and status (live/mock/unknown/stale/unsupported).
- [ ] Fail deployed environments closed against mockDataStore, demo tokens and default examples; explicit sandbox fixture mode only.
- [ ] Verify at least one consent-appropriate real beta telemetry event and feedback record reaches a management API query; reconcile counts with read-only source evidence.

## Out of scope

No historical fabricated backfill, claiming installs from app opens, automatic client-data migration, app instrumentation change or paid connector.

## Test plan

**Automated (test-first):**
- `test_live_routes_do_not_use_mock_data_store`
- `test_metric_registry_matches_launch_metrics_fixture`
- `test_source_freshness_unknown_and_zero_are_distinct`
- `test_telemetry_and_feedback_lineage_reconcile_to_fixture`

**Manual:**
1. Emit one approved beta test event and verify the source, API and UI after permitted ingestion. Expected: the result matches one traceable source event and shows a source timestamp; a deliberately broken connector displays unavailable rather than zero.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
