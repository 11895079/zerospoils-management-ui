## Context
Implement data export + delete account features as privacy baseline for MVP (required for app store approval and GDPR/privacy compliance). Users must be able to export their data and fully delete their account and all associated data.

## Goal
Deliver data export (CSV/JSON) + account/data deletion with full privacy compliance, tests, and telemetry.

## Expected behavior

**Data Export:**
- Users can export all local data (inventory, shopping lists, waste events, analytics) to CSV or JSON format
- Export includes all user-generated data with timestamps
- Files saved to device storage or shared via OS share sheet
- Works offline (reads from local DB only)
- Export is complete and human-readable

**Data Deletion:**
- Users can delete all local data and reset app to factory state
- Deletion is irreversible (confirmation dialog required)
- After deletion, user is returned to onboarding flow
- No orphaned data remains in local storage

**Privacy Baseline:**
- Both features available to ALL users (Free + Pro)
- No login required for Free tier (local data only)
- Pro tier: deletion also removes cloud-synced data (when implemented in M6)

## Acceptance criteria (Definition of Done)

**Data Export:**
- [ ] Export screen accessible from Settings → Privacy & Data
- [ ] User can select export format: CSV or JSON
- [ ] User can select data scopes: Inventory, Shopping Lists, Waste Events, Analytics, or All
- [ ] Export generates timestamped file: `zerospoils_export_2026-01-21.csv`
- [ ] CSV format: human-readable, opens in Excel/Google Sheets
- [ ] JSON format: structured, includes metadata (app_version, export_date, user_tier)
- [ ] Export action uses OS share sheet (save to Files, email, AirDrop, etc.)
- [ ] Progress indicator during export (if dataset is large)
- [ ] Success message after export: "Data exported successfully"
- [ ] Error handling: insufficient storage, write permission denied

**Data Deletion:**
- [ ] Delete account option in Settings → Privacy & Data
- [ ] Confirmation dialog with warning: "This will permanently delete all your data. This cannot be undone."
- [ ] User must type "DELETE" to confirm (prevents accidental deletion)
- [ ] Deletion clears all local database tables (items, events, shopping lists, settings)
- [ ] Deletion removes all cached files and images
- [ ] After deletion, user redirected to onboarding screen
- [ ] Telemetry: `privacy_data_deleted` event emitted BEFORE deletion (with user_tier, items_count)

**UI/UX:**
- [ ] Privacy & Data section in Settings screen
- [ ] Export button: "Export My Data"
- [ ] Delete button: "Delete All Data" (red, destructive styling)
- [ ] Empty state: "No data to export" (if user just installed)
- [ ] Offline-first verified (works without internet)
- [ ] Accessibility: labels, contrast, tap targets ≥44pt

**Testing:**
- [ ] Unit tests: export CSV generation, JSON serialization, deletion logic
- [ ] Widget tests: settings screen renders, export/delete buttons work
- [ ] Integration tests: export → verify file contents, delete → verify DB cleared
- [ ] Manual tests: export on iOS/Android, share to Files app, open CSV in Excel

**Telemetry:**
- [ ] Events: `privacy_data_exported`, `privacy_data_deleted`
- [ ] Properties: export_format (csv/json), data_scope (all/inventory/shopping/etc), file_size_kb, user_tier, items_count

**Privacy Compliance:**
- [ ] Export includes ALL user data (nothing hidden)
- [ ] Deletion is permanent and complete (no orphaned data)
- [ ] User controls (no forced retention)
- [ ] Documented in privacy policy (app store requirement)

## Out of scope
- Cloud sync (M6 — Pro tier feature)
- Import data from export file (defer to post-launch)
- Selective deletion (delete only inventory, keep shopping lists)
- Scheduled auto-exports or backups

## Implementation notes

**Export Data Schema (JSON):**
```json
{
  "metadata": {
    "app_version": "1.0.0",
    "export_date": "2026-01-21T10:30:00Z",
    "user_tier": "free",
    "total_items": 42
  },
  "inventory": [
    {
      "id": "uuid-123",
      "name": "Milk",
      "category": "dairy",
      "expiry_date": "2026-01-25",
      "purchase_price": 3.99,
      "location": "fridge",
      "created_at": "2026-01-15T08:00:00Z"
    }
  ],
  "shopping_lists": [...],
  "waste_events": [...],
  "analytics": {
    "total_waste_percent": 12.5,
    "money_saved": 45.00,
    "items_saved": 18
  }
}
```

**Export Data Schema (CSV):**
- Separate CSV file per data type (inventory.csv, shopping_lists.csv, waste_events.csv)
- OR single CSV with "type" column (flatter structure, easier for users)
- Include headers: `ID, Name, Category, Expiry Date, Price, Location, Created At`

**Deletion Implementation:**
```dart
// Pseudo-code for complete data deletion
Future<void> deleteAllUserData() async {
  // 1. Emit telemetry BEFORE deletion (while data still exists)
  await telemetry.logEvent('privacy_data_deleted', {
    'user_tier': userTier,
    'items_count': await db.countItems(),
  });
  
  // 2. Clear local database
  await db.deleteAllItems();
  await db.deleteAllEvents();
  await db.deleteAllShoppingLists();
  await db.deleteAllSettings();
  
  // 3. Clear cached files
  await fileStorage.clearCache();
  
  // 4. Reset app state
  await authService.logout(); // Pro tier only
  
  // 5. Navigate to onboarding
  navigator.pushReplacementNamed('/onboarding');
}
```

**Settings Screen Layout:**
```
Settings
  ...
  Privacy & Data
    > Export My Data
      - Download your inventory, shopping lists, and waste data
    > Delete All Data [RED]
      - Permanently remove all your data from this device
```

## Test plan

**Automated Tests:**

*Unit Tests (Export Logic):*
- Test CSV generation: verify headers, row count, date formatting
- Test JSON serialization: verify structure matches schema
- Test data scopes: export inventory only, export all
- Test empty data: export with zero items (should still generate valid file)
- Test large datasets: export 1000+ items (performance check)

*Unit Tests (Deletion Logic):*
- Test database clearing: verify all tables emptied
- Test file deletion: verify cache cleared
- Test telemetry: verify event emitted before deletion

*Widget Tests:*
- Render Settings → Privacy & Data section
- Tap "Export My Data" → format selector appears
- Tap "Delete All Data" → confirmation dialog appears
- Type "DELETE" → confirm button enabled

*Integration Tests:*
- Full export flow: Settings → Export → Select JSON → Share sheet → Verify file created
- Full deletion flow: Settings → Delete → Confirm → Verify DB empty → Onboarding screen shown

**Manual Tests:**

1. **Scenario: Export Data (CSV)**
   - Navigate to Settings → Privacy & Data
   - Tap "Export My Data"
   - Select format: CSV
   - Select scope: All Data
   - Tap "Export" → OS share sheet appears
   - Save to Files app
   - Open CSV in Excel/Numbers → verify data readable

2. **Scenario: Export Data (JSON)**
   - Repeat above with JSON format
   - Open JSON in text editor → verify structure matches schema

3. **Scenario: Export Empty Data**
   - Fresh install (no data)
   - Navigate to Settings → Privacy & Data
   - Tap "Export My Data"
   - Verify message: "No data to export" OR generates empty file with metadata

4. **Scenario: Delete All Data**
   - Add 10 inventory items
   - Navigate to Settings → Privacy & Data
   - Tap "Delete All Data" → confirmation dialog appears
   - Type "DELETE" → confirm
   - Verify loading indicator
   - Verify redirected to onboarding
   - Re-open app → verify all data gone (empty inventory)

5. **Scenario: Cancel Deletion**
   - Tap "Delete All Data" → confirmation dialog
   - Type "DELET" (wrong text) → confirm button disabled
   - Tap "Cancel" → dialog dismissed, no data deleted

6. **Scenario: Offline Export**
   - Enable airplane mode
   - Navigate to Settings → Privacy & Data
   - Tap "Export My Data" → export succeeds (local data only)

7. **Scenario: Pro Tier Deletion (M6)**
   - Upgrade to Pro (cloud sync enabled)
   - Add data, sync to cloud
   - Tap "Delete All Data" → confirm
   - Verify local data deleted
   - Verify cloud data deletion request sent (check logs)

**Privacy Compliance Checklist:**
- [ ] Export includes ALL user data (verified against DB schema)
- [ ] Deletion is complete (no orphaned data in local storage)
- [ ] User consent required for deletion (confirmation dialog)
- [ ] Feature documented in privacy policy
- [ ] App store privacy labels updated (data export/deletion available)

## Dependencies
- `docs/security-baseline.md` (encryption and secure storage requirements)
- M1: `080-define-v1-data-model-item-category-location-events.md` (data schema for export)
- M6: `470-pro-household-accounts-auth-shared-household-model.md` (cloud deletion for Pro tier)

