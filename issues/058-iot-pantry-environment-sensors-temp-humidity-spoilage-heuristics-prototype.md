## Context
Sensor data can enrich expiry predictions for premium users.

## Goal
Prototype ingesting temp/humidity readings to adjust recommendations.

## Expected behavior
- User can link a sensor source
- App shows a simple heuristic (not ML)

## Acceptance criteria (Definition of Done)
- [ ] Define sensor ingestion format (HA sensor entity → webhook) and retention policy
- [ ] Implement heuristic rules (e.g., elevated risk when warm/humid)
- [ ] Add UI indication and explanation of heuristic
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- ML model training.

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
