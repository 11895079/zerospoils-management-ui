# WI-0016: Visualize optional MAF shadow-review evaluations and QA comparison

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P2`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0008`, `WI-0009`
- Linked Issue: [#18](https://github.com/11895079/zerospoils-management-ui/issues/18)

## Context

ZeroSpoils #1340 plans an event-driven, optional read-only MAF shadow review pilot. A UI must show its results without treating a shadow model score as an authoritative code-review approval.

## Goal / user outcome

As a ZeroSpoils launch operator, I can visualize optional MAF shadow-review evaluations and QA comparison with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Define read-only MAF evaluation event schema keyed by repo, PR, head SHA and evaluator version: result, evidence file/line, reference QA comparison, model/provider, elapsed time, usage/cost estimate, errors and source timestamp.
- Add an Automation > MAF Evaluations page with baseline vs shadow findings (confirmed defects, false positives, human correction effort, retries and per-review cost where observed).
- Show state disabled, waiting, no-run, running, completed, failed, budget-capped and stale separately; never imply a failed/absent MAF run blocks the current QA lane.
- Permit only authorized project-local sanitized findings; deny prompts, model secrets and protected diff content to unauthorized roles.
- Document the owner GO/ADJUST/STOP decision with external tracker links and hard security tests; keep MAF implementation in ZeroSpoils #1340 and UI in this repo.

## Acceptance criteria

- [ ] Define read-only MAF evaluation event schema keyed by repo, PR, head SHA and evaluator version: result, evidence file/line, reference QA comparison, model/provider, elapsed time, usage/cost estimate, errors and source timestamp.
- [ ] Add an Automation > MAF Evaluations page with baseline vs shadow findings (confirmed defects, false positives, human correction effort, retries and per-review cost where observed).
- [ ] Show state disabled, waiting, no-run, running, completed, failed, budget-capped and stale separately; never imply a failed/absent MAF run blocks the current QA lane.
- [ ] Permit only authorized project-local sanitized findings; deny prompts, model secrets and protected diff content to unauthorized roles.
- [ ] Document the owner GO/ADJUST/STOP decision with external tracker links and hard security tests; keep MAF implementation in ZeroSpoils #1340 and UI in this repo.

## Out of scope

No running MAF agents in the management UI, mutation of PRs/labels/approvals, automatic fixes, new Kubernetes runtime or treating LLM judgements as security gates.

## Test plan

**Automated (test-first):**
- `test_maf_disabled_does_not_block_existing_review`
- `test_maf_report_dedupes_pr_head_and_version`
- `test_false_positive_counts_require_verified_labels`
- `test_unauthorized_prompts_and_review_content_redacted`

**Manual:**
1. Open the view with fixture PRs containing a confirmed false positive, a valid bug and an unavailable MAF provider. Expected: the baseline remains authoritative, the unavailable run is nonblocking and counts/costs come from explicit evidence.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
