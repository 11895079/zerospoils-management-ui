## Context
Meal planning features are optional and should be user-controlled to reduce clutter for users who only track inventory.

## Goal
Add a Meal Planning toggle in Settings that enables/disables meal planning surfaces.

## Expected behavior
- Settings → Preferences → Meal Planning toggle
- When OFF, meal planning UI entry points are hidden
- When ON, meal planning entry points appear
- Preference persists across restarts

## Acceptance criteria (Definition of Done)
- [ ] Toggle persists locally and survives restart
- [ ] Meal planning UI is gated by the toggle
- [ ] Telemetry event on change: `meal_planning_toggle_changed` { enabled: bool }
- [ ] Unit/widget tests added
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full meal planning feature implementation
- Recipe generation logic

## Implementation notes
- Gate entry points in navigation and any settings cards
- Store preference in SharedPreferences/UserDefaults

## Test plan
**Automated:**
- Widget test: toggling hides/shows meal planning entry points
- Unit test: preference persistence

**Manual:**
1. Toggle OFF → verify meal planning entry points disappear
2. Toggle ON → verify entry points reappear
3. Restart app → preference persists

## Dependencies
- M6/185 recipe suggestions (or equivalent meal planning feature)