# M4: Invited beta operations cockpit (EPIC-0001)

**Status:** `todo`. **Priority:** P0 foundation; do not silently change the beta launch gate or authorize wave expansion. **Epic:** [EPIC-0001](../../epics/EPIC-0001-beta-to-public-launch-operations.md).

## Objective

Deliver source-backed, privacy-safe and continuously extensible operations reporting for the invited beta without recreating the existing React/Express/DuckDB system. The critical safety path is real data, owner decision, feedback and release health; product adoption/reporting and optional automation panels may follow as their source events become available.

## Included workitems

- [WI-0007](../../workitems/WI-0007-live-source-lineage-kpi-contracts.md) — Verify live source lineage, KPI definitions and mock isolation (P0)
- [WI-0008](../../workitems/WI-0008-privacy-safe-read-api-and-freshness.md) — Enforce privacy-safe read API, source freshness and access boundaries (P0)
- [WI-0009](../../workitems/WI-0009-beta-control-room-and-wave-gates.md) — Build beta wave command center and GO/HOLD/HALT scorecard (P0)
- [WI-0010](../../workitems/WI-0010-beta-invitations-installation-funnel.md) — Track invitation, distribution and installation funnel by cohort (P1)
- [WI-0011](../../workitems/WI-0011-product-activation-feature-adoption.md) — Report activation, reminders, inventory, shopping, receipts and backup journeys (P1)
- [WI-0012](../../workitems/WI-0012-feedback-support-incident-desk.md) — Create feedback, support, incidents and severity/response desk (P0)
- [WI-0013](../../workitems/WI-0013-release-health-build-ledger-go-no-go.md) — Build release health, crash/data-loss risk, build ledger and gates (P0)
- [WI-0014](../../workitems/WI-0014-daily-weekly-owner-decision-reports.md) — Produce owner daily/weekly beta reports and evidence-backed decisions (P0)
- [WI-0015](../../workitems/WI-0015-live-worker-monitoring-in-management-ui.md) — Integrate existing live-worker monitoring into launch operations (P1)
- [WI-0016](../../workitems/WI-0016-maf-shadow-review-evaluation-view.md) — Visualize optional MAF shadow-review evaluations and QA comparison (P2)

## Order and acceptance

1. **Foundation:** 0007 real-source lineage and no mock-as-live; 0008 access/freshness/privacy.
2. **Beta safety:** 0009 wave scorecard and 0012 feedback/incident desk, then 0013 release health and 0014 daily/weekly owner decisions.
3. **Evidence-based learning:** 0010 channel/invitation funnel and 0011 released feature journeys; missing instrumentation is a reported gap rather than a zero.
4. **Engineering observation:** 0015 reuses existing [management UI #8](https://github.com/11895079/zerospoils-management-ui/issues/8), including the worker-side ZeroSpoils M6/1111 prerequisite. 0016 displays **optional** MAF #1340 output without replacing the review gate or blocking a beta decision.

**Exit:** at least one consent-appropriate real event proven end to end, real crash/feedback/build status with source timestamps, a dated owner GO/HOLD/HALT decision record and an independently checked daily report. If the GUI is unavailable, `scripts/launch_metrics.py` and original consoles remain the authorized fallback. Nothing in this plan sends invites or launches builds.

## Boundaries

Tester privacy/consent, no raw prompts or session replay in reports, independent RBAC, origin/source truth, and no management dashboard impersonation of GitHub/Firebase/store authority. Workitems are not marked done until independently tested and merged.
