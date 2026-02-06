## Context
Users expect a dark theme option for comfort and accessibility. The Settings wireframe includes a Dark Mode toggle marked as future.

## Goal
Implement a dark mode toggle that switches the app theme and persists the preference.

## Expected behavior
- Settings → Preferences → Dark Mode toggle
- Toggle switches app between light and dark themes immediately
- Preference persists across restarts

## Acceptance criteria (Definition of Done)
- [ ] Dark theme tokens defined for key surfaces (background, cards, text, icons)
- [ ] Toggle in Settings updates theme live
- [ ] Preference persists locally
- [ ] Telemetry event on change: `theme_changed` { theme: "light" | "dark" }
- [ ] Widget tests cover toggle behavior
- [ ] Accessibility: sufficient contrast in dark theme

## Out of scope
- System-following theme mode (auto)
- Dynamic color and theming from OS wallpaper

## Implementation notes
- Use ThemeMode in app root and expose via provider
- Reuse design tokens with dark variants; avoid hard-coded colors
- Ensure icons and dividers have dark-safe colors

## Test plan
**Automated:**
- Widget test: toggling dark mode updates Theme.of(context).brightness
- Unit test: theme preference persists

**Manual:**
1. Toggle dark mode on/off and verify key screens
2. Restart app and confirm theme persists

## Dependencies
- None