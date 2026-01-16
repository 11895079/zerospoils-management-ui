## Context
Low-cost IoT can start with labels: scan and update inventory quickly.

## Goal
Prototype NFC/QR labels that deep-link into a pre-filled item screen.

## Expected behavior
- Scanning opens ZeroSpoils to the right item (or add flow)
- User can update qty/expiry quickly

## Acceptance criteria (Definition of Done)
- [ ] Define label payload strategy (opaque ID vs encoded data)
- [ ] Implement deep link handling for item IDs
- [ ] Provide printable QR template and instructions in `docs/iot/nfc-qr.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Hardware manufacturing.

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
