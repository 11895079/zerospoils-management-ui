# WI-0017: Run staged public-launch and first-48h operations cockpit

## Metadata

- Status: `todo`
- Milestone: `M5`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P1`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0013`, `WI-0014`
- Linked Issue: [#19](https://github.com/11895079/zerospoils-management-ui/issues/19)

## Context

The beta management view must grow into an owner-controlled App Store/Google Play staged launch control room, aligned with ZeroSpoils M5/620 and M5/625; beta distribution must not be mistaken for public store rollout.

## Goal / user outcome

As a ZeroSpoils launch operator, I can run staged public-launch and first-48h operations cockpit with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Show verified iOS App Store Connect and Android Play Console readiness, listing assets, review status, staged rollout percentage, publish dates, app build numbers and source-specific installs; label missing integration as manual evidence.
- Provide T-24h, T0, T+2h, T+24h and T+48h operator checkpoints linked to runbooks, build ledger and owner decisions; classify blockers by severity and assigned owner.
- Combine real Crashlytics, performance, ingestion, feedback, app version adoption, cancellation/hotfix and store rating/review sources with timestamps and uncertainty.
- Include pause/rollback/kill-switch deep-links and auditable runbook notes, never a default live mutation endpoint or auto rollout.
- Publish 48-hour and week-1 reports with actual event window, denominator, source, known gaps and signed-off outcome; never pre-mark unexecuted launch activities complete.

## Acceptance criteria

- [ ] Show verified iOS App Store Connect and Android Play Console readiness, listing assets, review status, staged rollout percentage, publish dates, app build numbers and source-specific installs; label missing integration as manual evidence.
- [ ] Provide T-24h, T0, T+2h, T+24h and T+48h operator checkpoints linked to runbooks, build ledger and owner decisions; classify blockers by severity and assigned owner.
- [ ] Combine real Crashlytics, performance, ingestion, feedback, app version adoption, cancellation/hotfix and store rating/review sources with timestamps and uncertainty.
- [ ] Include pause/rollback/kill-switch deep-links and auditable runbook notes, never a default live mutation endpoint or auto rollout.
- [ ] Publish 48-hour and week-1 reports with actual event window, denominator, source, known gaps and signed-off outcome; never pre-mark unexecuted launch activities complete.

## Out of scope

No automatic store submission, payment or marketing campaigns, guessing release dates, changing eligibility policies or claiming beta automatically authorizes launch.

## Test plan

**Automated (test-first):**
- `test_beta_vs_public_install_sources_not_double_counted`
- `test_rolling_48h_uses_build_and_platform_filters`
- `test_p0_incident_blocks_rollout_recommendation`
- `test_missing_store_source_flagged_manual_not_zero`

**Manual:**
1. Run a tabletop staged rollout with one store still in review and Crashlytics unavailable. Expected: the rollout is shown blocked/unknown with source links, and no store publish or rollback action executes.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
