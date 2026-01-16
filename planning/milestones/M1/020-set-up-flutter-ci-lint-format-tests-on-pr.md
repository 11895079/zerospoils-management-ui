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
**Automated:**
- Verify `.github/workflows/ci.yml` exists and contains required jobs
- Parse workflow file to confirm `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed` are present

**Manual:**
1. Create PR with intentional lint error (should fail CI)
2. Create PR with failing test (should block merge)
3. Create PR with formatting issues (should fail CI)
4. Create clean PR (should pass and allow merge)
5. Verify CI logs and artifacts are accessible in Actions tab

## Dependencies
- None