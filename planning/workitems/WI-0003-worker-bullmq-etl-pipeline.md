# WI-0003: Worker BullMQ ETL Pipeline

## Metadata

- Status: `in-progress`
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

- [x] Jobs can be enqueued, processed, retried, and observed
- [x] Worker health endpoint reflects real queue state
- [x] Failed jobs are recoverable with clear diagnostics

## Definition of Done

- [x] Code implemented
- [x] Tests added/updated
- [x] Docs updated
- [ ] Merged to main
