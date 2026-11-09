# WI-0012: Create feedback, support, incidents and severity/response desk

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0007`, `WI-0008`
- Linked Issue: [#15](https://github.com/11895079/zerospoils-management-ui/issues/15)

## Context

Beta feedback may originate from in-app signed-in form, TestFlight, Firebase tester reports, Loops replies and GitHub issues; M5/625 calls for triage backlog and response-time measures. Sensitive personal content must not leak into general dashboards.

## Goal / user outcome

As a ZeroSpoils launch operator, I can create feedback, support, incidents and severity/response desk with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Create source-backed feedback summary and restricted detail deep-links; normalize source, received_at, severity P0/P1/P2, build, platform, owner, status and first-response time without copying unnecessary message bodies.
- Differentiate confirmed data-loss/privacy issues, crash-on-launch, usability questions and duplicated reports; show untriaged count, p95 time to triage and overdue replies with observable timestamps.
- Link incident record to affected release/feature flag/known issue, action log, containment and human-led halt/hotfix; surface response SLA from beta runbook.
- Support manual CSV or source-link evidence for TestFlight/Firebase feedback when no authorized API exists; no assumed global inbox parity.
- Keep status write actions external unless separately authorized, audited and implemented under WI-0005.

## Acceptance criteria

- [ ] Create source-backed feedback summary and restricted detail deep-links; normalize source, received_at, severity P0/P1/P2, build, platform, owner, status and first-response time without copying unnecessary message bodies.
- [ ] Differentiate confirmed data-loss/privacy issues, crash-on-launch, usability questions and duplicated reports; show untriaged count, p95 time to triage and overdue replies with observable timestamps.
- [ ] Link incident record to affected release/feature flag/known issue, action log, containment and human-led halt/hotfix; surface response SLA from beta runbook.
- [ ] Support manual CSV or source-link evidence for TestFlight/Firebase feedback when no authorized API exists; no assumed global inbox parity.
- [ ] Keep status write actions external unless separately authorized, audited and implemented under WI-0005.

## Out of scope

No automated replies to testers, ticket closure, waiving P0s or forwarding personal feedback to new processors.

## Test plan

**Automated (test-first):**
- `test_feedback_source_dedup_keeps_provenance`
- `test_first_response_and_triage_clock_correct`
- `test_p0_data_loss_blocks_recommendation`
- `test_support_view_redacts_contact_and_message`

**Manual:**
1. Import fixture feedback from two sources representing the same incident and mark a privacy exposure report. Expected: the issue appears once with both source links, P0 escalates, and a restricted operator cannot read personal text.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
