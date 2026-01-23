# Windows Flutter Test Strategy

To keep widget tests fast and reliable on Windows, avoid filesystem locks and long runner cleanup by replacing real Hive I/O with a lightweight in-memory mock repository.

## Rationale
- Windows file handles can linger during rapid test runs, causing `flutter test` timeouts and cleanup failures.
- Widget tests should not depend on disk persistence; instead, focus on UI behavior and interactions.

## Approach
- Use a `MockItemRepository` (in-memory list) for widget tests.
- Initialize the mock in `setUp()` and inject via Riverpod providers for screens under test.
- Prefer short, deterministic pumps (`pump(const Duration(milliseconds: 50))`) over long `pumpAndSettle()` loops.
- Ensure buttons are visible before tapping to avoid offscreen interactions.

## Example
```dart
setUp(() {
  final repo = MockItemRepository();
  // seed items as needed
});

await tester.pumpWidget(
  ProviderScope(overrides: [
    hiveItemRepositoryProvider.overrideWithValue(repo),
  ], child: const MyApp()),
);

// Interact, then assert
```

## Tips
- Keep validation tight: assert text visibility, enabled states, and navigation results.
- Avoid real Hive boxes; unit tests can cover adapters and repos separately.
- Use `ensureVisible()` patterns or scroll before `tap()` when needed.

## CI Compatibility
- This strategy runs consistently on Linux runners in GitHub Actions.
- The CI workflow includes `flutter analyze`, format checks, and `flutter test --coverage`.
