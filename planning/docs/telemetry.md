# Telemetry Taxonomy Document

## Purpose
Define consistent event instrumentation for measuring adoption, retention, and validating product hypotheses. Privacy-first design: no PII by default, opt-in/opt-out strategy documented.

## How to Fill
1. **Event Naming Convention:**
   - Format: `lowercase_underscore` (e.g., `item_added`, `reminder_opened`)
   - Categories: user actions (item_added), system events (notification_delivered), business metrics (waste_avoided)

2. **Core Funnel Events:**
   - `app_installed` - First app launch
   - `onboarding_completed` - User completes first-run setup
   - `item_added` - Manual item entry submitted
   - `expiry_date_scanned` - OCR capture attempted (property: `scan_success` boolean)
   - `item_edited` - Item updated
   - `inventory_viewed` - User opens inventory list
   - `expiring_viewed` - User opens expiring soon screen
   - `reminder_opened` - User taps notification
   - `item_consumed` - Item marked as consumed
   - `item_wasted` - Item marked as wasted/discarded
   - `shopping_item_added` - Item added to shopping list
   - `shopping_item_purchased` - Shopping item marked purchased
   - `shopping_converted` - Shopping list converted to inventory

3. **Standard Properties (all events):**
   - `platform`: "ios" | "android"
   - `app_version`: Semantic version (e.g., "1.0.0")
   - `timestamp`: ISO 8601 UTC
   - `session_id`: UUID for session grouping

4. **Event-Specific Properties:**
   - **item_added:** `category` (enum), `location` (enum), `lead_time_days` (int), `entry_method` ("manual" | "ocr" | "shopping_convert")
   - **expiry_date_scanned:** `scan_success` (boolean), `scan_duration_ms` (int), `date_format_detected` (string | null)
   - **item_wasted:** `category`, `location`, `waste_reason` (enum), `days_overdue` (int)
   - **reminder_opened:** `lead_time_days`, `time_of_day` ("morning" | "afternoon" | "evening")
   - **inventory_view_mode_changed:** `from` ("list" | "table" | "grid"), `to` ("list" | "table" | "grid"), `filters_applied` (boolean), `sort_key` (string | null), `result_count` (int)

5. **Privacy Strategy:**
   - **No PII:** Never collect email, phone, device_id without hashing
   - **Opt-in:** Pro tier features (cloud sync) require explicit consent
   - **Opt-out:** Local analytics only; disable cloud export in settings
   - **Anonymization:** Aggregate reports only; no individual user tracking

6. **Opt-in/Opt-out Implementation:**
   - Settings screen toggle: "Share anonymous usage data"
   - Default: Opt-in (local telemetry only, no cloud export)
   - Pro tier: Separate toggle for "Enable cloud analytics" (required for advanced insights dashboard)

## How It Will Be Used
- **Instrumentation (250):** Implement event tracking in all MVP screens
- **Analytics queries:** Measure success metrics from `docs/mvp.md`
- **Product decisions:** Validate hypotheses (e.g., reminder effectiveness)
- **Privacy policy (340):** Disclosure of data collection practices
- **Cloud sync (Pro):** Export telemetry for aggregated analytics dashboard
- **AI coding agents:** Consistent event naming; prevents ad-hoc instrumentation

## Source Material
Extract from PRD Section 8.5 (Analytics) and issue 040-define-telemetry-taxonomy.

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion.
