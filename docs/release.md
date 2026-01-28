# Release Process & Versioning

This document describes the release workflow for ZeroSpoils mobile app builds.

## Versioning Strategy

**Semantic Versioning:** `MAJOR.MINOR.PATCH[-PRERELEASE]`

- **MAJOR:** Breaking changes, incompatible API changes
- **MINOR:** New features, backwards-compatible additions
- **PATCH:** Bug fixes, backwards-compatible patches
- **PRERELEASE:** Optional suffix for pre-release versions

### Examples
- `1.0.0` — Production release
- `0.1.0-beta.1` — Beta pre-release
- `0.1.0-alpha.3` — Alpha pre-release
- `1.2.3` — Patch release

## Tag Format

**Git tags must follow:** `v<VERSION>`

Examples:
- `v0.1.0-beta.1`
- `v1.0.0`
- `v1.2.3`

## Release Workflow

### 1. Update Version in `pubspec.yaml`

```yaml
# app/pubspec.yaml
version: 0.1.0-beta.1+1
#        ^version    ^build
```

**Version format:** `<semantic-version>+<build-number>`
- Semantic version: `0.1.0-beta.1` (matches tag without `v` prefix)
- Build number: Incrementing integer for each build

### 2. Commit Version Bump

```bash
git checkout main
git pull origin main
git add app/pubspec.yaml
git commit -m "chore: Bump version to 0.1.0-beta.1"
git push origin main
```

### 3. Create and Push Tag

```bash
git tag v0.1.0-beta.1
git push origin v0.1.0-beta.1
```

**This triggers:**
- `.github/workflows/build-android.yml` — Builds APK + AAB
- `.github/workflows/build-ios.yml` — Builds IPA
- Both workflows run tests and analyzer before building
- Artifacts uploaded to GitHub Actions
- Draft GitHub Release created with artifacts attached

### 4. Download and Test Artifacts

1. Go to GitHub Actions → Find the workflow run for your tag
2. Download artifacts:
   - `android-apk-v0.1.0-beta.1` — APK for direct install
   - `android-aab-v0.1.0-beta.1` — AAB for Play Store
   - `ios-ipa-v0.1.0-beta.1` — IPA for TestFlight/Ad-hoc

3. Manual testing:
   - Install APK on Android device → verify app launches
   - Upload AAB to Play Store internal testing → verify integrity
   - Install IPA on iOS device → verify app launches

### 5. Publish GitHub Release

1. Go to Releases → Find the draft release for your tag
2. Edit release notes (auto-generated from commits)
3. Uncheck "Draft" → Publish release

## Code Signing Setup

### Android Signing

**Generate keystore (one-time setup):**
```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias zerospoils
```

**Add to GitHub Secrets:**
1. Encode keystore: `base64 -i release-keystore.jks | pbcopy` (macOS) or `base64 -w 0 release-keystore.jks` (Linux)
2. Add GitHub Secrets:
   - `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_ALIAS`: Key alias (e.g., `zerospoils`)
   - `ANDROID_KEY_PASSWORD`: Key password

**Configure Android app:**
```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            storeFile file("release-keystore.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Signing

**Prerequisites:**
- Apple Developer account
- Distribution certificate (`.p12` file)
- Provisioning profile (`.mobileprovision` file)

**Add to GitHub Secrets:**
1. Export certificate to `.p12` (from Keychain Access → Export)
2. Encode: `base64 -i Certificates.p12 | pbcopy` (macOS)
3. Encode provisioning profile: `base64 -i ZeroSpoils.mobileprovision | pbcopy`
4. Add GitHub Secrets:
   - `IOS_CERTIFICATE_BASE64`: Base64-encoded `.p12` certificate
   - `IOS_CERTIFICATE_PASSWORD`: Certificate export password
   - `IOS_PROVISIONING_PROFILE_BASE64`: Base64-encoded provisioning profile

## Troubleshooting

### Version Mismatch Error
```
Error: pubspec.yaml version (0.1.0) does not match tag version (0.2.0)
```
**Fix:** Update `pubspec.yaml` version to match the tag before pushing.

### Unsigned Build Warning
```
Warning: ANDROID_KEYSTORE_BASE64 secret not set. Build will be unsigned.
```
**Fix:** Add signing secrets to GitHub repository settings (see Code Signing Setup above).

### iOS Build Fails
```
Error: No signing certificate found
```
**Fix:** Ensure `IOS_CERTIFICATE_BASE64` and `IOS_PROVISIONING_PROFILE_BASE64` secrets are set.

## Changelog

When publishing a release, include a changelog summarizing:
- **Added:** New features
- **Changed:** Changes to existing features
- **Fixed:** Bug fixes
- **Removed:** Deprecated features removed

Example:
```markdown
## v0.1.0-beta.1 (2026-01-24)

### Added
- Item inventory CRUD with Hive local storage
- Add Item screen with manual entry

### Changed
- Migrated to Hive code generation for adapters

### Fixed
- None

### Removed
- None
```

## Build Pipeline Details

### GitHub Actions Workflows

**Location:** `.github/workflows/`

#### `build-android.yml`
- **Trigger:** Git tag push matching `v*`
- **Platform:** Ubuntu (Linux)
- **Steps:**
  1. Checkout code
  2. Setup Java 17 & Flutter
  3. Run `flutter analyze` (linting)
  4. Run `flutter test` (unit/widget tests)
  5. Build APK: `flutter build apk --release`
  6. Upload APK artifact

**Signing:**
- Uses GitHub Secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
- Keystore must be base64 encoded and stored in repository secrets

#### `build-ios.yml`
- **Trigger:** Git tag push matching `v*`
- **Platform:** macOS (required for iOS builds)
- **Steps:**
  1. Checkout code
  2. Setup Flutter & Xcode
  3. Pod install (CocoaPods dependencies)
  4. Run `flutter analyze`
  5. Run `flutter test`
  6. Build iOS app: `flutter build ios --release`
  7. Create Xcode archive for distribution
  8. Upload artifact

**Signing:**
- Uses GitHub Secrets: `IOS_CERTIFICATE_BASE64`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_CERTIFICATE_PASSWORD`
- Requires valid Apple Developer account and provisioning profiles

### Setting Up Code Signing

#### Android Signing Setup

1. **Generate a keystore file** (if not already done):
   ```bash
   keytool -genkey -v -keystore app-release.keystore \
     -alias zerospoils \
     -keyalg RSA -keysize 2048 \
     -validity 10000
   ```

2. **Encode keystore to base64:**
   ```bash
   cat app-release.keystore | base64 | tr -d '\n' > keystore-base64.txt
   ```

3. **Add to GitHub Secrets:**
   - Go to GitHub repo → Settings → Secrets and variables → Actions
   - Create new secrets:
     - `KEYSTORE_BASE64`: Content of keystore-base64.txt
     - `KEYSTORE_PASSWORD`: Keystore password
     - `KEY_ALIAS`: Signing key alias (from keytool step)
     - `KEY_PASSWORD`: Key password

#### iOS Signing Setup

1. **Export signing certificate** from Apple Developer:
   - Open Xcode → Preferences → Accounts
   - Select Apple ID → Manage Certificates
   - Right-click Developer ID → Export → Save as .p8 file

2. **Export provisioning profile:**
   - Visit [Apple Developer - Certificates](https://developer.apple.com/account/resources/certificates/list)
   - Select app provisioning profile → Download (.mobileprovision file)

3. **Encode files to base64:**
   ```bash
   cat certificate.p8 | base64 | tr -d '\n' > cert-base64.txt
   cat profile.mobileprovision | base64 | tr -d '\n' > profile-base64.txt
   ```

4. **Add to GitHub Secrets:**
   - `IOS_CERTIFICATE_BASE64`: Content of cert-base64.txt
   - `IOS_PROVISIONING_PROFILE_BASE64`: Content of profile-base64.txt
   - `IOS_CERTIFICATE_PASSWORD`: Certificate password
   - `APPLE_ID`: Apple ID email
   - `APPLE_APP_PASSWORD`: App-specific password (from appleid.apple.com)

## Next Steps

Future releases will automate:
- Changelog generation from conventional commits (M3)
- TestFlight/Play Store uploads via fastlane (M3)
- Version bump automation (M4)
- Release notes generation (M4)
