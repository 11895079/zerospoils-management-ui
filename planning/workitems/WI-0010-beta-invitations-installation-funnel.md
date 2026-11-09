# WI-0010: Track invitation, distribution and installation funnel by cohort

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P1`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0007`, `WI-0009`
- Linked Issue: [#13](https://github.com/11895079/zerospoils-management-ui/issues/13)

## Context

ZeroSpoils runs invited beta waves via Loops with TestFlight for iOS and Firebase App Distribution for Android, with /beta and WhatsApp/Telegram as contextual channels. These tools count different events and cannot be treated as one trusted identifier.

## Goal / user outcome

As a ZeroSpoils launch operator, I can track invitation, distribution and installation funnel by cohort with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Model audience, campaign, wave, platform, build, channel and consent-safe source tags; report Loops sent/delivered/bounced/unsubscribed/clicked separately from TestFlight/Firebase invited/accepted/installed counts.
- Support read-only source APIs or owner-verified CSV/manual evidence; label attribution as observed, estimated or unavailable; no fabricated join between a marketing email and an anonymous app install.
- Show invite-to-install funnel and friction by platform with explicit cohort and date windows; link /beta documentation and source-verified delivery status.
- Surface stale links, distribution readiness, external beta review and tester-group caps as manual owner checklist entries with evidence.
- Preserve marketing consent/unsubscribe compliance and small-cohort suppression.

## Acceptance criteria

- [ ] Model audience, campaign, wave, platform, build, channel and consent-safe source tags; report Loops sent/delivered/bounced/unsubscribed/clicked separately from TestFlight/Firebase invited/accepted/installed counts.
- [ ] Support read-only source APIs or owner-verified CSV/manual evidence; label attribution as observed, estimated or unavailable; no fabricated join between a marketing email and an anonymous app install.
- [ ] Show invite-to-install funnel and friction by platform with explicit cohort and date windows; link /beta documentation and source-verified delivery status.
- [ ] Surface stale links, distribution readiness, external beta review and tester-group caps as manual owner checklist entries with evidence.
- [ ] Preserve marketing consent/unsubscribe compliance and small-cohort suppression.

## Out of scope

No automated Loops campaign sends, scraped tester email, guessed acquisition attribution or direct access to Apple's/Firebase's unapproved APIs.

## Test plan

**Automated (test-first):**
- `test_no_cross_provider_funnel_join_without_identity_contract`
- `test_invite_denominator_excludes_bounced_when_configured`
- `test_missing_distribution_api_shows_manual_evidence`
- `test_optout_email_never_exported_in_dashboard`

**Manual:**
1. Reconcile a fixture Loops campaign and platform tester CSV to the displayed funnel. Expected: the page shows source-specific counts and explicitly unknown conversion where joining identities is not permitted.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
