## Context
We want repeatable artifacts for QA/beta testing and later store releases. GitHub Actions can build Android/iOS artifacts on tag push to ensure version consistency.

## Goal
Create CI workflows that build Android APK/AAB and iOS IPA artifacts when tagging releases, with artifacts uploaded to GitHub Actions for download.

## Expected behavior
- Pushing a tag like `v0.1.0-beta.1` triggers both Android and iOS build workflows
- Android workflow produces APK (for direct install) and AAB (for Play Store)
- iOS workflow produces an IPA archive (requires macOS runner)
- Artifacts are uploaded and accessible from GitHub Actions UI
- Version number in `pubspec.yaml` matches the tag

## Acceptance criteria (Definition of Done)
- [ ] `.github/workflows/build-android.yml` workflow exists and triggers on tag push
- [ ] `.github/workflows/build-ios.yml` workflow exists and triggers on tag push
- [ ] Android workflow builds release APK and AAB, uploads as artifacts
- [ ] iOS workflow builds release IPA (ad-hoc or enterprise), uploads as artifact
- [ ] Versioning strategy documented in `docs/release.md` (semver, tag format, changelog)
- [ ] Workflows handle signing (Android keystore in secrets, iOS provisioning profiles)
- [ ] README updated with release/tagging instructions

## Out of scope
- Store submission automation (fastlane upload to Play Store/App Store Connect deferred to M4)
- TestFlight/Play Store beta distribution automation (M3)
- Code signing certificate generation (manual setup, document in `docs/release.md`)
- Automated changelog generation (M3)
- Multi-flavor builds (dev/staging/prod) (M3)

## Implementation notes
- **Android signing:** Store keystore in GitHub Secrets as base64, decode in workflow
- **iOS signing:** Use macOS runner (`macos-latest`), store provisioning profiles + certificate in secrets
- **Tag format:** `v<major>.<minor>.<patch>[-beta.<n>]` (e.g., `v0.1.0-beta.1`, `v1.0.0`)
- **Version bump:** Update `pubspec.yaml` version before tagging
- **Workflow triggers:** `on: push: tags: ['v*']`
- Use `actions/upload-artifact@v3` to store APK/AAB/IPA
- Consider caching Flutter SDK and dependencies to speed up builds

## Test plan
**Automated:**
- Workflow validation: Use `act` (local GitHub Actions runner) to test workflow syntax
- Dry-run: Test workflow with a test tag without publishing

**Manual:**
1. Update `pubspec.yaml` version to `0.1.0-beta.1` → commit → push to main
2. Create and push tag: `git tag v0.1.0-beta.1 && git push origin v0.1.0-beta.1`
3. Verify Android workflow triggers and completes successfully (check Actions tab)
4. Download APK artifact from GitHub Actions → install on Android device → verify app launches
5. Download AAB artifact → upload to Play Store internal testing track → verify integrity
6. Verify iOS workflow triggers and completes successfully (macOS runner)
7. Download IPA artifact from GitHub Actions → install on iOS device via TestFlight or ad-hoc → verify app launches
8. Test version mismatch: Push tag without updating `pubspec.yaml` → verify workflow fails with clear error
9. Test invalid tag format: Push `release-1.0` → verify workflow doesn't trigger (only `v*` tags)

## Dependencies
- None (can be done independently)
