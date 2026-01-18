# Telemetry Schema Changelog

All notable changes to telemetry schemas, tools, and policies are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.0.0] - 2025-01-17

### Added

**Schemas:**
- `envelope.schema.json`: Standard event wrapper (id, name, timestamp, app_version, platform, session_id)
  - UUID v4 validation for id and session_id
  - ISO 8601 timestamp format
  - Semver validation for app_version
  - Platform: enum (ios, android)
  
- `events/app_installed.schema.json`: App installation event
  - `is_first_install` (boolean): true if first installation or post-uninstall
  
- `events/item_added.schema.json`: Item added to inventory
  - `source` (enum): manual | receipt | household
  - `category` (string): dairy, produce, proteins, grains, condiments, beverages, frozen, other
  - `has_expiry_date` (boolean): true if item has expiration date
  
- `events/item_wasted.schema.json`: Item marked as wasted
  - `category` (string): Same as item_added
  - `days_until_expiry` (integer): Days until/past expiration; negative = past expiry
  - `waste_reason` (enum): expired | spoiled | overcrowded | other
  - `cost` (number, nullable): Estimated cost of wasted item in CAD
  
- `allowlist.json`: Event name → allowed properties mapping
  - Enforces property whitelist per event type
  - Strict validation (unknown properties trigger warnings)
  - Versioned schema format

**Fixtures:**
- Sample event payloads for each event type
- Valid envelope + properties per schema
- Used for integration tests and documentation

**Tools:**
- `validate_events.py`: Validate JSON events against schemas and allowlist
  - Supports glob patterns
  - Reports validation errors vs. warnings
  - CLI interface for CI/CD integration
  
- `generate_dart_constants.py`: Generate Dart type-safe constants
  - Outputs `app/lib/telemetry/generated/telemetry_events.dart`
  - TelemetryEvents class (event names)
  - TelemetryProperties class (property names)
  - TelemetrySchemas map (event schema metadata)
  
- `pii_scan.py`: Scan events for PII (emails, phones, SSNs, etc.)
  - Pattern-based detection
  - Blocked key validation
  - CI/CD integration

**Policies:**
- `sampling.yaml`: Event sampling rates (1.0 = 100%, 0.5 = 50%, etc.)
  - Baseline events: 100% (app_installed, item_added, item_wasted)
  - High-frequency events: 95% or 50%
  - Applied at enqueue time (probabilistic)
  
- `retention.yaml`: Data retention periods (days)
  - Local queue: 30 days, 10k event limit
  - Remote default: 90 days
  - Remote waste events: 365 days
  - Sync batch size: 100, retries: 5, backoff: 1s → 5m
  
- `redaction.yaml`: PII protection rules
  - Blocked keys (removed entirely): password, auth_token, credit_card, ssn, phone, email_address, ip_address, latitude, longitude
  - Masked keys (truncated): user_id, household_id
  - Applied pre-enqueue (defense-in-depth)
  
- `consent.md`: Privacy and compliance strategy
  - MVP (M1-M3): Opt-in (disabled by default)
  - Pro/Sync (M5+): Opt-out (enabled by default)
  - Canada: PIPEDA compliance (granular consent, annual refresh, 30-day export/delete)
  - EU: GDPR (future; strict consent, right to be forgotten)
  - Data usage: Analytics only, no third-party sale, no ad linking
  - Transparency: Privacy policy link, yearly "Your Data" report

### Notes

- Schema validation uses JSON Schema draft-7 (widely supported)
- Allowlist enforces strict but forward-compatible validation
- Offline-first design: enqueue locally, batch sync remotely with retries
- Privacy by default: redaction applied before storage/upload
- Extensible: new events can be added without breaking existing validation

## Future Versions

### [1.1.0] (Planned for M1/040)
- Add 5+ new events (inventory_viewed, reminder_opened, household_invited, etc.)
- Event versioning strategy (e.g., item_wasted_v2 for breaking changes)
- Advanced retention policies (per-user retention override)

### [2.0.0] (Planned for M5+)
- Receipt OCR events (image_uploaded, item_ocr_extracted)
- Machine learning training data tagging (model_training_sample)
- Household sync events (sync_initiated, sync_completed, conflict_resolved)
- Pro tier feature usage tracking

---

**Semantic Versioning:**
- **MAJOR:** Breaking schema changes (properties removed/renamed)
- **MINOR:** Backward-compatible additions (new optional properties, new events)
- **PATCH:** Bug fixes, documentation, tooling improvements

**Backward Compatibility:**
- Old event versions remain valid after new releases
- Allowlist permits unknown properties for forward compatibility
- Migration path: e.g., item_wasted_v2 if incompatible changes needed
