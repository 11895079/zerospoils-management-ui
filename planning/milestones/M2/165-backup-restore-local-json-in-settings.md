## Context
Users want to safeguard local data after shopping. Provide an offline-first backup/restore to open JSON from Settings, without a new tab.

## Goal
Add Backup & Restore actions to Settings → Data Management: export inventory data to JSON file; import JSON to restore. Local-first in M2; cloud/Drive can come later (Pro).

## Expected behavior
- Settings entry: "Backup & Restore"
- Export: writes JSON to user-chosen location (share/save flow); includes schema_version and app_version
- Import: detects backup schema_version and app_version; auto-migrates data if versions differ; validates before applying
- Handles cross-version scenarios: restore v1.0.0 backup into v1.1.0 app (forward compatible), or v1.1.0 backup into v1.0.0 app (reject with explanation)
- Shows last export timestamp and result messages
- Rollback on failure: if restore errors mid-process, local DB remains unchanged (transactional)
- Works offline

## Acceptance criteria (DoD)
- [ ] Backup/Restore available from Settings (not a separate tab)
- [ ] JSON schema versioned; includes items, categories, storage locations, batches, settings, schema_version, app_version, exported_at
- [ ] Export succeeds offline; user chooses path (share sheet / file picker); includes backup metadata header
- [ ] Import validates JSON and compares schema_version with app's current schema_version
- [ ] Forward migration (old backup → new app): auto-run migrations on imported data to current schema (e.g., v1.0.0 backup into v1.1.0 app)
- [ ] Backward migration (new backup → old app): reject with user-friendly message (require app update or restore to compatible version)
- [ ] Dry-run validation before restore: preview data counts (items, categories, etc.) and prompt for confirmation
- [ ] Rollback on failure: if restore errors at any step, local DB unchanged; show clear error message
- [ ] Telemetry: `backup_started`, `backup_succeeded` (size, item_count), `backup_failed` (reason), `restore_started`, `restore_succeeded` (item_count_imported, migrations_applied), `restore_failed` (reason, schema_mismatch)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud/Drive backup (defer to Pro tier later)
- Household sync

## Implementation notes
- Use open JSON format; keep binary assets (images) out of M2 scope or reference URIs only
- Backup metadata header: `{ "backup_version": "1.0", "schema_version": "1.0.0", "app_version": "1.0.0", "exported_at": "2026-01-26T12:34:56Z", "item_count": 42, "data": {...} }`
- Large data: stream writing/reading where possible; cap file size guidance (~10MB for MVP)
- Schema migration on restore:
  - Load backup → read schema_version and app_version
  - Compare with app's current schema_version
  - If same or newer minor version: run applicable migrations (v1.0.0 → v1.0.1 patches, then v1.0 → v1.1 additive changes)
  - If major version mismatch: reject with message "Backup from [version] not compatible. Please update the app to [required_version] or downgrade backup."
  - Track applied migrations in telemetry
- Dry-run validation: parse JSON, simulate import into temp DB, verify counts and referential integrity
- Rollback strategy: use database transactions; if any step fails, rollback entire transaction and restore original state
- Error UX: show clear messaging with suggested actions (update app, re-export backup from newer app, etc.)
- Require explicit user confirmation before overwriting existing local data (show summary: "This will restore 42 items, 8 categories, 3 batches. Continue?")
- Store last successful backup metadata (timestamp, size) for display in Settings

## Test plan
**Automated:**
- Unit: export produces valid JSON with correct metadata header; schema_version matches app version
- Unit: import detects and validates schema_version; parses backup metadata correctly
- Unit: forward migration (v1.0.0 backup → v1.1.0 app) runs applicable migrations and data is accessible
- Unit: backward migration (v1.1.0 backup → v1.0.0 app) rejects with appropriate error message
- Unit: JSON validation catches schema violations; import rejected before DB modified
- Integration: export→delete local DB→import→data fully restored with same counts
- Integration: rollback test - inject failure mid-import, verify local DB unchanged
- Dry-run test: preview shows correct item/category/batch counts before confirmation
- Telemetry: events emitted with schema_version, migrations_applied, item_count, success/failure reason

**Manual:**
1. Settings → Backup → save JSON to file; verify file contains metadata (schema_version, app_version, exported_at)
2. Delete app data via Settings → Clear All Data; verify local DB empty
3. Settings → Restore → select backup JSON; verify dry-run preview shows expected counts; confirm restore
4. Verify all items/categories/batches restored with original data intact
5. Corrupt JSON (edit to remove closing brace) → import → see validation error, local data unchanged
6. Create backup on v1.0 app; (in future) restore into v1.1 app; verify forward migration succeeds
7. Create backup on v1.1 app; attempt restore on v1.0 app (simulated); verify rejection with helpful message
8. Large backup: export 500+ items; measure performance and file size
9. Offline mode: export/import works without network
10. Interrupted restore: kill app mid-import (via test framework); relaunch and verify DB not corrupted

## Dependencies
- M1/080 (data model) and M2 storage for schema definition
- M3/240 (data export/delete baseline) alignment
