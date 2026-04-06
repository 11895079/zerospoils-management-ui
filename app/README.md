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
