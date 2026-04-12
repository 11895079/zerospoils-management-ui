## Context
Android closed testing is partially underway, but the work item still lacks concrete artifact requirements, tester-group workflow, and a repeatable release-validation path.

## Goal
Enable Google Play internal or closed testing with repeatable upload, tester-group management, and release-validation steps for Android beta builds.

## Expected behavior
- CI or a documented release path can produce a release AAB suitable for Google Play internal or closed testing
- Tester groups and invite flow are documented so they can be managed without ad hoc console work
- Android beta release notes and smoke-test checklist are attached to each beta cut
- Beta validation covers install/update, launch, sign-in, add-item, OCR entry points, shopping, and feedback access
- Crash visibility, Remote Config bootstrap, and release hardening remain intact in beta builds

## Acceptance criteria (Definition of Done)
- [ ] Document the Android beta workflow in `docs/beta-android.md`, including Play Console steps, tester groups, rollout/rollback notes, and common failure modes
- [ ] CI or a documented release automation path produces a signed AAB suitable for Play internal or closed testing
- [ ] Tester-group setup and invite instructions are defined for at least one internal cohort
- [ ] Release checklist includes version code/name validation, signing verification, release-note attachment, and smoke-test coverage
- [ ] Smoke-test checklist exists for install, update, auth, add-item, packaged-item scan, expiry scan, shopping, and feedback entry
- [ ] Beta build is verified for Crashlytics, Remote Config, and release-hardening behavior in non-debug mode
- [ ] Unit/widget/integration tests added or updated where build or release tooling changes require coverage
- [ ] Telemetry added or updated to identify beta-build context where applicable
- [ ] Offline-first behavior verified for the MVP flows exercised during closed testing
- [ ] Accessibility basics validated on the beta path for the high-traffic flows under test

## Out of scope
- Public Play production rollout
- Firebase App Distribution tester feedback retrieval and screenshot triage workflow
- Store-listing copy and launch assets

## Implementation notes
- Keep this issue focused on Play distribution readiness and tester operations, not end-user feature development
- Align the Android smoke-test checklist with the iOS beta checklist where practical so feedback is comparable across platforms
- Reuse the shared feedback entry point from M4/280 and M4/285
- Keep Android release validation aligned with M4/370 hardening requirements so beta builds resemble launch conditions

## Test plan
**Automated:**
- CI validation: beta workflow produces a signed AAB artifact with expected version metadata
- Existing critical-path widget and integration tests remain green on the same commit used for Play upload
- Release validation checks confirm required signing and release config are present for beta builds

**Manual:**
1. Produce an Android beta AAB and confirm it uploads successfully to Play internal or closed testing
2. Add or verify a tester group, then confirm a tester can accept the invite and install the build
3. Install the build on a physical Android device and verify launch, sign-in, add-item, packaged-item scan, expiry scan, shopping, and settings feedback flow
4. Update from one beta build to the next and verify the upgrade path works without data loss
5. Confirm Crashlytics, Remote Config, and hardened release behavior remain active in the beta build
6. Verify release notes and tester instructions are attached and understandable without direct developer support

## Dependencies
- M2/030 Android build pipeline foundation
- M4/280 in-app feedback entry point
- M4/285 settings feedback entry
- M4/370 closed-testing backend security hardening
