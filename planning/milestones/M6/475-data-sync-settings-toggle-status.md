## Context
Pro tier introduces household accounts and sync rules. Users need a Settings control to enable/disable sync and see status.

## Goal
Add a Data Sync settings section with toggle and last sync status, integrated with Pro sync pipeline.

## Expected behavior
- Settings → Account & Data → Data Sync toggle (ON/OFF)
- Shows last sync timestamp and sync status (idle/syncing/error)
- When OFF, background sync is disabled and no outbound sync jobs run
- Preference persists across restarts

## Acceptance criteria (Definition of Done)
- [ ] Data Sync toggle persists locally
- [ ] Sync jobs respect toggle (no sync when OFF)
- [ ] UI shows last sync time and current status
- [ ] Telemetry event on change: `sync_toggle_changed` { enabled: bool }
- [ ] Error state surfaced for failed syncs
- [ ] Unit/widget/integration tests added
- [ ] Offline-first behavior verified

## Out of scope
- Initial account creation flow
- Conflict resolution UX

## Implementation notes
- Wire to sync scheduler and repository layer (M6/470, M6/480)
- Use a shared SyncStatus model exposed via provider
- Store last sync time in local preferences for offline display

## Test plan
**Automated:**
- Unit test: sync toggle persistence
- Integration test: toggle OFF prevents sync scheduler from firing
- Widget test: status text updates on provider changes

**Manual:**
1. Enable sync → confirm status updates and last sync time
2. Disable sync → confirm no background sync runs
3. Simulate sync error → confirm error state shows in Settings

## Dependencies
- M6/470 household accounts
- M6/480 sync rules & conflict resolution