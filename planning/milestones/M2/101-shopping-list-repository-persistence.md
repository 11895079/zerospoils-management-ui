## Context
Shopping list is core to MVP: users need to plan purchases and track what to buy.

## Goal
Implement local persistence for ShoppingListItem with CRUD and query operations.

## Expected behavior
- Create/update/delete shopping list items
- Mark items as purchased
- Query by purchase status
- Data persists across app restarts

## Acceptance criteria (Definition of Done)
- [x] Repository layer abstracts storage (HiveShoppingListRepository)
- [x] CRUD operations implemented (add, get, delete, clear, list all)
- [x] Query operations (getPurchased, getUnpurchased)
- [x] Unit tests added or updated (8+ tests)
- [x] Offline-first behavior verified
- [x] Telemetry added (tracking purchase actions)
- [x] Data persists across restarts
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Shopping list sharing (M6)
- Budget tracking/estimated costs (M4 enhancement)
- Receipt attachment (M6)
- Barcode scanning (M6)
- Price comparison (Pro tier)

## Implementation notes
- Reuse HiveDatabase infrastructure from M2/100
- Schema: id, name, category, quantity, unit, estimated_cost, is_purchased, purchased_at, notes, created_at, updated_at
- Indexes: (id), (is_purchased), (created_at desc) for sorting
- No encryption needed for MVP
- Use TypeAdapter pattern like ItemAdapter for serialization

## Test plan
**Automated:**
- Unit test: saveShoppingListItem persists and retrieves
- Unit test: getAllItems returns all shopping list items
- Unit test: getPurchased filters correctly
- Unit test: getUnpurchased filters correctly
- Unit test: deleteItem removes from storage
- Unit test: markAsPurchased updates purchased_at timestamp
- Unit test: markAsUnpurchased clears purchased_at
- Unit test: Data persists across app restarts

**Manual:**
1. Add 5 items to shopping list \u2192 close app \u2192 reopen \u2192 verify all present
2. Mark 2 items as purchased \u2192 verify badge count updates
3. Delete item \u2192 verify removed after restart
4. Force crash \u2192 reopen \u2192 verify all data intact
5. Test on both iOS and Android emulators

## Dependencies
- M2/100 (HiveDatabase infrastructure)
- Must complete before M2/140 (Add Item screen needs shopping list integration)

## Telemetry
Log events:
- `shopping_list_item_added`: {item_id, category, quantity, unit}
- `shopping_list_item_purchased`: {item_id, days_to_purchase}
- `shopping_list_item_deleted`: {item_id}
