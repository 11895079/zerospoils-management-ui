## Context
We need a controlled beta channel on iOS.

## Goal
Enable internal TestFlight distribution with a repeatable release note process.

## Expected behavior
- Build can be uploaded to TestFlight
- Release notes captured per tag/build

## Acceptance criteria (Definition of Done)
- [ ] Document steps in `docs/beta-ios.md`
- [ ] CI produces iOS archive suitable for upload
- [ ] Versioning strategy implemented
- [ ] Tester instructions included
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Not defined

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
