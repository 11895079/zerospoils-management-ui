# WI-0018: Analyze real retention, food-waste outcomes and feature value by cohort

## Metadata

- Status: `todo`
- Milestone: `M5`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P1`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0011`
- Linked Issue: [#20](https://github.com/11895079/zerospoils-management-ui/issues/20)

## Context

ZeroSpoils's purpose is food-waste reduction. Feature engagement and D1/D7 alone are not proof that households saved food. Product metrics need honest outcome definitions and cohort eligibility, while offline-only usage is not necessarily visible.

## Goal / user outcome

As a ZeroSpoils launch operator, I can analyze real retention, food-waste outcomes and feature value by cohort with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Provide D1/D7/W4 return and weekly meaningful-action cohorts with age eligibility, build/wave/platform segments, opt-out caveats, D7 confidence notes and no re-identification.
- Create a food-outcome measurement model: items consumed before expiry, discarded, rescued, reminders acted upon, waste baseline where collected, and optional self-reported savings; separate observed counts from modelled estimates.
- Examine funnels for first value: dated inventory, location setup, shopping list, receipt review/OCR, reminders, backup/restore, tour, product info and recipe suggestions only when feature launched/instrumented.
- Support feature release/flag dates to avoid treating unlaunched Pro, household sync, food-quality, donations, price suggestions and advanced analytics as failed zero-use products.
- Compare cohorts with repeatability and denominator rules; record hypotheses, accepted experiment windows and before/after limitations instead of causal claims from correlation.

## Acceptance criteria

- [ ] Provide D1/D7/W4 return and weekly meaningful-action cohorts with age eligibility, build/wave/platform segments, opt-out caveats, D7 confidence notes and no re-identification.
- [ ] Create a food-outcome measurement model: items consumed before expiry, discarded, rescued, reminders acted upon, waste baseline where collected, and optional self-reported savings; separate observed counts from modelled estimates.
- [ ] Examine funnels for first value: dated inventory, location setup, shopping list, receipt review/OCR, reminders, backup/restore, tour, product info and recipe suggestions only when feature launched/instrumented.
- [ ] Support feature release/flag dates to avoid treating unlaunched Pro, household sync, food-quality, donations, price suggestions and advanced analytics as failed zero-use products.
- [ ] Compare cohorts with repeatability and denominator rules; record hypotheses, accepted experiment windows and before/after limitations instead of causal claims from correlation.

## Out of scope

No household-level surveillance, uploading food lists without permission, invented dollars saved, model-driven health/food safety advice or causal A/B claims without actual experimental design.

## Test plan

**Automated (test-first):**
- `test_d7_excludes_age_ineligible_cohorts`
- `test_consumed_is_not_same_as_saved_without_baseline`
- `test_feature_flag_and_instrumentation_coverage_matrix`
- `test_offline_optout_cohort_not_counted_as_zero`

**Manual:**
1. Compare synthetic cohorts with reminders and consumption events but no baseline and one partially instrumented feature. Expected: the report shows observed uses, marks savings unproven and the partial feature measurement incomplete.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
