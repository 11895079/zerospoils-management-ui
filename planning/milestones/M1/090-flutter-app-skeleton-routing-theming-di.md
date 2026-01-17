## Context
Establish a maintainable architecture for rapid iteration. Foundation for all subsequent MVP features (M2/140-210). Must support offline-first, telemetry, and deep linking.

## Goal
Create a Flutter app skeleton with:
- **Navigation:** Tab-based shell (Inventory, Expiring, Shopping, Settings) + modals for Add/Edit
- **Theming:** Design tokens from `docs/design-tokens.md` as Flutter ThemeData
- **DI:** Service layer with repository pattern (local DB access, telemetry client, connectivity monitor)
- **Testing:** Widget tests for navigation, unit tests for DI resolution
- **Accessibility:** WCAG 2.1 AA baseline (44pt touch targets, 4.5:1 contrast, semantic labels)

## Expected behavior
- App launches to home shell with 4 tabs visible
- Tab navigation switches between screens (no data loss on tab switch)
- Theme tokens (spacing, colors, typography) applied consistently
- Placeholder screens render correctly (Inventory, Expiring, Shopping, Settings)
- DI container resolves services (TelemetryClient, Repository, ConnectivityService)
- Deep links work (e.g., `zerospoils://item/{itemId}` opens Item Detail)
- Telemetry events logged on key actions (app_installed, tab_switched, item_add_initiated)

## Acceptance criteria (Definition of Done)
- [x] Project structure: domain/data/presentation layers
- [x] Project compiles for iOS and Android without warnings
- [x] Theme applied from `docs/design-tokens.md` (colors, spacing, typography)
- [x] Tab-based navigation with 4 tabs (Inventory, Expiring, Shopping, Settings)
- [x] Placeholder screens for each tab (AppBar + empty state)
- [x] Modal for Add Item (bottom sheet, dismissible)
- [x] Deep link routing configured (`zerospoils://` scheme)
- [x] DI container (GetIt or similar) with test service resolution
- [x] Connectivity service integrated (monitors online/offline)
- [x] Telemetry client wired (enqueues events locally, no upload yet)
- [x] Base components: PrimaryButton, SecondaryButton, EmptyStateWidget
- [x] Linting passes (`flutter analyze` clean, no warnings)
- [x] Formatting passes (`dart format` applied)
- [x] Unit tests: DI container resolves all services (≥1 test)
- [x] Widget tests: App launches, renders home, tabs switch (≥3 tests)
- [x] Integration test: Deep link navigation (≥1 test)
- [x] Telemetry instrumented: app_installed, tab_switched events logged
- [x] Offline-first verified: app works with no network (no runtime crashes)
- [x] Accessibility verified: 44pt buttons, semantic labels, 4.5:1 contrast on text

## Out of scope
- Feature implementation (actual inventory, shopping, expiring logic) — that's M2
- Cloud sync or backend endpoints — local-only for M1
- Advanced state management (beyond simple riverpod/provider scoping)
- Notifications or background tasks — M3
- OCR or receipt parsing — M6 Pro tier

## Implementation notes
- **Structure:** Follow clean architecture:
  ```
  app/lib/
  ├── domain/              # Business logic, models
  │   ├── models/
  │   │   └── item.dart
  │   └── repositories/
  │       └── item_repository.dart
  ├── data/                # Local DB, network, shared prefs
  │   ├── local/
  │   │   ├── hive_service.dart
  │   │   └── telemetry_repository.dart
  │   ├── repositories/
  │   │   └── item_repository_impl.dart
  │   └── datasources/
  │       └── item_local_datasource.dart
  ├── presentation/        # UI, routing, state
  │   ├── themes/
  │   │   └── app_theme.dart
  │   ├── routing/
  │   │   └── router.dart
  │   ├── screens/
  │   │   ├── home_shell.dart
  │   │   ├── inventory/
  │   │   ├── expiring/
  │   │   ├── shopping/
  │   │   └── settings/
  │   ├── widgets/
  │   │   └── base_components.dart
  │   └── di/
  │       └── service_locator.dart
  ├── core/
  │   ├── constants/
  │   ├── utils/
  │   └── extensions/
  ├── main.dart
  └── main_dev.dart
  ```
- **State management:** Use Riverpod (pods for services, connectivity, future builders for screens) — no complex logic yet.
- **Database:** Hive for local queue (Item, ShoppingListItem, Event); configure in `data/local/hive_service.dart`.
- **Telemetry:** `lib/telemetry/` mirrors app-level logic (local enqueue, sync service stub).
- **Routing:** Go Router with deep link support; define routes in `router.dart` (e.g., `/item/:id`).
- **Theme:** Define in `presentation/themes/app_theme.dart` using design token constants; apply in MaterialApp.
- **Connectivity:** Use `connectivity_plus` package; expose as Riverpod stream so UI responds to online/offline.
- **Tests:** Place alongside source (e.g., `test/presentation/screens/home_shell_test.dart`).

## Test plan
**Automated:**
- **Unit (test/domain/, test/data/):**
  - DI container resolves all registered services (GetIt / service_locator_test.dart)
  - Item model serialization/deserialization (JSON roundtrip)
  - Telemetry repository enqueues/dequeues events without network
  
- **Widget (test/presentation/):**
  - App launches and renders home shell (4 tabs visible)
  - Tab bar switches between Inventory, Expiring, Shopping, Settings screens
  - Each tab renders AppBar with title and placeholder empty state
  - Add Item modal opens on FAB tap (bottom sheet appears)
  - Modal dismisses on back/scrim tap
  - Theme tokens applied: button color matches primary color, spacing matches tokens
  
- **Integration (test/integration/):**
  - Deep link `zerospoils://` opens app (cold start)
  - Deep link `zerospoils://item/123` navigates to Item Detail (if app already running)
  - Offline mode: disconnect network, app still renders (no crash)
  - Telemetry event logged on app start: `app_installed` with `app_version`, `platform`

**Manual:**
1. **iOS Simulator:**
   - `flutter run -d "iPhone 15"` → app launches, 4 tabs visible, smooth transitions
   - Tap each tab → screen changes, no lag
   - Tap FAB → Add Item modal appears, looks good on 6.1" screen
   - Press back → modal dismisses
   - Verify green primary color and spacing match design tokens
   
2. **Android Emulator:**
   - `flutter run -d emulator-5554` → app launches, 4 tabs visible
   - Repeat tab navigation, modal test
   - Verify contrast: text readable on background
   - Verify touch targets: buttons are at least 44×44 dp (use Flutter DevTools inspector)

3. **Physical Device (optional for M1, required for final QA):**
   - Install APK/IPA; launch app
   - Run through tab navigation, modal flows
   - Measure scroll performance (no jank)
   - Test with Accessibility Inspector (iOS) / TalkBack (Android) — basic nav works

4. **Deep Linking:**
   - `adb shell am start -W -a android.intent.action.VIEW -d "zerospoils://item/123" com.zerospoils.zerospoils`
   - Verify it opens Item Detail (or gracefully falls back to home if no item with that ID)

5. **Offline Testing:**
   - Airplane mode on; all screens still render
   - Tap actions (Add Item, etc.) → still work locally
   - Turn airplane mode off → no crashes, telemetry queues sync

## Dependencies
- **planning/docs/design-tokens.md** – Colors, spacing, typography tokens (MUST be complete before M1/090 impl)
- **planning/docs/ux.md** – Component patterns, interaction guidelines (MUST be complete)
- **planning/docs/data-model.md** – Item schema (for domain models)
- **planning/docs/telemetry.md** – Event taxonomy (for wiring events)
- **M1/040** – Telemetry taxonomy (should be merged so event names are locked)
- **telemetry/** folder – Schemas and fixtures (optional but helpful for tests)

