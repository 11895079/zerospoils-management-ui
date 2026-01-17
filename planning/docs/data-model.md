# Data Model Document

## Purpose
Define canonical domain model and schema for local storage (Hive/sqflite). Stable schema reduces rework and enables future features (analytics, cloud sync, ML pipelines).

---

## Core Entities

### 1. Item
Primary entity representing food items in inventory.

| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| `id` | UUID | Yes | Unique identifier | Primary key |
| `name` | String | Yes | Item name (e.g., "Milk", "Chicken Breast") | Max 100 chars |
| `category` | Enum | Yes | Food category | See Category enum |
| `location` | Enum | Yes | Storage location | See Location enum |
| `quantity` | Number | Yes | Original/total amount | Decimal, min 0.01, initial purchase quantity |
| `unit` | String | Yes | Unit of measure | e.g., "count", "lbs", "oz", "ml" |
| `quantity_consumed` | Number | Yes | Amount consumed | Decimal, min 0, default 0, tracks cumulative consumption |
| `quantity_wasted` | Number | Yes | Amount wasted | Decimal, min 0, default 0, tracks cumulative wastage |
| `cost` | Decimal | No | Purchase cost | Currency amount (e.g., 3.99), nullable, min 0 |
| `expiry_date` | Date | No | Expiration date | ISO 8601, nullable for non-perishables |
| `purchase_date` | Date | No | Date purchased/added | ISO 8601, defaults to created_at |
| `status` | Enum | Yes | Current state | See Status enum |
| `notes` | String | No | User notes | Max 500 chars, nullable |
| `created_at` | DateTime | Yes | Creation timestamp | ISO 8601 UTC |
| `updated_at` | DateTime | Yes | Last update timestamp | ISO 8601 UTC, auto-update |

**Business Rules:**
- `quantity_consumed + quantity_wasted ≤ quantity` (cannot consume/waste more than purchased)
- When `quantity_consumed + quantity_wasted = quantity`, item is fully consumed/wasted
- Remaining quantity: `quantity - quantity_consumed - quantity_wasted`
- Status transitions:
  - `active` → `consumed` when `quantity_consumed = quantity` (full consumption)
  - `active` → `wasted` when `quantity_wasted = quantity` (full wastage)
  - `active` → remains `active` for partial consumption/wastage
  - UI can show "partially consumed" or "partially wasted" badges based on these fields

**Indexes:**
- Primary: `id`
- Secondary: `status`, `expiry_date`, `category`, `location`
- Composite: `(status, expiry_date)` for expiring soon queries

---

### 2. ShoppingListItem
Items planned for purchase.

| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| `id` | UUID | Yes | Unique identifier | Primary key |
| `name` | String | Yes | Item name | Max 100 chars |
| `category` | Enum | No | Food category | See Category enum, nullable |
| `quantity` | Number | Yes | Amount needed | Decimal, min 0.01 |
| `unit` | String | Yes | Unit of measure | e.g., "count", "lbs" |
| `estimated_cost` | Decimal | No | Estimated purchase cost | Currency amount, nullable, for budgeting |
| `is_purchased` | Boolean | Yes | Purchased status | Default: false |
| `purchased_at` | DateTime | No | Purchase timestamp | ISO 8601 UTC, nullable |
| `notes` | String | No | Shopping notes | Max 500 chars, nullable |
| `created_at` | DateTime | Yes | Creation timestamp | ISO 8601 UTC |
| `updated_at` | DateTime | Yes | Last update timestamp | ISO 8601 UTC |

**Indexes:**
- Primary: `id`
- Secondary: `is_purchased`

---

### 3. Event
Audit log for item state changes and user actions.

| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| `id` | UUID | Yes | Unique identifier | Primary key |
| `item_id` | UUID | No | Related item | Foreign key to Item, nullable for app-level events |
| `event_type` | Enum | Yes | Event category | See EventType enum |
| `timestamp` | DateTime | Yes | Event occurrence time | ISO 8601 UTC |
| `metadata` | JSON | No | Flexible event properties | Varies by event_type |

**Indexes:**
- Primary: `id`
- Secondary: `item_id`, `event_type`, `timestamp`
- Composite: `(item_id, timestamp)` for item history queries

**Metadata Examples:**
- `item_created`: `{"source": "manual" | "ocr" | "shopping_list"}`
- `item_consumed`: `{"days_until_expiry": 2, "quantity_consumed": 0.5, "remaining_quantity": 0.5}`
- `item_wasted`: `{"waste_reason": "expired", "days_past_expiry": 3, "quantity_wasted": 0.5, "remaining_quantity": 0}`
- `item_edited`: `{"fields_changed": ["expiry_date", "location"]}`

**Consumption/Wastage Event Guidelines:**
- Always include `quantity_consumed` or `quantity_wasted` in metadata
- Include `remaining_quantity` for tracking purposes (calculated as: `quantity - quantity_consumed - quantity_wasted`)
- For partial consumption: log event with amount consumed, item stays `active`
- For partial wastage: log event with amount wasted, item stays `active`
- For full consumption/wastage: update item status to `consumed` or `wasted`

---

## Enums

### Category
Food classification for organization and analytics.

```
vegetables
fruit
dairy
meat_poultry
seafood
grains
bakery
condiments_sauces
beverages
snacks
leftovers
prepared_meals
frozen_foods
canned_goods
other
```

### Location
Storage location for item placement.

```
fridge
freezer
pantry
counter
other
```

### Status
Item lifecycle state.

```
active        # In inventory, available for consumption
consumed      # Fully consumed (quantity_consumed = quantity)
wasted        # Fully wasted (quantity_wasted = quantity)
expired       # Past expiry date but not yet discarded
```

**Note:** For partial consumption/wastage scenarios (e.g., half a loaf eaten, half wasted), the item remains `active` status until fully consumed or wasted. Use `quantity_consumed` and `quantity_wasted` fields to track partial usage.

### WasteReason
Reason for item wastage (analytics).

```
expired             # Past expiration date
spoiled            # Visible spoilage (mold, smell)
forgotten          # Discovered too late
disliked           # Taste/preference issue
overestimated      # Bought too much
duplicate          # Already had some
other              # Catch-all
```

### EventType
Types of tracked events.

```
item_created
item_edited
item_consumed
item_wasted
item_expired_auto      # System-marked as expired
shopping_item_added
shopping_item_purchased
shopping_converted     # Shopping list → inventory
reminder_sent
reminder_opened
```

---

## Relationships

```
Item (1) ──→ (n) Event
  └─ item_id foreign key

ShoppingListItem ──converts to──→ Item
  └─ On purchase, creates new Item with shopping list data
```

**Conversion Logic:**
When `ShoppingListItem.is_purchased = true`:
1. Create `Item` with same name, category, quantity, unit
2. Set `Item.purchase_date = ShoppingListItem.purchased_at`
3. If `ShoppingListItem.estimated_cost` is set, initialize `Item.cost = ShoppingListItem.estimated_cost`; otherwise leave `Item.cost = null` until the user confirms the actual purchase cost
4. Log `Event` with `event_type = shopping_converted`
5. Shopping list item remains for historical tracking

---

## Migration Strategy

### Version Tracking
- Store `schema_version` in local metadata table
- Current version: **v1.0.0**
- Version format: Semantic versioning (MAJOR.MINOR.PATCH)

### Migration Approach
1. **Additive Changes (MINOR):** Add new optional fields with defaults
   - Example: Adding `Item.barcode` field (nullable)
   - Backward compatible, old app versions ignore new fields

2. **Breaking Changes (MAJOR):** Require app update
   - Example: Renaming `quantity` to `amount`
   - Show in-app prompt: "Update required for new features"

3. **Data Patches (PATCH):** Fix data inconsistencies
   - Example: Normalize category values after enum expansion
   - Run on app startup if `schema_version` mismatch detected

### Migration Scripts
Located in: `app/lib/data/migrations/`

Pattern:
```dart
// migration_v1_to_v2.dart
Future<void> migrate(Database db) async {
  await db.execute('ALTER TABLE items ADD COLUMN barcode TEXT');
  await db.execute('UPDATE metadata SET schema_version = "2.0.0"');
}
```

### Rollback Strategy
- Maintain last 2 schema versions for compatibility
- Pro tier: Cloud backup before major migrations
- Grace period: 30 days warning before forcing update

---

## Usage Guidelines

### For Developers
1. **Adding Fields:** Always add as nullable with defaults for backward compatibility
2. **Enums:** Never remove enum values (mark deprecated instead)
3. **Indexes:** Add composite indexes for common query patterns
4. **Events:** Log all state changes for analytics and debugging
5. **Partial Consumption/Wastage:** 
   - Update `quantity_consumed` or `quantity_wasted` fields when user records usage
   - Validate: `quantity_consumed + quantity_wasted ≤ quantity`
   - Update status to `consumed` or `wasted` only when fully used
   - Log `item_consumed` or `item_wasted` events with quantity in metadata

### For AI Agents
This is the **authoritative schema**. When generating code:
- Use exact field names (snake_case in DB, camelCase in Dart)
- Respect nullability constraints
- Include proper indexes in repository layer
- Log events for all CRUD operations

### Query Patterns

**Expiring Soon:**
```sql
SELECT * FROM items 
WHERE status = 'active' 
  AND expiry_date BETWEEN NOW() AND NOW() + INTERVAL 7 DAY
ORDER BY expiry_date ASC;
```

**Waste Analysis:**
```sql
SELECT category, COUNT(*), AVG(quantity) 
FROM items 
WHERE status = 'wasted' 
  AND created_at >= NOW() - INTERVAL 30 DAY
GROUP BY category;
```

**Money Saved/Wasted (Proportional):**
```sql
-- Money utilized (proportional to consumed quantity)
SELECT SUM(
  CASE 
    WHEN quantity > 0 THEN cost * (quantity_consumed / quantity)
    ELSE 0
  END
) as money_utilized
FROM items
WHERE updated_at >= NOW() - INTERVAL 30 DAY
  AND cost IS NOT NULL
  AND quantity_consumed > 0;

-- Money wasted (proportional to wasted quantity)
SELECT category, 
  SUM(
    CASE 
      WHEN quantity > 0 THEN cost * (quantity_wasted / quantity)
      ELSE 0
    END
  ) as money_wasted,
  COUNT(*) as items_affected,
  SUM(quantity_wasted) as total_quantity_wasted
FROM items
WHERE updated_at >= NOW() - INTERVAL 30 DAY
  AND cost IS NOT NULL
  AND quantity_wasted > 0
GROUP BY category;

-- Combined view: items with partial consumption/wastage
SELECT name, quantity, quantity_consumed, quantity_wasted,
  (quantity - quantity_consumed - quantity_wasted) as remaining,
  cost,
  CASE 
    WHEN quantity > 0 THEN cost * (quantity_consumed / quantity)
    ELSE 0
  END as money_utilized,
  CASE 
    WHEN quantity > 0 THEN cost * (quantity_wasted / quantity)
    ELSE 0
  END as money_wasted
FROM items
WHERE cost IS NOT NULL
  AND (quantity_consumed > 0 OR quantity_wasted > 0)
  AND updated_at >= NOW() - INTERVAL 30 DAY;
```

---

## Cost Tracking

### Purpose
Track financial impact of food waste to motivate behavior change and calculate value recovered from food that is actually used.

### Implementation Notes
- **Optional Field:** `cost` is nullable (not all users track prices)
- **Currency Agnostic:** Store as decimal; UI handles currency formatting based on locale
- **Privacy:** Cost data stays local-only in MVP; Pro tier aggregates anonymously
- **Receipt OCR:** Pro feature can extract costs from receipts (M6)
- **Insights:** Show "Money Utilized" vs "Money Wasted" in dashboard (M6/490)

### Calculation Examples
- **Item fully consumed before expiry:** 
  - `quantity_consumed = quantity` → Cost × 100% → "Money Utilized"
- **Item fully wasted:** 
  - `quantity_wasted = quantity` → Cost × 100% → "Money Wasted"
- **Item partially consumed, partially wasted (e.g., loaf of bread):**
  - Purchase: 1 loaf @ $3.00, `quantity = 1`
  - Consume half: `quantity_consumed = 0.5` → Money Utilized = $3.00 × 0.5 = $1.50
  - Waste half: `quantity_wasted = 0.5` → Money Wasted = $3.00 × 0.5 = $1.50
  - Item status transitions to `wasted` (fully used up)
- **Item partially consumed, still active:**
  - Purchase: 2 lbs chicken @ $12.00, `quantity = 2`
  - Consume 1 lb: `quantity_consumed = 1` → Money Utilized = $6.00
  - Remaining: 1 lb, status stays `active`
- **Monthly value utilized:** Sum of all items' `cost × (quantity_consumed / quantity)`
- **Waste reduction ROI:** Compare month-over-month waste costs

---

## How It Will Be Used

- **M2/100** - Local storage implementation (Hive/sqflite setup)
- **M2/140-170** - MVP screens (inventory, expiring soon, item detail)
- **M3/250** - Telemetry instrumentation (event logging)
- **M6** - Analytics and insights (query patterns)
- **Pro Tier** - Cloud sync (schema compatibility with backend)

---

## Validation Checklist

- [x] All MVP entities defined (Item, ShoppingListItem, Event)
- [x] Required fields for item management (name, category, location, quantity, expiry)
- [x] Partial consumption/wastage tracking fields added (quantity_consumed, quantity_wasted)
- [x] Business rules documented for partial usage scenarios
- [x] Proportional cost calculation queries provided
- [x] Enums have ≥3 values (Category: 15, Location: 5, WasteReason: 7, Status: 4, EventType: 10)
- [x] Migration strategy includes versioning approach
- [x] Relationships documented (Item → Events)
- [x] Indexes defined for performance
- [x] Query patterns provided for common use cases

---

## Source Material
- Issue: `planning/milestones/M1/080-define-v1-data-model-item-category-location-events.md`
- PRD: `planning/docs/prd/ZeroSpoils_Market_Report_FINAL_fixed_citations.md` (Section 8.4)

## Status
✅ **COMPLETE** - Reviewed and validated for M1/080 acceptance criteria.
