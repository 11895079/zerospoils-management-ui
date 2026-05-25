# zerospoils

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android CI Parity (Local)

To reproduce Android beta CI behavior locally, use the same core toolchain:

- Java 17
- Flutter 3.41.8 (stable)
- Android SDK platform 35 and build-tools 35.0.0

Quick parity check:

```bash
cd app
java -version
flutter --version | head -n 1
sdkmanager --list_installed | grep -E 'platforms;android-35|build-tools;35\.0\.0'
```

Run the same release build path used by CI:

```bash
cd app
rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
flutter build apk --release --no-pub --dart-define=BETA_BUILD=true
```

## iOS Simulator + MLKit Workaround

Apple Silicon iOS 26+ simulators require arm64 simulator support from all
native pods. Current MLKit pods in this project do not provide compatible
simulator support, so simulator builds fail when real MLKit plugins are active.

Use the stub toggle scripts when you need simulator runs:

```bash
cd app
chmod +x scripts/use-ios-simulator-mlkit-stubs.sh scripts/use-real-mlkit-packages.sh
./scripts/use-ios-simulator-mlkit-stubs.sh
flutter run -d ios --debug
```

Restore real packages before device or release builds:

```bash
cd app
./scripts/use-real-mlkit-packages.sh
```

Notes:
- Stub mode only affects local development by creating `pubspec_overrides.yaml`.
- Real iOS devices should use real MLKit packages (no stubs).
- In stub mode, OCR/CV flows gracefully return no detections and the app falls
  back to manual entry.

## Firebase Integration Tests

The Firebase-backed integration tests under `integration_test/` are opt-in.
They are skipped unless Firebase settings are provided with `--dart-define`.

Required defines:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`

Example:

```powershell
flutter test ^
	--dart-define=FIREBASE_API_KEY=... ^
	--dart-define=FIREBASE_APP_ID=... ^
	--dart-define=FIREBASE_MESSAGING_SENDER_ID=... ^
	--dart-define=FIREBASE_PROJECT_ID=...
```
