```markdown
## Context
We want repeatable artifacts for QA/beta and later store releases.

## Goal
Create CI jobs that build artifacts when tagging releases.

## Expected behavior
- Tag triggers Android build artifact
- Tag triggers iOS archive artifact (macOS runner)

## Acceptance criteria (Definition of Done)
- [ ] Workflow builds Android APK/AAB and uploads artifact
- [ ] Workflow builds iOS archive and uploads artifact
- [ ] Versioning strategy documented in `docs/release.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Store submission automation.

## Implementation notes
- Keep signing material in secrets.
- Use macOS runners for iOS.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None

```
## Context
We want repeatable artifacts for QA/beta and later store releases.

## Goal
Create CI jobs that build artifacts when tagging releases.

## Expected behavior
- Tag triggers Android build artifact
- Tag triggers iOS archive artifact (macOS runner)

## Acceptance criteria (Definition of Done)
- [ ] Workflow builds Android APK/AAB and uploads artifact
- [ ] Workflow builds iOS archive and uploads artifact
- [ ] Versioning strategy documented in `docs/release.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Store submission automation.

## Implementation notes
- Keep signing material in secrets.
- Use macOS runners for iOS.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
