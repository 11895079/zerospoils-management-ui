# Feature Flags

Feature flags control rollout of upcoming Pro tier, IoT, and backend features without scattering conditional logic throughout the app.

## Architecture

Flags are resolved in order:
1. **Local Override** (developer/debug only, persists in SharedPreferences)
2. **Remote Override** (optional, e.g., Firebase Remote Config for future use)
3. **Code Default** (source of truth, version controlled)

This design ensures:
- ✅ Offline-first: local defaults work without network
- ✅ No vendor lock-in: remote overrides are optional and adapters are generic
- ✅ Testable: all flag checks inject `FeatureFlags` via DI
- ✅ Centralized: single service, no ad-hoc `if` checks

## Flags

All flags default to **disabled** for M3 MVP. Flags are enabled per feature's target milestone.

| Flag | Description | Default | Target | Cost Notes |
|------|-------------|---------|--------|-----------|
| `cloud_sync` | Household inventory shared across devices | ❌ | M6 | Cloud storage read/write (Supabase) |
| `cloud_analytics_export` | Send event data to backend | ❌ | M4+ | Network bandwidth for telemetry |
| `receipt_ocr` | Extract items from receipt photos | ❌ | M5+ | ML API calls (Google Vision API) |
| `batch_photo_capture` | Scan multiple receipts in one session | ❌ | M5+ | Scales with receipt_ocr volume |
| `household_sync` | Collaborate with household members | ❌ | M6 | Cloud database + sync logic |
| `iot_hooks` | Integration with smart kitchen devices | ❌ | M7+ | Device APIs and cloud messaging |
| `expiry_date_ocr` | Extract expiry dates from product labels using on-device OCR | ✅ | M2 | On-device ML Kit OCR; no network cost |

## Usage

### Check Flag Status

```dart
// In a widget/service, inject via Riverpod
final isFlagEnabled = ref.watch(isFlagEnabledProvider(FeatureFlagKey.receiptOcr));

// Or directly from service
final service = await ref.read(featureFlagsServiceProvider.future);
if (service.isEnabled(FeatureFlagKey.receiptOcr)) {
  // Show OCR entry method
}
```

### Example: Conditional UI

```dart
// Hide "Cloud analytics export" option unless cloud_analytics_export is enabled
final canExport = ref.watch(
  isFlagEnabledProvider(FeatureFlagKey.cloudAnalyticsExport),
);

canExport.when(
  data: (enabled) => DropdownMenuItem(
    enabled: enabled,
    child: Text('Export to Cloud'),
  ),
  loading: () => const SizedBox.shrink(),
  error: (err, _) => const SizedBox.shrink(),
);
```

### Example: Feature Gating

```dart
// In settings_screen.dart or nav routing
final receiptOcrEnabled = ref.watch(
  isFlagEnabledProvider(FeatureFlagKey.receiptOcr),
);

receiptOcrEnabled.whenData((enabled) {
  if (enabled) {
    // Add camera/OCR entry button to shopping list
  }
});
```

## Developer Settings

In **debug builds only**, developers can override flags via the Developer Settings screen:

```dart
// In a debug menu or hidden settings tab
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const DeveloperSettingsScreen(),
  ),
);
```

The screen shows:
- All flags and their descriptions
- Current value (respecting overrides)
- Which flags are using local overrides vs defaults
- "Reset All Overrides" button to restore defaults
- Cost notes and target milestones

Overrides persist across app restarts (saved in SharedPreferences).

## Future: Remote Overrides

To add Firebase Remote Config or similar (M6+):

1. Update `FeatureFlagsService` constructor to accept `getRemoteOverrides`
2. Remote overrides already participate in precedence logic (see service implementation)
3. No changes needed to UI or flag checks—remote overrides flow through existing logic

Example wiring for Firebase:
```dart
final firebaseRemoteConfig = await FirebaseRemoteConfig.instance;
await firebaseRemoteConfig.setConfigSettings(...);

final service = FeatureFlagsService(
  prefs: prefs,
  getRemoteOverrides: () => {
    'receipt_ocr': firebaseRemoteConfig.getBool('receipt_ocr'),
    'household_sync': firebaseRemoteConfig.getBool('household_sync'),
    // ... map other flags
  },
);
```

## Testing

All flags are mockable via Riverpod overrides:

```dart
testWidgets('shows OCR button when receipt_ocr is enabled', (tester) async {
  final container = ProviderContainer(
    overrides: [
      isFlagEnabledProvider(FeatureFlagKey.receiptOcr).overrideWithValue(
        const AsyncValue.data(true),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );

  expect(find.byIcon(Icons.camera_alt), findsOneWidget);
});
```

## Checklist for Adding a New Flag

1. Add enum entry to [feature_flag_key.dart](../lib/core/feature_flags/feature_flag_key.dart)
2. Add unit test coverage to [feature_flags_service_test.dart](../test/unit/core/feature_flags/feature_flags_service_test.dart)
3. Use `isFlagEnabledProvider(flag)` in UI where feature is conditional
4. Add widget test to verify UI shows/hides feature based on flag state
5. Update this table ☝️ when flag is implemented
