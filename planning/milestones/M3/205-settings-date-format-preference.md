## Context
Users want dates to match their preferred format across inventory, item details, and reminders. The Settings screen already includes a Date Format dropdown but no backing implementation.

## Goal
Add a persisted Date Format preference and apply it consistently across UI surfaces.

## Expected behavior
- Settings → Preferences → Date Format dropdown (MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD)
- Selection persists locally and survives app restart
- All date displays in the app use the selected format
- Works offline

## Acceptance criteria (Definition of Done)
- [ ] Date format preference persists locally (SharedPreferences/UserDefaults)
- [ ] UI uses preference when formatting dates (inventory list, item detail, progress stats, reminders)
- [ ] Default remains MM/DD/YYYY for existing installs
- [ ] Telemetry event on change: `date_format_changed` { format: string }
- [ ] Unit/widget tests added
- [ ] Offline-first behavior verified
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full localization/i18n and locale-based auto-formatting
- Timezone preferences

## Implementation notes
- Use a shared DateFormatter utility and inject settings via provider/repository
- Prefer `intl` DateFormat patterns; avoid ad-hoc string concatenation
- Update any existing date helper to accept a format preference

## Test plan
**Automated:**
- Unit test: DateFormatter outputs correct strings per format
- Widget test: Settings dropdown persists selection across rebuild
- Widget test: Item detail date reflects selected format

**Manual:**
1. Change date format to DD/MM/YYYY
2. Verify inventory and item detail dates update
3. Restart app; confirm preference persists

## Dependencies
- None