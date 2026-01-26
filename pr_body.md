## Planning Updates from Bisi Feedback Session (Jan 25, 2026)

### New Issues Created

**M2/185** - User-defined Category Management
- Searchable dropdown with built-in + custom categories
- CRUD operations for user categories
- Integration with backup/restore (M2/165)
- Telemetry tracking

**M2/155** - Demo Mode Data Isolation  
- Separate demo/live database namespaces
- Rich demo seeding with varied expiry horizons (expired, today, this week, later)
- Subtle UI badge to indicate demo mode
- Offline-first design

**M2/180** - Inventory View Modes (List/Table/Grid)
- Toggle between list (default), table (sortable columns), and grid/cards (photo-forward) views
- Persistence of last-selected mode
- Shared filters/search/sort across modes
- Telemetry event for mode changes

**M3/190** - Shopping Batch/Receipt Capture
- Option A workflow: create batch with metadata (store, date, cost, receipt photo), then link items
- Support non-perishable items in batches
- Batch detail view with receipts, item lists, and aggregate stats
- Inventory filter by batch
- Integration with backup/restore

**M3/195** - Package OCR Multi-Field Extraction
- Full package OCR extracting: name, category, weight, price, expiry, batch code
- On-device ML inference (no cloud APIs)
- Pro tier gating
- Confirmation screen with field-level confidence indicators

### Data Model Enhancements (M1/080)

**Updated planning/docs/data-model.md with:**
- New Item fields: `purchase_source`, `batch_code`, `images[]`, `sublocation`
- Separate Attachments entity (URI + checksum + dimensions, max 5/item)
- Category Presets table (default expiry/storage/unit per category)
- Storage hierarchy guidance (e.g., `fridge.crisper_left`)
- Measurement/validation rules (count=integer, weight/volume=2dp precision)
- PurchaseSource enum (grocery, farmers_market, delivery, other)
- Planned v1.1.0 schema bump for additive changes

### Existing Issue Updates

- **M2/150:** Added search clear button (X) to acceptance criteria
- **M2/160:** Clarified "Review Inventory" button navigation to inventory screen
- **M2/170:** Added Mark As Wasted dialog width/readability enhancements
- **M2/155:** Enhanced demo seeding with specific requirements (20-25 items, multiple expiry buckets, realistic metadata)
- **M2/142:** Clarified OCR gating to Pro tier
- **M2/140:** Confirmed expiry entry with chips, NL parsing, and category presets
- **M4/165:** Added tab header contrast check to accessibility audit

### Telemetry Schema

**Added to planning/docs/telemetry.md:**
- `inventory_view_mode_changed` event with properties: `{from, to, filters_applied, sort_key, result_count}`

## Alignment with Feedback

All items address key feedback from Bisi:
- ✅ Custom category management (searchable + "Add new" button)
- ✅ Notes and image attachments for items
- ✅ Weight/quantity capture with measurement rules
- ✅ Demo mode with rich sample data
- ✅ Shopping batch capture with receipt photos (Option A workflow)
- ✅ Inventory view flexibility (list/table/grid)
- ✅ OCR for package information (Pro tier, future)
- ✅ Backup/restore with all metadata (JSON format)
- ✅ Storage location flexibility with sublocations
- ✅ Enhanced UX: search clear button, improved dialogs, better color contrast

## Ready for Implementation

Prioritization next step: determine implementation order for M2 and M3 issues.
