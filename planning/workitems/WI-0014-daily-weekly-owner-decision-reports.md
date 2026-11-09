# WI-0014: Produce owner daily/weekly beta reports and evidence-backed decisions

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0009`, `WI-0012`, `WI-0013`
- Linked Issue: [#17](https://github.com/11895079/zerospoils-management-ui/issues/17)

## Context

The post-launch playbook asks for 15-minute daily status, weekly cohort reviews and dated go/no-go decisions. M5/970 already supplies a read-only launch KPI script; an operator view should reuse definitions, not silently supersede it.

## Goal / user outcome

As a ZeroSpoils launch operator, I can produce owner daily/weekly beta reports and evidence-backed decisions with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Generate a beta daily briefing: release/build, known P0/P1, crash-free/sample, distribution, D1/D7 when cohort age permits, feedback backlog/response, active incidents and unavailable sources.
- Produce weekly cohort/release comparisons with denominators, versioned metric registry and confidence caveats; include manual-owner approvals and follow-up links.
- Export Markdown/CSV and a printable snapshot with source timestamps and provenance; distinguish incomplete/missing data, delayed export and unknown from zero.
- Link observed threshold breaches to the approved runbook's halt criteria; never change feature flags, send emails or auto-halt releases.
- Reconcile sample totals and trends with M5/970 script outputs and independently verified console screenshots or authorized exports.

## Acceptance criteria

- [ ] Generate a beta daily briefing: release/build, known P0/P1, crash-free/sample, distribution, D1/D7 when cohort age permits, feedback backlog/response, active incidents and unavailable sources.
- [ ] Produce weekly cohort/release comparisons with denominators, versioned metric registry and confidence caveats; include manual-owner approvals and follow-up links.
- [ ] Export Markdown/CSV and a printable snapshot with source timestamps and provenance; distinguish incomplete/missing data, delayed export and unknown from zero.
- [ ] Link observed threshold breaches to the approved runbook's halt criteria; never change feature flags, send emails or auto-halt releases.
- [ ] Reconcile sample totals and trends with M5/970 script outputs and independently verified console screenshots or authorized exports.

## Out of scope

No automated launch, contact emails, unaudited dashboard-specific KPI maths or synthetic week-1 public launch report.

## Test plan

**Automated (test-first):**
- `test_daily_report_has_source_times_and_unknowns`
- `test_weekly_d1_d7_windows_use_eligible_cohorts`
- `test_kpi_export_reconciles_with_launch_metrics_fixture`
- `test_report_cannot_publish_or_authorize_invites`

**Manual:**
1. Generate a report from a fixed beta rehearsal fixture including one stale source and one open incident. Expected: exported and on-screen figures match M5/970 definitions and label stale metrics and the open incident without auto-issuing a GO decision.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
