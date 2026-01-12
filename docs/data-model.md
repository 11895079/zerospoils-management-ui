# Data Model Document

## Purpose
Define canonical domain model and schema for local storage (Hive/sqflite). Stable schema reduces rework and enables future features (analytics, cloud sync, ML pipelines).

## How to Fill
1. **Core Entities:**
   - **Item:** id (UUID), name (string), category (enum), location (enum), quantity (number), unit (string), expiry_date (date), purchase_date (date), status (enum: active/consumed/discarded), created_at, updated_at
   - **ShoppingListItem:** id, name, category, quantity, unit, is_purchased (bool), purchased_at
   - **Event:** id, item_id, event_type (enum: created/edited/consumed/discarded), timestamp, metadata (JSON for flexible properties)

2. **Enums:**
   - **Category:** vegetables, fruit, dairy, meat, fish, grains, bakery, condiments, beverages, leftovers, other
   - **Location:** fridge, freezer, pantry, counter, other
   - **WasteReason:** expired, spoiled, forgotten, disliked, overestimated, other

3. **Relationships:**
   - Item → Events (one-to-many)
   - ShoppingListItem → Item (converts on purchase)

4. **Migration Strategy:**
   - Version tracking (schema_version field)
   - Migration scripts for adding/removing fields
   - Backward compatibility approach (grace period for old app versions)

## How It Will Be Used
- **Local storage implementation (100):** Database schema creation and migration logic
- **Repository layer:** Data access patterns, query optimization
- **Feature development:** All MVP screens reference this schema
- **Telemetry (040):** Event log structure for analytics
- **Cloud sync (Pro tier):** Schema compatibility with backend services
- **AI coding agents:** Authoritative schema reference; prevents inconsistent field usage

## Source Material
Extract from `ZeroSpoils_Market_Report_FINAL_fixed_citations.md` Section 8.4 (Data Architecture) and issue 080-define-v1-data-model.

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion.
