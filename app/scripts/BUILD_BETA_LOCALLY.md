# Beta Build Scripts

Local build scripts that mirror CI workflows for cost-effective testing before pushing tags to GitHub.

## Quick Start

### Android Beta APK
```bash
cd app
./scripts/build-android-beta.sh
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Beta IPA
```bash
cd app
./scripts/build-ios-beta.sh
```
Output: `build/ios/ipa/ZeroSpoils.ipa`

## Why Local Builds First?

GitHub Actions charges $0.008/minute on macOS runners. A failed iOS build can waste 10+ minutes on pod install + archive before failing on signing. Local builds let you catch errors in seconds for free.

**Cost savings example:**
- Local debug cycle: 30s (find and fix error) → $0
- CI cycle: 10+ min (wait for build) → $0.08+ per attempt

## Prerequisites

### Android
- Android SDK configured (via Android Studio or `flutter doctor`)
- Keystore file at `android/key.properties` with signing credentials
- `flutter` and `gradle` in PATH

### iOS
- Xcode installed
- Apple Developer certificate installed in Keychain (`security import cert.p12 ...`)
- Provisioning profile installed in `~/Library/MobileDevice/Provisioning Profiles/`
- CocoaPods installed (`sudo gem install cocoapods`)
- `flutter` and `xcode-select` in PATH

## What These Scripts Do

Both scripts mirror the CI workflows exactly:

1. **Check prerequisites** (Flutter, Xcode, keychains, profiles)
2. **Clean previous builds** (remove build/ and .dart_tool/)
3. **Get dependencies** (`flutter pub get`)
4. **Run analysis** (`flutter analyze`)
5. **Android only:** Delete plugin registrant to exclude integration_test
6. **Build release APK/IPA** with:
   - `--no-pub` (exclude dev_dependencies like integration_test)
   - `--dart-define=BETA_BUILD=true` (beta feature flags)
   - `-v` (verbose output for debugging)

## Testing After Build

### Android
```bash
# Install on emulator/device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or upload to Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app=1:123456789:android:abcdef123456 \
  --testers-file=testers.txt
```

### iOS
```bash
# Upload to TestFlight via Transporter
open /Applications/Transporter.app

# Or use altool
xcrun altool --upload-app --type ios \
  --file build/ios/ipa/ZeroSpoils.ipa \
  --username <apple-id> --password @keychain:AC_PASSWORD
```

## CI Tagging Workflow

Once local builds pass:

1. **Commit code changes**
   ```bash
   git add .
   git commit -m "feat: my feature"
   ```

2. **Test locally**
   ```bash
   ./scripts/build-android-beta.sh  # Should pass
   ./scripts/build-ios-beta.sh      # Should pass
   ```

3. **Push and tag only if local builds pass**
   ```bash
   git push origin feature/branch
   git tag v0.2.0-b33
   git push origin v0.2.0-b33
   # Android runs automatically on tag push (CI picks it up)
   # iOS requires manual dispatch: gh workflow run distribute-beta-ios.yml --ref v0.2.0-b33
   ```

## Troubleshooting

### Android: `GeneratedPluginRegistrant.java:99: error: package dev.flutter.plugins.integration_test does not exist`
This means the registrant deletion didn't work. The script should handle it, but if the error persists:
```bash
rm -f app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
```

### iOS: `No Apple Distribution certificate found in keychain`
Install your Apple Developer certificate:
```bash
security import ~/Downloads/Certificates.p12 \
  -k ~/Library/Keychains/login.keychain-db \
  -P <password>
```

### iOS: Pod install hangs
Try clearing CocoaPods cache:
```bash
rm -rf ~/.cocoapods
pod setup
```

Then re-run the script.

## Environment Variables

None required, but you can override paths if needed (advanced):
- Android: Keystore configured in `android/key.properties`
- iOS: Certificate/profile auto-discovered from system Keychain/Library

## See Also

- [CI Workflows](.github/workflows/distribute-beta-*.yml)
- [Release Guide](../docs/release.md)
- [Firebase App Distribution Setup](../docs/closed-testing-checklist-firebase-app-distribution.md)
