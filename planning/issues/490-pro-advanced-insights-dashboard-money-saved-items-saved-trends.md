## Context
Insights are a core Pro value: motivate and quantify impact. Current planning lacks a concrete analytics architecture that separates operational writes (OLTP) from analytical queries (OLAP), which risks inconsistent numbers and slow dashboards.

## Goal
Implement an insights dashboard using local + synced event logs with explicit OLTP/OLAP boundaries and a reusable metric-definition contract.

## Expected behavior
- Dashboard shows weekly/monthly trends
- Shows top wasted categories and progress
- Dashboard supports filters by platform, app version, locale, and household/user scope (where available)
- Metrics are traceable to documented formulas and source datasets

## Acceptance criteria (Definition of Done)
- [ ] Define calculations for: items_saved, items_wasted, estimated_cost_avoided (configurable)
- [ ] Implement dashboard UI with charts
- [ ] Include copy explaining how metrics are estimated
- [ ] Telemetry: insights_view, insights_share (if added)
- [ ] Define and publish a metric spec file (name, formula, dimensions, freshness target) consumed by dashboard and reports
- [ ] Implement OLAP query layer against DuckDB marts (or equivalent analytics adapter) with deterministic fixture outputs
- [ ] Add reconciliation check between OLTP event counts and OLAP aggregates for core metrics
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- External partner reporting
- Revenue attribution or ad-network analytics

## Implementation notes
- Keep codebase modular (domain/data/ui layers).
- OLTP source of truth: app event log and operational entities.
- OLAP source: materialized marts built from normalized telemetry + event data.
- Any metric shown to users must include freshness timestamp and estimation disclaimer text.

## Test plan
**Automated:**
- Unit test: metric formula calculators for `items_saved`, `items_wasted`, `estimated_cost_avoided` using fixed fixtures.
- Integration test: OLAP adapter query results match expected snapshots for 7-day and 30-day windows.
- Contract test: metric-definition file fields are complete (`name`, `formula`, `dimensions`, `freshness_slo`).

**Manual:**
1. Open insights dashboard with seeded fixture data and verify chart values match reference report.
2. Change date range from weekly to monthly and verify calculations remain stable.
3. Apply filter (platform/app version) and verify denominator/percentages update correctly.
4. Trigger offline mode and verify last-known insights are shown with staleness banner.

## Dependencies
- 250 (telemetry instrumentation baseline)
- 500 (consent model for aggregated analytics export)
- 545 (role-aware access for household insights views)
- 690 (telemetry ETL and DuckDB analytics marts)
