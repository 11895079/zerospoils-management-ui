# WI-0013: Build release health, crash/data-loss risk, build ledger and gates

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0009`, `WI-0012`
- Linked Issue: [#16](https://github.com/11895079/zerospoils-management-ui/issues/16)

## Context

Beta and public launch require versioned build evidence, Crashlytics health, distribution status, feature flags/kill switches, privacy consent, rollback and device smoke checks; missing alerts cannot be treated as healthy.

## Goal / user outcome

As a ZeroSpoils launch operator, I can build release health, crash/data-loss risk, build ledger and gates with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Read-only build ledger by platform/versionCode/commit/channel/rollout, release notes and verified console/CI evidence; distinguish TestFlight/Firebase vs store rollout.
- Surface crash-free users/sessions, open P0/P1, confirmed data-loss incidents, telemetry ingestion lag, schema reject counts and budget/alert readiness with source timestamps.
- Show the owner-approved Wave R0/R1 and public Gate D criteria as versioned checklist records; require evidence for device update, rollback/kill-switch and hotfix drill before marking verified.
- Separate risk trigger, operator recommendation and actual owner action; deep-link to Remote Config change/audit rather than executing changes from a read dashboard.
- Include missing source/empty/error state, delayed Crashlytics reporting and unverified App Store/Play Console manual checks.

## Acceptance criteria

- [ ] Read-only build ledger by platform/versionCode/commit/channel/rollout, release notes and verified console/CI evidence; distinguish TestFlight/Firebase vs store rollout.
- [ ] Surface crash-free users/sessions, open P0/P1, confirmed data-loss incidents, telemetry ingestion lag, schema reject counts and budget/alert readiness with source timestamps.
- [ ] Show the owner-approved Wave R0/R1 and public Gate D criteria as versioned checklist records; require evidence for device update, rollback/kill-switch and hotfix drill before marking verified.
- [ ] Separate risk trigger, operator recommendation and actual owner action; deep-link to Remote Config change/audit rather than executing changes from a read dashboard.
- [ ] Include missing source/empty/error state, delayed Crashlytics reporting and unverified App Store/Play Console manual checks.

## Out of scope

No automatic public release, app-store credential delegation, automated kill switch or replacement of the launch runbook.

## Test plan

**Automated (test-first):**
- `test_release_channel_build_ids_do_not_cross_mix`
- `test_no_crashlytics_data_is_unknown_not_healthy`
- `test_data_loss_report_requires_halt_review`
- `test_manual_gate_cannot_self_mark_approved`

**Manual:**
1. Run a synthetic launch rehearsal with one confirmed data-loss incident, an older build and missing Crashlytics telemetry. Expected: the dashboard flags the incident and unsupported evidence, and no rollout/flag or approval is changed.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
