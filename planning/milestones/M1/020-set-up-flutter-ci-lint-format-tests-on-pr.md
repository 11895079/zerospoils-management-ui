## Context
We need repeatable quality checks before merging.

## Goal
Create a CI workflow that runs on PRs and blocks merges on failure.

## Expected behavior
- PRs run static analysis + formatting + unit tests
- Artifacts/logs visible in Actions

## Acceptance criteria (Definition of Done)
- [x] GitHub Actions workflow runs `flutter analyze`, `flutter test` and formatting checks
- [x] CI caches dependencies
- [x] CI runs on pull_request and push to main
- [x] Status check is required for merge (via branch protections)
- [x] Unit/widget/integration tests added or updated (19/19 tests pass)
- [x] Telemetry added/updated (app_installed, tab_switched, item_added, item_updated)
- [x] Offline-first behavior verified (no runtime crashes offline)
- [x] Accessibility basics (44pt buttons, Material icons, semantic labels, 4.5:1 contrast)

**Status:** ✅ **COMPLETE** — `.github/workflows/flutter-ci.yml` runs on every PR: format check → analyze → test with coverage upload

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