# WI-0019: Report consented acquisition, referral and Pro monetization when available

## Metadata

- Status: `todo`
- Milestone: `M5`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P2`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0010`, `WI-0018`
- Linked Issue: [#21](https://github.com/11895079/zerospoils-management-ui/issues/21)

## Context

The public launch starts free; referral incentives, subscriptions, Pro household sync/advanced analytics, partnerships and paid marketing are planned or conditional. The management UI should anticipate commercial measures without presenting deferred capabilities as launched revenue.

## Goal / user outcome

As a ZeroSpoils launch operator, I can report consented acquisition, referral and Pro monetization when available with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Report verified waitlist/source/channel attribution, complaint/unsubscribe rates, invite/referral conversion and consented quote counts from Loops/other approved sources.
- Create dormant or clearly marked unsupported entitlement/subscription/payment KPI adapters for future Pro rollout, with store/provider receipts and net revenue definitions before activation.
- Show activation-to-retention-to-referral funnel and cohort LTV/CAC only when source data is real and attribution is valid; never infer billing events from feature-flag exposure.
- Allow owner-approved feature-launch date and reporting coverage labels for future food-quality, recommendations, household sync, sponsorships and paid acquisition.
- Track experiment and spending budgets, data consent, aggregate suppression and manual review before publishing any financial or public marketing claim.

## Acceptance criteria

- [ ] Report verified waitlist/source/channel attribution, complaint/unsubscribe rates, invite/referral conversion and consented quote counts from Loops/other approved sources.
- [ ] Create dormant or clearly marked unsupported entitlement/subscription/payment KPI adapters for future Pro rollout, with store/provider receipts and net revenue definitions before activation.
- [ ] Show activation-to-retention-to-referral funnel and cohort LTV/CAC only when source data is real and attribution is valid; never infer billing events from feature-flag exposure.
- [ ] Allow owner-approved feature-launch date and reporting coverage labels for future food-quality, recommendations, household sync, sponsorships and paid acquisition.
- [ ] Track experiment and spending budgets, data consent, aggregate suppression and manual review before publishing any financial or public marketing claim.

## Out of scope

No app billing changes, purchase approvals, marketing emails, ad campaigns, commercial contracts, made-up savings or external customer segmentation.

## Test plan

**Automated (test-first):**
- `test_pro_revenue_unavailable_when_no_billing_source`
- `test_referral_counts_require_attribution_event`
- `test_unsubscribed_contact_excluded_from_outreach_report`
- `test_forecast_labelled_estimate_with_assumptions`

**Manual:**
1. Open the growth view with free-only launch data and no subscription receipts. Expected: reported actual revenue remains unknown/not applicable rather than a fabricated amount, while consented acquisition metrics show their proper sources.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
