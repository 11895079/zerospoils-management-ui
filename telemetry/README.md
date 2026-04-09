# ZeroSpoils Telemetry Infrastructure

Schemas, tools, and policies for privacy-first, offline-first telemetry collection. This folder is versioned at the repo root to enable schema evolution independent of app releases.

## Folder Structure

```
telemetry/
├── schemas/              # JSON Schema definitions (draft-07)
│   ├── envelope.schema.json      # Standard wrapper for all events
│   ├── allowlist.json            # Event → allowed properties mapping
│   └── events/
│       ├── app_installed.schema.json
│       ├── item_added.schema.json
│       └── item_wasted.schema.json
├── fixtures/             # Sample event payloads for testing
│   └── events/
│       ├── app_installed.json
│       ├── item_added.json
│       └── item_wasted.json
├── tools/                # Validation and code generation
│   ├── validate_events.py       # Validate events against schemas
│   ├── generate_dart_constants.py  # Generate Dart constants from allowlist
│   └── pii_scan.py               # Scan for PII in events
├── policies/             # Data handling rules
│   ├── sampling.yaml             # Event sampling rates
│   ├── retention.yaml            # Data retention policies
│   ├── redaction.yaml            # PII blocking/masking rules
│   └── consent.md                # Consent strategy (regional compliance)
├── README.md             # This file
└── CHANGELOG.md          # Version history of schema changes
```

## Schemas

### Envelope (all events)
Every event follows this structure:

```json
{
  "id": "uuid",
  "name": "event_name",
  "timestamp": "ISO-8601",
  "app_version": "semver",
  "platform": "ios|android",
  "session_id": "uuid",
  "properties": { /* event-specific */ }
}
```

**Required Fields:** id, name, timestamp, app_version, platform, session_id  
**ID Format:** UUID v4 (RFC 4122)  
**Timestamp:** ISO 8601 UTC (e.g., "2025-01-17T12:34:56Z")

### Event Schema Examples

#### app_installed
```json
{
  "name": "app_installed",
  "properties": {
    "is_first_install": true  // boolean
  }
}
```
**When:** App launches for first time or after uninstall  
**User:** Understand install source, reinstall frequency

#### item_added
```json
{
  "name": "item_added",
  "properties": {
   "source": "manual|camera_barcode|camera_expiry|camera_barcode_and_expiry|shopping_convert|receipt_batch_camera",
   "entry_method": "manual|camera_barcode|camera_expiry|camera_barcode_and_expiry|shopping_convert|receipt_batch_camera",
   "camera_used": true,
   "category": "dairy|produce|...",
   "location": "fridge|freezer|pantry|counter|other",
   "quantity": 1,
   "has_expiry_date": true,
   "camera_barcode_accepted": true,
   "camera_expiry_accepted": false,
   "camera_barcode_source": "seed_catalog|learned_mapping|unknown|none",
   "camera_expiry_format": "MM/DD/YYYY|DD/MM/YYYY|YYYY MON DD|none"
  }
}
```
**When:** User saves a new inventory item from the add form, shopping conversion, or receipt-batch inventory path  
**Use:** Understand entry-channel adoption, camera trust, category/location distribution, and conversion-path mix

### Item Entry Analysis Queries

The shipped `item_added` payload is sufficient to answer the product questions behind the recent camera-assisted work without joining against scan-attempt events.

**Recommended dashboard cards:**

1. **Entry mix**
  - Group `item_added` by `entry_method`
  - Primary read: share of `manual` vs `camera_barcode`, `camera_expiry`, `camera_barcode_and_expiry`, `shopping_convert`, `receipt_batch_camera`

2. **Camera reliance rate**
  - Formula: `count(item_added where camera_used=true) / count(item_added)`
  - Primary read: how much of item creation is camera-assisted at save time

3. **Barcode trust rate**
  - Formula: `count(item_added where camera_barcode_accepted=true) / count(item_added where source in ('camera_barcode','camera_barcode_and_expiry'))`
  - Primary read: how often a barcode capture actually survives into the saved item

4. **Expiry trust rate**
  - Formula: `count(item_added where camera_expiry_accepted=true) / count(item_added where source in ('camera_expiry','camera_barcode_and_expiry'))`
  - Primary read: how often OCR-derived expiry dates are accepted into the saved item

5. **Camera full-success rate**
  - Formula: `count(item_added where entry_method='camera_barcode_and_expiry' and camera_barcode_accepted=true and camera_expiry_accepted=true) / count(item_added where entry_method='camera_barcode_and_expiry')`
  - Primary read: how often the combined flow succeeds end-to-end

6. **Barcode source quality**
  - Group accepted camera saves by `camera_barcode_source`
  - Primary read: compare seeded catalog vs learned mappings vs unknown fallback

**Interpretation guidance:**

- Use `item_added` as the source of truth for accepted values.
- Use `camera_assisted_barcode_scanned` and `expiry_date_scanned` only for attempt, cancel, and failure analysis.
- `receipt_batch_camera` indicates a camera-derived bulk path, but it does not imply field-level barcode or expiry acceptance.
- `shopping_convert` is intentionally non-camera even if the original shopping item came from a prior suggested flow.

#### item_wasted
```json
{
  "name": "item_wasted",
  "properties": {
    "category": "dairy|produce|...",
    "days_until_expiry": -3,   // Negative = past expiry
    "waste_reason": "expired|spoiled|overcrowded|other",
    "cost": 4.99               // Estimated cost wasted
  }
}
```
**When:** User marks item as wasted  
**Use:** Waste analysis, cost impact, prevention insights

## Tools

### validate_events.py
Validate event JSON files against schemas and allowlist.

```bash
# Validate single file
python tools/validate_events.py fixtures/events/item_added.json

# Validate multiple files
python tools/validate_events.py fixtures/events/*.json
```

**Output:**
- ✅ Valid events
- ⚠️ Unknown properties (not in allowlist, but allowed for forward compatibility)
- ❌ Schema violations (hard failures)

### generate_dart_constants.py
Generate Dart code for type-safe event names and properties.

```bash
python tools/generate_dart_constants.py
# Output: app/lib/telemetry/generated/telemetry_events.dart
```

**Generated Constants:**
```dart
class TelemetryEvents {
  static const String APP_INSTALLED = 'app_installed';
  static const String ITEM_ADDED = 'item_added';
  static const String ITEM_WASTED = 'item_wasted';
}

class TelemetryProperties {
  static const String IS_FIRST_INSTALL = 'is_first_install';
  static const String SOURCE = 'source';
  static const String CATEGORY = 'category';
  // ...
}
```

**Usage in Dart:**
```dart
final event = {
  'name': TelemetryEvents.ITEM_ADDED,
  'properties': {
    TelemetryProperties.SOURCE: 'manual',
    TelemetryProperties.CATEGORY: 'dairy',
  }
};
```

### pii_scan.py
Scan event files for PII (emails, phone numbers, SSNs, etc.).

```bash
python tools/pii_scan.py fixtures/events/*.json
```

**Detects:**
- Email addresses
- Phone numbers
- SSNs
- Credit card numbers
- IP addresses
- Dates of birth
- Blocked keys (per redaction policy)

## Policies

### Sampling (sampling.yaml)
Event sampling rates to reduce volume and cost:

- **app_installed:** 100% (critical baseline)
- **item_added:** 100% (core funnel)
- **item_wasted:** 100% (core funnel)
- **reminder_opened:** 95% (high frequency)
- **inventory_viewed:** 50% (very high frequency)

### Retention (retention.yaml)
Data retention periods:

- **Local queue:** 30 days max, 10k event limit
- **Remote (default):** 90 days
- **Remote (waste events):** 365 days (long-term insights)
- **Sync batch size:** 100 events
- **Retries:** 5 attempts with exponential backoff (1s → 5m)

### Redaction (redaction.yaml)
PII protection rules applied pre-enqueue:

**Blocked Keys** (removed entirely):
- password, auth_token, credit_card, ssn, phone, email_address, ip_address, latitude, longitude

**Masked Keys** (truncated to first 2 chars):
- user_id, household_id

### Consent (consent.md)
Regional compliance and user choice:

- **MVP (M1-M3):** Opt-in (disabled by default)
- **Pro/Sync (M5+):** Opt-out (enabled by default)
- **Canada:** PIPEDA compliance (granular consent, annual refresh, export/delete rights)
- **EU (future):** GDPR (strict consent, right to be forgotten)
- **Privacy policy:** zerospoils.example/privacy

## Integration with App

### Runtime Code Location
Application code lives in `app/lib/telemetry/`:

```
app/lib/telemetry/
├── client.dart           # TelemetryClient (enqueue/batch/sync)
├── local_store.dart      # Hive-based event queue
├── remote_service.dart   # Upload to backend
├── models/
│   ├── event.dart        # Event envelope + parsing
│   └── payload.dart      # Event payloads
├── middleware/
│   ├── redaction.dart    # Apply redaction rules
│   ├── sampling.dart     # Apply sampling rates
│   └── validation.dart   # Validate against allowlist
└── generated/
    └── telemetry_events.dart  # Generated constants
```

### Offline-First Flow

1. **Enqueue:** User action → TelemetryClient.enqueue(event)
2. **Local Storage:** Event → Hive queue (with redaction/sampling)
3. **Batch Upload:** TelemetryClient periodically uploads 100-event batches
4. **Sync:** Remote service stores, validates, processes
5. **Retry:** Exponential backoff on network errors; max 5 retries

### Example: Adding a New Event

1. **Define schema** in `telemetry/schemas/events/new_event.schema.json`
2. **Add to allowlist** in `telemetry/schemas/allowlist.json`
3. **Add fixture** in `telemetry/fixtures/events/new_event.json`
4. **Validate** with `python tools/validate_events.py`
5. **Regenerate Dart constants** with `python tools/generate_dart_constants.py`
6. **Use in app:**
   ```dart
   telemetryClient.enqueue({
     'name': TelemetryEvents.NEW_EVENT,
     'properties': {
       TelemetryProperties.SOME_PROPERTY: value,
     }
   });
   ```
7. **Update CHANGELOG.md** with event description and version

## CI/CD Integration

### Pre-Commit Validation
```bash
# In .git/hooks/pre-commit
python telemetry/tools/validate_events.py telemetry/fixtures/**/*.json
python telemetry/tools/pii_scan.py telemetry/fixtures/**/*.json
```

### On PR
- Validate all event schemas
- Scan for PII
- Regenerate Dart constants if schemas changed
- Check redaction policy compliance

## FAQ

**Q: Why is telemetry at repo root vs. `app/lib/`?**  
A: Schemas need to evolve independently of app releases. Telemetry backend may support old and new event versions simultaneously.

**Q: How do we prevent schema drift?**  
A: Allowlist enforces strict property validation. Unknown properties trigger warnings (for forward compatibility) but don't block events.

**Q: What if a user disables telemetry?**  
A: TelemetryClient respects consent flag; events aren't enqueued if disabled.

**Q: How long until events are deleted?**  
A: Local: 30 days or 10k limit. Remote: 90 days (default) or 365 days (waste events).

**Q: Can users export their data?**  
A: Yes (future feature). See `consent.md` for PIPEDA/GDPR export rights.

---

**Last Updated:** 2025-01-17  
**Schema Version:** 1.0.0  
**Changelog:** See [CHANGELOG.md](CHANGELOG.md)
