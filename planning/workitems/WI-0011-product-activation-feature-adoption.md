# WI-0011: Report activation, reminders, inventory, shopping, receipts and backup journeys

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P1`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0007`, `WI-0009`
- Linked Issue: [#14](https://github.com/11895079/zerospoils-management-ui/issues/14)

## Context

The product's offline-first core has onboarding, inventory/expiry and use/discard, shopping list, reminders, receipts/OCR and backup, plus guided tour, streaks, food insights and planned features. Reporting needs to show instrumented user journeys without inventing cloud activity from device-local state.

## Goal / user outcome

As a ZeroSpoils launch operator, I can report activation, reminders, inventory, shopping, receipts and backup journeys with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- For each released capability map a specific allowed event and denominator to the metric registry: install/session, onboarding completion, first item in 24h, five dated items in 3d, reminder schedule/open/permission gap, shopping list engagement, receipt capture/OCR review, backup success/restore failure, use/discard actions, tour and tips.
- Render an explicit feature coverage matrix: released+instrumented, released+partial, released+unmeasurable, planned/not active; distinguish local-only data from telemetry export.
- Segment safely by wave/build/platform and feature flag, with age-eligible cohorts and no small-bucket identification.
- Show drop-off, reliability/errors and review backlog for OCR and backup; open source/PR/feedback references rather than new intrusive tracking.
- Maintain a separate future-ready category for food-quality product info, recipes, donation, household sync and optional Pro features; mark as deferred until evidence exists.

## Acceptance criteria

- [ ] For each released capability map a specific allowed event and denominator to the metric registry: install/session, onboarding completion, first item in 24h, five dated items in 3d, reminder schedule/open/permission gap, shopping list engagement, receipt capture/OCR review, backup success/restore failure, use/discard actions, tour and tips.
- [ ] Render an explicit feature coverage matrix: released+instrumented, released+partial, released+unmeasurable, planned/not active; distinguish local-only data from telemetry export.
- [ ] Segment safely by wave/build/platform and feature flag, with age-eligible cohorts and no small-bucket identification.
- [ ] Show drop-off, reliability/errors and review backlog for OCR and backup; open source/PR/feedback references rather than new intrusive tracking.
- [ ] Maintain a separate future-ready category for food-quality product info, recipes, donation, household sync and optional Pro features; mark as deferred until evidence exists.

## Out of scope

No new app analytics SDK or user-level session playback, no receipt contents or household inventory upload, no invented food-savings values.

## Test plan

**Automated (test-first):**
- `test_feature_matrix_does_not_count_unreleased_as_zero`
- `test_first_item_cohort_window_and_deduplication`
- `test_backup_failure_and_ocr_partial_events_not_success`
- `test_optout_prevents_sensitive_user_journey_display`

**Manual:**
1. Compare one consented fixture tester with onboarded/item-added/reminder events and another offline-only session. Expected: only evidenced funnel steps count, the offline session is labelled unobserved rather than abandoned, and planned features are not shown as launched.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
