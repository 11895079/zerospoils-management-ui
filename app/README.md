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
