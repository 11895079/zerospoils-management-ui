# Mobile Release Cycle Runbook (iOS + Android)

## Purpose

This runbook defines a cost-aware, repeatable develop-build-release cycle for:

- iOS TestFlight distribution via Xcode Cloud (Apple-managed signing)
- Android Firebase App Distribution (fast beta loops)
- Android Google Play Internal Testing (store-like validation)

It is designed to:

- Avoid running iOS cloud builds on every merge to main
- Keep iOS release triggers aligned to your git tag strategy
- Reduce GitHub macOS runner usage and cost
- Keep Linux PR checks in GitHub Actions for fast feedback

---

## Target CI/CD Split

### GitHub Actions owns

- Pull request quality gates (format, analyze, test)
- Android release artifact generation and distribution
- Tag governance and release bookkeeping

### Xcode Cloud owns

- iOS archive/sign/upload pipeline for TestFlight
- Apple capability/signing validation (entitlements, profiles, team)

---

## Release Channels

| Channel | Platform | Trigger Type | Audience | Frequency |
|---|---|---|---|---|
| PR Validation | iOS + Android code checks | PR to main/develop | Engineering | Every PR |
| Beta Android (Firebase) | Android APK | Tag `vX.Y.Z-bN` | Internal + trusted beta | Frequent |
| Beta Android (Play Internal) | Android AAB | Tag `vX.Y.Z-bN` | Internal Play testers | Frequent |
| Beta iOS (TestFlight) | iOS archive/upload | Custom iOS trigger branch + tag guard | Internal + TestFlight testers | Frequent |
| Production | iOS + Android | Stable tag `vX.Y.Z` | Public users | Controlled |

---

## Tagging Strategy (Single Source of Truth)

Use these tag formats consistently:

- Beta: `vMAJOR.MINOR.PATCH-bBUILD`
- Stable: `vMAJOR.MINOR.PATCH`

Examples:

- `v0.3.0-b12`
- `v0.3.0`

Version alignment rule:

- `app/pubspec.yaml` version (without leading `v`) must match the tag semantic part.
- Build number after `+` must be incremented per build.

Example:

- Tag: `v0.3.0-b12`
- `pubspec.yaml`: `0.3.0-b12+45`

---

## iOS Custom Trigger Model (No auto-run on main)

## Why this model

Xcode Cloud does not need to run on every merge. You want intentional iOS releases that are tied to tags.

## Mechanism

1. Keep normal development on `main`.
2. Create a beta/stable tag on the chosen commit.
3. Move a dedicated trigger branch (example: `release/ios`) to that tagged commit.
4. Xcode Cloud workflow triggers only on `release/ios`.
5. A CI guard script verifies that HEAD has a valid release tag.

This gives manual control + deterministic mapping from build to tag.

## One-time setup in App Store Connect / Xcode Cloud

1. Create an iOS workflow (Archive action).
2. Start condition:
   - Branch changes only
   - Include branch: `release/ios`
   - Do not include `main`
3. Distribution destination:
   - TestFlight for beta workflow
   - App Store/TestFlight for production workflow (separate workflow recommended)
4. Keep signing automatic (cloud-managed preferred).

## One-time setup in repository

Create these scripts under `app/ios/ci_scripts/`:

- `ci_post_clone.sh`
- `ci_pre_xcodebuild.sh`

Recommended responsibilities:

### ci_post_clone.sh

- Bootstrap Flutter environment
- Run `flutter pub get` in `app/`
- Run `pod install` in `app/ios/`

### ci_pre_xcodebuild.sh

- Enforce tag guard
- Fail build unless current commit has a valid tag pattern (`v*`)

Example guard command:

```bash
TAG=$(git tag --points-at HEAD | head -n 1)
if [[ -z "$TAG" ]]; then
  echo "No release tag points at this commit. Failing intentionally."
  exit 1
fi
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-b[0-9]+)?$ ]]; then
  echo "Tag format invalid: $TAG"
  exit 1
fi
echo "Release tag validated: $TAG"
```

---

## Android Distribution Strategy

## Firebase App Distribution (fastest beta loop)

Use for immediate QA and trusted external testers.

- Artifact: APK
- Best for rapid iteration and feedback
- Use groups like `internal-qa` and `beta-closed`

## Google Play Internal Testing (store-realistic beta loop)

Use for store-like testing and install/update behavior validation.

- Artifact: AAB
- Best for policy/store behavior checks
- Recommended before wider closed/open tracks

Recommended combined approach:

1. Ship each beta tag to Firebase first (fast smoke).
2. Promote same tag build to Play Internal for realistic rollout validation.

---

## End-to-End Beta Cycle (Step by Step)

## Step 1: Prepare release candidate commit

1. Merge approved changes into `main`.
2. Update `app/pubspec.yaml` version.
3. Run local checks:

```bash
cd app
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

## Step 2: Create and push beta tag

```bash
git checkout main
git pull origin main
git tag v0.3.0-b12
git push origin v0.3.0-b12
```

Expected result:

- Android beta pipelines run from tag (APK/AAB paths in existing workflows)

## Step 3: Move iOS trigger branch to tagged commit

```bash
git checkout release/ios || git checkout -b release/ios
TAG=v0.3.0-b12
COMMIT=$(git rev-list -n 1 "$TAG")
git reset --hard "$COMMIT"
git push origin release/ios --force-with-lease
```

Expected result:

- Xcode Cloud workflow starts from `release/ios`
- Workflow fails fast if tag guard fails

## Step 4: Validate distributions

### iOS TestFlight

1. Confirm Xcode Cloud archive/upload success.
2. Verify build in App Store Connect TestFlight.
3. Add release notes and assign tester groups.

### Android Firebase

1. Confirm APK upload succeeded.
2. Confirm tester group notification received.
3. Perform install/update smoke tests.

### Android Play Internal

1. Confirm AAB uploaded to Internal track.
2. Verify opt-in and install from Play Store.
3. Validate update from previous internal build.

## Step 5: Gate and decide

Go/No-Go checks:

- Crash-free startup on both platforms
- Auth, inventory, OCR smoke scenarios pass
- Remote config / feature flags behave as expected
- No P0/P1 regressions from testers

If fail:

- Patch on main
- Create next beta tag (`-b13`)
- Repeat cycle

---

## Production Release Cycle (Step by Step)

1. Start from last accepted beta commit.
2. Bump version to stable in `pubspec.yaml`.
3. Tag stable release:

```bash
git tag v0.3.0
git push origin v0.3.0
```

4. Move `release/ios` to stable tag commit (same method as beta).
5. Run production iOS workflow in Xcode Cloud (separate workflow recommended).
6. Promote Android artifact to Play production (or staged rollout).
7. Publish release notes and monitor telemetry/crash dashboards.

---

## Required Apple Capability Alignment (iOS)

For iCloud/CloudKit enabled app IDs, all three must match:

1. App ID capability settings in Apple Developer
2. Entitlements in app target
3. Signing assets used by cloud archive

Repository wiring:

- `app/ios/Runner/Runner.entitlements`
- `app/ios/Runner.xcodeproj/project.pbxproj`

If any mismatch exists, `xcodebuild archive` often fails with exit code 65.

---

## Operational Cost Guidance

To reduce CI spend:

1. Keep PR validation on Linux GitHub runners.
2. Remove redundant GitHub macOS iOS archive jobs once Xcode Cloud is stable.
3. Keep Android build/distribution in GitHub Actions.
4. Run iOS cloud builds only from `release/ios` branch updates (not every main merge).

---

## Suggested Workflow Ownership Map

| Workflow | Owner | Trigger |
|---|---|---|
| PR lint/analyze/test | GitHub Actions | PR |
| Android beta distribute | GitHub Actions | `v*-b*` tag |
| Android stable release | GitHub Actions | `v*` stable tag |
| iOS beta TestFlight | Xcode Cloud | `release/ios` branch update + tag guard |
| iOS production | Xcode Cloud | `release/ios` branch update + stable tag guard |

---

## Release Operator Checklist (copy/paste)

### Before tagging

- [ ] Version in `app/pubspec.yaml` updated
- [ ] PR checks green
- [ ] Local smoke tests pass

### Beta run

- [ ] Create and push beta tag `vX.Y.Z-bN`
- [ ] Move/push `release/ios` branch to tagged commit
- [ ] Confirm Xcode Cloud beta workflow pass
- [ ] Confirm Firebase Android distribution pass
- [ ] Confirm Play Internal upload pass

### Stable run

- [ ] Create and push stable tag `vX.Y.Z`
- [ ] Move/push `release/ios` to stable tagged commit
- [ ] Confirm iOS production workflow pass
- [ ] Confirm Android production rollout plan
- [ ] Publish notes and monitor crash/telemetry

---

## Troubleshooting Quick Map

### iOS archive fails with code 65

- Check entitlement/capability mismatch first
- Verify app ID capability and container IDs
- Confirm cloud signing asset regeneration if stale

### Build runs on wrong commit

- Verify `release/ios` branch HEAD
- Verify tag points to same commit
- Re-run after branch force-update to tagged SHA

### Android install update fails

- Verify release signing key continuity
- Validate keystore and Play signing settings

---

## Recommended Next Hardening Tasks

1. Add `app/ios/ci_scripts/ci_post_clone.sh` and `app/ios/ci_scripts/ci_pre_xcodebuild.sh`.
2. Add tag-format guard to Android workflows (if not already strict enough).
3. Add a release orchestration script to automate:
   - tag creation
   - `release/ios` branch update
   - changelog template generation
