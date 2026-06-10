# WI-0003: Worker BullMQ ETL Pipeline

## Metadata

- Status: `todo`
- Milestone: `M1`
- Owner: `unassigned`
- Priority: `P1`
- Target Date: `2026-07-04`
- Dependencies: `WI-0002`
- Linked Issue: `690`

## Context

Worker service currently exposes stub endpoints without real queue processing.

## Scope

- In scope:
  - Add BullMQ queues and processors
  - Implement retries, dead-letter strategy, and health reporting
  - Produce ETL outputs consumed by analytics marts
- Out of scope:
  - Distributed scheduling across multiple worker nodes

## Acceptance Criteria

- [ ] Jobs can be enqueued, processed, retried, and observed
- [ ] Worker health endpoint reflects real queue state
- [ ] Failed jobs are recoverable with clear diagnostics

## Definition of Done

- [ ] Code implemented
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Merged to main
