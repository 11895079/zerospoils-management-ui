## Context
Users want to safeguard local data after shopping. Provide an offline-first backup/restore to open JSON from Settings, without a new tab.

## Goal
Add Backup & Restore actions to Settings → Data Management: export inventory data to JSON file; import JSON to restore. Local-first in M2; cloud/Drive can come later (Pro).

## Expected behavior
- Settings entry: "Backup & Restore"
- Export: writes JSON to user-chosen location (share/save flow)
- Import: selects JSON, validates schema/version, then applies with rollback on failure
- Shows last export timestamp and result messages
- Works offline

## Acceptance criteria (DoD)
- [ ] Backup/Restore available from Settings (not a separate tab)
- [ ] JSON schema versioned; includes items, categories, storage locations, batches, settings
- [ ] Export succeeds offline; user chooses path (share sheet / file picker)
- [ ] Import validates JSON; rejects on schema/version mismatch; rollback on partial failure
- [ ] Telemetry: `backup_started`, `backup_succeeded/failed`, `restore_started`, `restore_succeeded/failed` (include sizes/counts)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud/Drive backup (defer to Pro tier later)
- Household sync

## Implementation notes
- Use open JSON format; keep binary assets (images) out of M2 scope or reference URIs only
- Add schema version and exported_at timestamp; include app version
- Large data: stream writing/reading where possible; cap file size guidance
- Consider dry-run validation before applying restore
- Error UX: clear messaging; require explicit confirmation before overwrite

## Test plan
**Automated:**
- Unit: export produces valid JSON; import validates schema/version; rollback on injected failure
- Integration: export→delete local DB→import→data restored
- Telemetry: events emitted with counts

**Manual:**
1. Settings → Backup → save JSON; view file
2. Delete app data; Settings → Restore from saved JSON; verify items/categories/locations restored
3. Corrupt JSON import → see error, no data change
4. Offline mode: export/import works

## Dependencies
- M1/080 (data model) and M2 storage for schema definition
- M3/240 (data export/delete baseline) alignment
