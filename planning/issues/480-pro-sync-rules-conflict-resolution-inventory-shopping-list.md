## Context
Multi-device sync requires clear conflict resolution to maintain trust.

## Goal
Define and implement conflict rules for edits and deletes.

## Expected behavior
- Concurrent edits do not corrupt data
- User-visible outcomes are predictable

## Acceptance criteria (Definition of Done)
- [ ] Define sync strategy (last-write-wins + event log preferred) and document in `docs/pro/sync.md`
- [ ] Implement conflict handling for item edits, mark-used/wasted, and deletions
- [ ] Implement optimistic UI with retry/backoff
- [ ] Add integration tests for conflict scenarios
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full offline multi-master CRDT system (unless needed).

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
