# M1/090 Implementation Quickstart

## Pre-Implementation Checklist

✅ **All Planning Complete:**
- [x] Design tokens (spacing, colors, typography)
- [x] UX patterns and component guidelines
- [x] Data model (Item, ShoppingListItem, categories)
- [x] Telemetry schema (app_installed, item_added, item_wasted)
- [x] Telemetry infrastructure (validation tools, policies)
- [x] M1/090 specification (160+ lines, 13+ criteria)

✅ **Environment Ready:**
- [x] Flutter 3.38.5 (Dart 3.10.4) installed
- [x] Feature branch `feature/flutter-app-skeleton` created
- [x] `app/.gitkeep` exists (placeholder)
- [x] Git configured with proper commit messages

---

## Step 1: Create Flutter Project

```bash
cd c:\Projects\zerospoils\etc\zerospoils_github_issues_pack\app
flutter create . --org com.zerospoils --project-name zerospoils
```

**Expected output:**
- Scaffolds iOS, Android, web projects
- Generates pubspec.yaml with Flutter dependencies
- Creates main.dart entry point

---

## Step 2: Update pubspec.yaml

Add required dependencies per M1/090 spec:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Routing
  go_router: ^14.2.0
  # State management + DI
  riverpod: ^2.6.0
  flutter_riverpod: ^2.6.0
  # Local storage
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  # Connectivity
  connectivity_plus: ^6.0.0
  # Serialization
  json_serializable: ^6.8.0
  # Network
  http: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
  riverpod_generator: ^2.5.0

flutter:
  uses-material-design: true
```

Run `flutter pub get` after saving.

---

## Step 3: Scaffold Folder Structure

Create these directories (matching M1/090 spec):

```
app/lib/
├── domain/
│   ├── models/
│   │   └── item.dart
│   └── repositories/
│       └── item_repository.dart
├── data/
│   ├── local/
│   │   ├── hive_service.dart
│   │   └── telemetry_repository.dart
│   ├── repositories/
│   │   └── item_repository_impl.dart
│   └── datasources/
│       └── item_local_datasource.dart
├── presentation/
│   ├── themes/
│   │   └── app_theme.dart
│   ├── routing/
│   │   └── router.dart
│   ├── screens/
│   │   ├── home_shell.dart
│   │   ├── inventory/
│   │   │   └── inventory_screen.dart
│   │   ├── expiring/
│   │   │   └── expiring_screen.dart
│   │   ├── shopping/
│   │   │   └── shopping_screen.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   ├── widgets/
│   │   ├── base_components.dart
│   │   └── empty_state.dart
│   └── di/
│       └── service_locator.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   └── extensions/
│       └── context_extensions.dart
├── telemetry/
│   ├── client.dart
│   ├── local_store.dart
│   └── generated/
│       └── telemetry_events.dart
├── main_dev.dart
└── main.dart

app/test/
├── unit/
│   ├── domain/
│   └── data/
├── widget/
│   └── screens/
├── integration_test/
│   └── app_test.dart
└── fixtures/
    └── sample_events.dart
```

---

## Step 4: Key Implementation Files (Template Stubs)

### app/lib/main.dart
- Initialize Hive for local storage
- Setup Riverpod for DI/state management
- Initialize telemetry client
- Run app with GoRouter configuration

### app/lib/presentation/themes/app_theme.dart
- Create ThemeData using tokens from `planning/docs/design-tokens.md`
- Define colors: `const primaryColor = Color(0xff1b5e20)`; // Adjust per spec
- Define spacing: `const smallSpacing = 8.0`, `mediumSpacing = 16.0`, etc.
- Apply to Material theme (TextTheme, BottomNavigationBarThemeData, etc.)

### app/lib/presentation/routing/router.dart
- Use GoRouter with routes for each tab
- Add deep linking support (`zerospoils://item/{itemId}`)
- Define route guards for offline-first (all routes work offline)

### app/lib/presentation/screens/home_shell.dart
- BottomNavigationBar with 4 tabs
- Index-based page switching (PageStorage to preserve scroll)
- FAB for "Add Item" action

### app/lib/domain/models/item.dart
- Serialize Item from `planning/docs/data-model.md`
- Properties: id, name, category, location, expiry_date, purchase_date, cost, status, waste_reason

### app/lib/telemetry/client.dart
- TelemetryClient class with `enqueue(event)` method
- Use Riverpod provider pattern
- Calls `redaction.apply()` and `sampling.apply()` before storing
- Store in Hive queue; no upload yet (M2+)

---

## Step 5: Generate Code

After defining models with Hive/@HiveType decorators:

```bash
cd app
flutter pub run build_runner build
```

This generates:
- Hive adapters for Item/ShoppingListItem/Event models
- JSON serialization code (if using @JsonSerializable)

---

## Step 6: Testing Stubs

### app/test/unit/domain/models/item_test.dart
- Test Item serialization/deserialization
- Verify category and waste_reason enums

### app/test/widget/screens/home_shell_test.dart
- Test app launches and renders home
- Test tab bar switches between screens
- Test FAB opens Add Item modal

### app/test/integration_test/app_test.dart
- Test deep linking (cold start)
- Test offline behavior (disconnect network, app still works)

---

## Step 7: Validation Before PR

Run these commands in `app/` folder:

```bash
# Analyze code for errors
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Build for iOS (requires macOS)
flutter build ios --no-codesign

# Build for Android
flutter build apk --debug
```

All should pass with zero warnings.

---

## Step 8: Commit & Push

```bash
cd c:\Projects\zerospoils\etc\zerospoils_github_issues_pack
git add app/
git commit -m "feat(app): scaffold Flutter app skeleton with routing, theming, DI

- Setup Riverpod for state management and DI
- Configure GoRouter for deep linking (zerospoils://)
- Implement 4-tab navigation (Inventory, Expiring, Shopping, Settings)
- Apply theme from design tokens (colors, spacing, typography)
- Setup Hive for local storage (Item, ShoppingListItem, Event models)
- Integrate connectivity monitoring
- Wire telemetry client (local enqueue, no upload yet)
- Add base components (buttons, empty state)
- Implement unit/widget/integration tests
- Verify offline-first behavior
- Accessibility: 44pt buttons, semantic labels, 4.5:1 contrast

Satisfies M1/090 acceptance criteria: structure, compilation, theme, tabs, modals, routing, DI, connectivity, telemetry, tests, linting, formatting, accessibility."

git push origin feature/flutter-app-skeleton
```

Then create PR linking to issue M1/090.

---

## Step 9: CI/CD Next (M1/020)

After M1/090 is merged, implement M1/020:
- GitHub Actions workflow: `flutter analyze`, `dart format`, `flutter test`, iOS/Android build
- Run on every PR to `main`

---

## Key Design Decisions (Already Made in M1/090)

| Decision | Value | Rationale |
|----------|-------|-----------|
| State Management | Riverpod | Type-safe, compile-time verification, good DI support |
| Routing | GoRouter | Deep linking, type-safe route handling, Flutter team recommended |
| Local Database | Hive | Lightweight, fast, good for offline-first (alternatives: sqflite, isar) |
| DI Container | Riverpod providers | No extra dependency; Riverpod already chosen for state |
| Telemetry | Local queue first | Enqueue locally, sync batch to backend later (M2+) |

---

## Checklist (Copy to PR Description)

- [ ] Project structure matches spec (domain/data/presentation/core/telemetry)
- [ ] Compiles for iOS and Android without warnings
- [ ] Theme applied from design-tokens.md (colors, spacing, typography)
- [ ] 4 tabs visible and functional (Inventory, Expiring, Shopping, Settings)
- [ ] Add Item modal opens and dismisses
- [ ] Deep linking works (`zerospoils://item/123`)
- [ ] DI container resolves all services
- [ ] Connectivity service integrated
- [ ] Telemetry client enqueues events
- [ ] Base components implemented (buttons, empty state)
- [ ] `flutter analyze` passes (zero warnings)
- [ ] `dart format` applied
- [ ] Unit tests for DI container (≥1)
- [ ] Widget tests for navigation (≥3)
- [ ] Integration test for deep linking (≥1)
- [ ] Offline behavior verified (no crashes)
- [ ] Accessibility verified (44pt buttons, semantic labels, contrast)

---

## Troubleshooting

**Problem:** `flutter create` fails with permission denied  
**Solution:** Run PowerShell as Administrator, or adjust file permissions in `app/` folder.

**Problem:** Build fails with `Error: Could not create build context`  
**Solution:** Delete `build/`, `.dart_tool/`, `pubspec.lock` and run `flutter pub get` again.

**Problem:** Hive adapter not generated  
**Solution:** Ensure models have `@HiveType()` and `@HiveField()` decorators; run `flutter pub run build_runner build --delete-conflicting-outputs`.

**Problem:** Deep links don't open app on Android  
**Solution:** Verify `zerospoils://` scheme registered in `AndroidManifest.xml` (should be auto-generated by Flutter).

---

**Reference:** [M1/090 Full Spec](planning/milestones/M1/090-flutter-app-skeleton-routing-theming-di.md)
