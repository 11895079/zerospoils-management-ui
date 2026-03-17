## Context
We want repeatable artifacts for QA/beta testing and later store releases. GitHub Actions can build Android/iOS artifacts on tag push to ensure version consistency.

## Goal
Create CI workflows that build Android APK/AAB and iOS IPA artifacts when tagging releases, with artifacts uploaded to GitHub Actions for download.

## Current delivery split (Mar 2026)
- **Track A (unblocked now): Android release CI completion**
	- Finish signed APK + AAB generation and artifact upload on tag pushes.
	- Validate keystore secret decoding and release signing in CI.
- **Track B (blocked): iOS release CI completion**
	- Requires active Apple Developer Program enrollment and valid distribution assets.
	- Keep workflow scaffolding in place, then finalize signing and IPA distribution once enrollment is active.

## Expected behavior
- Pushing a tag like `v0.1.0-beta.1` triggers both Android and iOS build workflows
- Android workflow produces APK (for direct install) and AAB (for Play Store)
- iOS workflow produces an IPA archive (requires macOS runner)
- Artifacts are uploaded and accessible from GitHub Actions UI
- Version number in `pubspec.yaml` matches the tag

## Acceptance criteria (Definition of Done)
- [x] `.github/workflows/build-android.yml` workflow exists and triggers on tag push
- [x] `.github/workflows/build-ios.yml` workflow exists and triggers on tag push
- [ ] **Track A / Android (execute now):** workflow builds signed release APK and AAB, uploads both artifacts
- [ ] **Track A / Android (execute now):** keystore secret decode + signing step validated end-to-end on tag build
- [ ] **Track A / Android (execute now):** workflow fails fast on tag/version mismatch with clear error
- [ ] **Track B / iOS (blocked until Apple enrollment):** workflow builds signed IPA (ad-hoc or enterprise), uploads artifact
- [ ] **Track B / iOS (blocked until Apple enrollment):** provisioning profile + certificate secret handling validated end-to-end
- [ ] Versioning strategy documented in `docs/release.md` (semver, tag format, changelog)
- [ ] README updated with release/tagging instructions (Android now; iOS addendum when unblocked)

## Out of scope
- Store submission automation (fastlane upload to Play Store/App Store Connect deferred to M4)
- TestFlight/Play Store beta distribution automation (M3)
- Code signing certificate generation (manual setup, document in `docs/release.md`)
- Automated changelog generation (M3)
- Multi-flavor builds (dev/staging/prod) (M3)

## Blockers
- iOS release artifact validation is blocked by Apple Developer Program enrollment and distribution signing assets.
- Android release CI completion is not blocked and should be shipped first.

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
- Workflow syntax validation for both `build-android.yml` and `build-ios.yml`
- Android tag run validates: APK + AAB artifacts present, signing step executed, and tag/version guard works
- iOS validation queued until Apple enrollment and signing assets are available

**Manual:**
1. Update `pubspec.yaml` version to `0.1.0-beta.1` → commit → push to main
2. Create and push tag: `git tag v0.1.0-beta.1 && git push origin v0.1.0-beta.1`
3. Verify Android workflow triggers and completes successfully (check Actions tab)
4. Download APK artifact from GitHub Actions → install on Android device → verify app launches
5. Download AAB artifact → upload to Play Store internal testing track → verify integrity
6. Test version mismatch: Push tag without updating `pubspec.yaml` → verify workflow fails with clear error
7. Test invalid tag format: Push `release-1.0` → verify workflow doesn't trigger (only `v*` tags)
8. After Apple enrollment is active, run iOS workflow validation on tag
9. Download IPA artifact → validate install via Firebase App Distribution/TestFlight

## Dependencies
- None (can be done independently)
