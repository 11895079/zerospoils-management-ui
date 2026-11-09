# WI-0015: Integrate existing live-worker monitoring into launch operations

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P1`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0008`
- Linked Issue: [#8](https://github.com/11895079/zerospoils-management-ui/issues/8)

## Context

Existing management UI issue #8 and ZeroSpoils M6/1111 already contain the detailed local worker heartbeat, event history, queue and GitHub label design. This workitem references them, avoiding a second competing worker monitor spec.

## Goal / user outcome

As a ZeroSpoils launch operator, I can integrate existing live-worker monitoring into launch operations with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Implement existing issue #8 in this React/Express app; mount worker status.json and metrics/units.jsonl read-only, poll safely and explain clean idle vs crashed worker.
- Show active work item, provider, phase, lease, throttled/rested reason, latest drain/wake and direct PR/CI links alongside beta blockers.
- Never expose credentials, full prompts, raw agent logs or repo contents; no pause/retry/override controls in this view.
- Reuse the planned M6/1107 append-only metrics for comparisons and M6/1106 multi-node sources only after they are implemented; no K8s dependency for local worker health.
- Keep launch reporting resilient if the worker process, Docker mount or GitHub is offline.

## Acceptance criteria

- [ ] Implement existing issue #8 in this React/Express app; mount worker status.json and metrics/units.jsonl read-only, poll safely and explain clean idle vs crashed worker.
- [ ] Show active work item, provider, phase, lease, throttled/rested reason, latest drain/wake and direct PR/CI links alongside beta blockers.
- [ ] Never expose credentials, full prompts, raw agent logs or repo contents; no pause/retry/override controls in this view.
- [ ] Reuse the planned M6/1107 append-only metrics for comparisons and M6/1106 multi-node sources only after they are implemented; no K8s dependency for local worker health.
- [ ] Keep launch reporting resilient if the worker process, Docker mount or GitHub is offline.

## Out of scope

No separate worker service, forced Kubernetes migration, general-purpose log streaming or privileged worker dispatch.

## Test plan

**Automated (test-first):**
- `test_worker_heartbeat_fresh_late_idle_down`
- `test_jsonl_reader_respects_partial_lines_and_rotation`
- `test_readonly_mount_and_no_worker_mutation`
- `test_github_label_state_and_local_status_reconcile`

**Manual:**
1. Use fixture worker status in the management UI and simulate a stopped worker during an active unit. Expected: the page transitions from active to late/down with last-seen evidence while normal clean idle is not falsely alarmed.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative launch fixtures.
- [ ] Docs and runbook links updated; implementation PR reviewed and merged by owner.
