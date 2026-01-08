## Context
We need repeatable quality checks before merging.

## Goal
Create a CI workflow that runs on PRs and blocks merges on failure.

## Expected behavior
- PRs run static analysis + formatting + unit tests
- Artifacts/logs visible in Actions

## Acceptance criteria (Definition of Done)
- [ ] GitHub Actions workflow runs `flutter analyze`, `flutter test` and formatting checks
- [ ] CI caches dependencies
- [ ] CI runs on pull_request and push to main
- [ ] Status check is required for merge
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Release builds/signing (separate issue).

## Implementation notes
- Use stable Flutter.
- Add `dart format --set-exit-if-changed`.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
