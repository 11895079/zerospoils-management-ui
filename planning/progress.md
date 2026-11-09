# Progress Dashboard

Last Updated: 2026-11-09 (planning rebaseline; implementation states from prior evidence remain unchanged)

## Overall Snapshot

- Total milestones: 6 (M4/M5 are newly planned)
- Total workitems: 20 (WI-0000–0019)
- Completed: 4 (previously recorded; not revalidated in this planning PR)
- In progress: 1 (previously recorded)
- Blocked: 0 recorded
- Todo: 15 (includes 13 new reporting items)
- Overall completion: 4/20 (20%); not a live product-health score

## Milestone Progress

| Milestone | Total | Done | In Progress | Blocked | Progress |
|---|---:|---:|---:|---:|---:|
| M0 | 1 | 1 | 0 | 0 | 100% |
| M1 | 3 | 3 | 0 | 0 | 100% |
| M2 | 1 | 0 | 1 | 0 | 50% |
| M3 | 2 | 0 | 0 | 0 | 0% |
| M4 beta operations | 10 | 0 | 0 | 0 | 0% |
| M5 public launch reporting | 3 | 0 | 0 | 0 | 0% |

## Active Workitems

| Workitem | Status | Owner | Next Checkpoint |
|---|---|---|---|
| [WI-0001](./workitems/WI-0001-ci-test-execution-and-reporting.md) | done | unassigned | Merged and CI stabilized |
| [WI-0002](./workitems/WI-0002-duckdb-analytics-marts.md) | done | unassigned | DuckDB-backed metrics routes implemented and merged |
| [WI-0003](./workitems/WI-0003-worker-bullmq-etl-pipeline.md) | done | unassigned | BullMQ queues + worker health/retry endpoints merged |
| [WI-0004](./workitems/WI-0004-feature-flags-control-plane.md) | in-progress | unassigned | Firebase Remote Config API + admin UI foundation complete |
| [WI-0005](./workitems/WI-0005-audit-policy-rbac-enforcement.md) | todo | unassigned | Policy decision matrix and audit payload shape |
| [WI-0006](./workitems/WI-0006-dashboard-performance-and-observability.md) | todo | unassigned | Baseline p95 latency and frontend bundle profile |

## New EPIC-0001 beta/public reporting workitems

| [WI-0007](./workitems/WI-0007-live-source-lineage-kpi-contracts.md) | todo | unassigned | M4: Verify live source lineage, KPI definitions and mock isolation |
| [WI-0008](./workitems/WI-0008-privacy-safe-read-api-and-freshness.md) | todo | unassigned | M4: Enforce privacy-safe read API, source freshness and access boundaries |
| [WI-0009](./workitems/WI-0009-beta-control-room-and-wave-gates.md) | todo | unassigned | M4: Build beta wave command center and GO/HOLD/HALT scorecard |
| [WI-0010](./workitems/WI-0010-beta-invitations-installation-funnel.md) | todo | unassigned | M4: Track invitation, distribution and installation funnel by cohort |
| [WI-0011](./workitems/WI-0011-product-activation-feature-adoption.md) | todo | unassigned | M4: Report activation, reminders, inventory, shopping, receipts and backup journeys |
| [WI-0012](./workitems/WI-0012-feedback-support-incident-desk.md) | todo | unassigned | M4: Create feedback, support, incidents and severity/response desk |
| [WI-0013](./workitems/WI-0013-release-health-build-ledger-go-no-go.md) | todo | unassigned | M4: Build release health, crash/data-loss risk, build ledger and gates |
| [WI-0014](./workitems/WI-0014-daily-weekly-owner-decision-reports.md) | todo | unassigned | M4: Produce owner daily/weekly beta reports and evidence-backed decisions |
| [WI-0015](./workitems/WI-0015-live-worker-monitoring-in-management-ui.md) | todo | unassigned | M4: Integrate existing live-worker monitoring into launch operations |
| [WI-0016](./workitems/WI-0016-maf-shadow-review-evaluation-view.md) | todo | unassigned | M4: Visualize optional MAF shadow-review evaluations and QA comparison |
| [WI-0017](./workitems/WI-0017-public-launch-staged-rollout-first-48h.md) | todo | unassigned | M5: Run staged public-launch and first-48h operations cockpit |
| [WI-0018](./workitems/WI-0018-retention-food-waste-value-and-learning.md) | todo | unassigned | M5: Analyze real retention, food-waste outcomes and feature value by cohort |
| [WI-0019](./workitems/WI-0019-growth-referral-pro-monetization-forecast.md) | todo | unassigned | M5: Report consented acquisition, referral and Pro monetization when available |

## Weekly Log

### 2026-11-09 (planning only)

- Groomed [EPIC-0001](epics/EPIC-0001-beta-to-public-launch-operations.md), 13 workitems in M4/M5, and linked [management UI epic #9](https://github.com/11895079/zerospoils-management-ui/issues/9). No implementation marked done.
- Reuse existing [worker monitor #8](https://github.com/11895079/zerospoils-management-ui/issues/8) and optional ZeroSpoils MAF [#1340](https://github.com/11895079/zerospoils/issues/1340); do not duplicate worker telemetry or change launches.
- Critical P0 path: source data truth + privacy → beta control room + incident desk → release health → owner report. The source of truth for older workitem status is the previous progress evidence, not the outdated milestone-index percentages.

### 2026-06-10

- Added planning baseline (milestones, workitems, dashboard).
- Captured completed Phase 0 baseline as WI-0000.
- Seeded next work for M1 and M2.
- Retuned milestone plan to match repo roadmap issues 690, 700, and 710.

### 2026-06-11

- Started WI-0001 implementation by adding GitHub Actions workflow for build, unit/coverage, and e2e smoke.
- Completed WI-0001 by merging CI workflow improvements and stabilizing frontend test runtime compatibility.
- Started WI-0002 by wiring `/api/metrics/*` to DuckDB-backed worker marts with documented fallback behavior.

### 2026-06-12

- Started WI-0003 by implementing BullMQ-backed worker queues (`telemetry_etl`, `feedback_processor`, `telemetry_batch`) with recurring and manual enqueue flows.
- Added queue-aware worker health and queue/job observation endpoints with retry diagnostics for failed jobs.
- Added worker tests covering queue identifier validation and ETL audit/marts update behavior.
- Completed local validation sequence: worker build/tests, API build/unit coverage, frontend build/unit/e2e.

### 2026-06-15 (continued)

- Addressed all 9 PR #5 review comments: async error handling, NaN limit handling, ETL audit source tracking, favicon HTML, and auth documentation.
- Merged PR #5 (WI-0003 complete): BullMQ infrastructure with 3 queues, recurring jobs, retry support, and ETL audit trail.
- M1 milestone now 100% complete (3/3 workitems).
- Started WI-0004 by implementing Firebase Remote Config API foundation:
  * Added remoteConfigService with template management, validation, publish/rollback with etag-based conflict resolution
  * Added REST endpoints for fetch, validate, publish, rollback, and version history
  * Created RemoteConfigManager React component for admin UI with dynamic parameter discovery
  * Type-aware editing (BOOLEAN/NUMBER/JSON/STRING) with validation errors
  * Added 9 comprehensive tests covering validation, conflicts, and rollback scenarios
  * All API tests passing (29/29 including 9 new remote config tests)
  * Frontend builds successfully with Remote Config types integrated
- Closed WI-0002 as merged: DuckDB-backed `/api/metrics/*` implementation and documented fallback behavior are on main.
