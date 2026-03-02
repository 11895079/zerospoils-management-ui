## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Reminder preferences UI with concrete notification settings (lead time, sound, vibration, master toggle) plus tests and telemetry.

## Expected behavior
- Settings → Notifications section includes:
  - Master notifications toggle (on/off)
  - Expiry warning lead time (1, 3, 7 days)
  - Sound toggle (on/off)
  - Vibration toggle (on/off)
- Preferences persist locally (SharedPreferences/UserDefaults)
- Integration with notification scheduling honors master toggle + lead time
- Works offline without requiring login
- Error and empty states handled

## Acceptance criteria (Definition of Done)
- [x] Settings screen renders notification preferences (toggle + lead time + sound + vibration)
- [x] Master toggle disables scheduling when OFF and re-enables when ON
- [x] Lead time change updates scheduling window (1/3/7 days)
- [x] Sound/vibration toggles persist and are readable by notification service
- [x] Preferences persist locally and survive app restart
- [x] Telemetry emitted on changes:
  - `notification_toggle_changed` { notifications_enabled: bool }
  - `expiry_warning_changed` { lead_time_days: int }
  - `sound_toggle_changed` { sound_enabled: bool }
  - `vibration_toggle_changed` { vibration_enabled: bool }
- [x] Unit/widget/integration tests added or updated
- [x] Offline-first behavior verified
- [x] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud sync
- Receipt scanning
- Household sharing

## Implementation notes
- Follow design tokens in theme.
- Keep domain/data/ui separation.
- Use a Settings repository/service that wraps SharedPreferences for testability.
- Notification scheduling integration should respect preferences without backend.
- Add widget tests for Settings toggles and dropdown behavior.

## Test plan
**Automated:**
- Unit test: settings repository persists and returns notification prefs
- Widget test: toggling notifications updates UI state and persists preference
- Widget test: lead time dropdown persists selection (1/3/7 days)
- Integration test: scheduling respects master toggle + lead time

**Manual:**
1. Toggle Notifications OFF → confirm no scheduling occurs
2. Toggle ON → confirm scheduling resumes
3. Change lead time to 1 day → confirm upcoming items schedule at 1 day
4. Toggle Sound/Vibration and restart app → values persist

## Dependencies
- None
