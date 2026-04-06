## Context
Users expect a dark theme option for comfort and accessibility. The Settings wireframe includes a Dark Mode toggle marked as future.

## Goal
Implement a dark mode toggle that switches the app theme and persists the preference.

## Expected behavior
- Settings → Preferences → Dark Mode toggle
- Toggle switches app between light and dark themes immediately
- Preference persists across restarts

## Acceptance criteria (Definition of Done)
- [x] Dark theme tokens defined for key surfaces (background, cards, text, icons)
- [x] Toggle in Settings updates theme live
- [x] Preference persists locally
- [x] Telemetry event on change: `theme_changed` { theme: "light" | "dark" }
- [x] Widget tests cover toggle behavior
- [ ] Accessibility: sufficient contrast in dark theme

## Out of scope
- System-following theme mode (auto)
- Dynamic color and theming from OS wallpaper

## Implementation notes
- Use ThemeMode in app root and expose via provider
- Reuse design tokens with dark variants; avoid hard-coded colors
- Ensure icons and dividers have dark-safe colors
- Implemented live theme switching from Settings with persisted `SharedPreferences` preference and `theme_changed` telemetry.
- Audited shared surfaces and top-level screens used in the Windows/Desktop flow: settings, shell navigation, drawer, inventory, shopping list, progress, item detail, item form, receipt capture, receipt review, item cards, quantity toggles, category chips, and the shared item-entry sheet.
- Added widget regressions covering toggle persistence/live switching plus dark-theme surface checks on shared widgets, receipt flows, item detail/form flows, and top-level screens.
- Accessibility contrast validation still needs explicit manual verification across all screens and states.

## Test plan
**Automated:**
- Widget test: toggling dark mode updates Theme.of(context).brightness
- Unit test: theme preference persists
- Widget tests: shared/widget/screen dark-theme surfaces use theme-aware colors in Settings, HomeShell, Inventory, Shopping List, Progress, Item Detail, Item Form, Receipt Capture, Receipt Review, and item-entry flows

**Manual:**
1. Toggle dark mode on/off and verify key screens
2. Restart app and confirm theme persists
3. Launch the Windows desktop app and verify the audited screens render with dark surfaces and readable foreground colors, including item detail/form and receipt capture/review flows

## Dependencies
- None
