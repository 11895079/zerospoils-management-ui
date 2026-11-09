# WI-0009: Build beta wave command center and GO/HOLD/HALT scorecard

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0007`, `WI-0008`
- Linked Issue: [#12](https://github.com/11895079/zerospoils-management-ui/issues/12)

## Context

The beta plan has explicit Wave 0/Wave N gates (crash-free users, P0/P1 defects, data loss, D1/D7 and operational readiness), but evidence is dispersed across consoles and scripts.

## Goal / user outcome

As a ZeroSpoils launch operator, I can build beta wave command center and GO/HOLD/HALT scorecard with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Deliver a responsive Beta Control Room: active cohort/wave/platform/build, invited and installed where authoritative, activated/retained testers, fresh crash summary, unresolved P0/P1, feedback pending, source errors and owner's next decision.
- Link each gate and threshold to the current owner-approved beta plan and decision version, retaining sample size/time window and threshold provenance; not all thresholds are measurable on day one.
- Show GO/HOLD/HALT **recommendation/unknown** separate from the owner's final dated decision; do not allow the dashboard to authorize beta sends.
- Keep a read-only source list with evidence URLs and manual-verification tasks; export a signed-off decision snapshot without raw PII.
- Render clean empty, live-but-zero, stale, unknown and partial readiness distinctly, and avoid treating missing D7 on a young cohort as zero retention.

## Acceptance criteria

- [ ] Deliver a responsive Beta Control Room: active cohort/wave/platform/build, invited and installed where authoritative, activated/retained testers, fresh crash summary, unresolved P0/P1, feedback pending, source errors and owner's next decision.
- [ ] Link each gate and threshold to the current owner-approved beta plan and decision version, retaining sample size/time window and threshold provenance; not all thresholds are measurable on day one.
- [ ] Show GO/HOLD/HALT **recommendation/unknown** separate from the owner's final dated decision; do not allow the dashboard to authorize beta sends.
- [ ] Keep a read-only source list with evidence URLs and manual-verification tasks; export a signed-off decision snapshot without raw PII.
- [ ] Render clean empty, live-but-zero, stale, unknown and partial readiness distinctly, and avoid treating missing D7 on a young cohort as zero retention.

## Out of scope

No sending invitations, overriding freeze/halt rules, privileged feature toggles or substituting UI decisions for release approvals.

## Test plan

**Automated (test-first):**
- `test_gate_recommendation_requires_complete_evidence`
- `test_crash_threshold_uses_user_denominator_and_sample_count`
- `test_cohort_age_makes_d7_pending_not_failed`
- `test_owner_decision_never_auto_published`

**Manual:**
1. Load a fixture with a severe crash and a too-young D7 cohort, then inspect the wave decision. Expected: crash risk is highlighted with actual denominator and D7 reads pending; no automatic GO or invitation dispatch occurs.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
