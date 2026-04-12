## Context
Closed iOS testing needs to be repeatable and easy to run for every beta cut. The milestone already calls for TestFlight, but the work item does not yet define artifact rules, build numbering, tester onboarding, or a consistent smoke-test process.

## Goal
Enable internal TestFlight distribution with a repeatable release-note, tester-onboarding, and release-validation workflow.

## Expected behavior
- CI or a documented release path can produce an archive suitable for TestFlight upload
- App version and build number follow a documented convention so tester feedback can be tied back to a specific build
- Release notes are captured per beta cut and linked to the milestone or issue scope included in that build
- Internal testers receive clear install instructions, known-risk areas, and feedback guidance
- TestFlight builds are validated on at least one physical iPhone before broader tester rollout

## Acceptance criteria (Definition of Done)
- [ ] Document the iOS beta workflow in `docs/beta-ios.md`, including prerequisites, archive/upload steps, tester invite flow, and rollback notes
- [ ] CI or a documented release automation path produces an iOS archive or IPA suitable for TestFlight distribution
- [ ] Versioning strategy is defined and implemented for beta app versions and build numbers
- [ ] Release-notes template exists and is used for each beta build
- [ ] Tester instructions include install steps, supported-device expectations, known-risk areas, and how to submit feedback
- [ ] Smoke-test checklist exists for install, launch, sign-in, add-item, shopping, OCR entry points, and feedback entry
- [ ] TestFlight build is verified for crash visibility and telemetry bootstrap in non-debug mode
- [ ] Unit/widget/integration tests added or updated where build or release tooling changes require coverage
- [ ] Telemetry added or updated to identify beta-build context where applicable
- [ ] Offline-first behavior verified for the MVP flows exercised during beta
- [ ] Accessibility basics validated on the beta path for the high-traffic flows under test

## Out of scope
- Public App Store submission or App Review packaging
- External/public TestFlight campaigns
- Android Firebase App Distribution feedback automation
- Store-listing asset generation

## Implementation notes
- Keep this issue focused on iOS beta operations and release hygiene rather than new end-user features
- Prefer a simple build-numbering convention tied to CI run number or timestamp so testers can reference builds unambiguously
- Reuse the shared feedback entry point from M4/280 and M4/285 rather than inventing an iOS-only feedback channel
- Capture release-note sections consistently: included scope, known issues, upgrade notes, and explicit tester asks

## Test plan
**Automated:**
- CI validation: beta workflow produces a signed iOS archive or IPA artifact with expected version/build metadata
- Release-note/template validation: generated artifact names and release-note references follow the documented versioning convention
- Existing critical-path widget and integration tests remain green on the same commit used for TestFlight upload

**Manual:**
1. Produce an iOS beta build and verify the artifact is acceptable for TestFlight upload
2. Upload the build to TestFlight and confirm internal testers can see the new version and release notes
3. Install the build on at least one physical iPhone and verify launch, sign-in, add-item, shopping, OCR entry points, and feedback entry
4. Confirm crash reporting and telemetry bootstrap work in the beta build without debug-only tooling
5. Share tester instructions and verify a tester can install and use the build without direct developer hand-holding
6. Repeat the process for a second beta cut and verify numbering and release notes remain consistent

## Dependencies
- M2/030 iOS build pipeline foundation
- M4/280 in-app feedback entry point
- M4/285 settings feedback entry
- M4/290 crash reporting and basic performance monitoring
