## Context
Even small apps need a plan for incidents (data deletion bugs, notification storms, etc.).

## Goal
Create an incident runbook that includes privacy and security scenarios.

## Expected behavior
- Team can respond quickly with defined roles and steps
- Postmortems are captured

## Acceptance criteria (Definition of Done)
- [ ] Create `docs/ops/incident.md` with severity levels, comms templates, and rollback strategy
- [ ] Include privacy scenarios: accidental data exposure, telemetry bug, auth token leak
- [ ] Include postmortem template and timeline
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Formal ISO/SOC program.

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
