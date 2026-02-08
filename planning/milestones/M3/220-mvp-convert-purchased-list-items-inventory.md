## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver conversion of purchased shopping list items into inventory items with expiry-date prompt, tests, and telemetry.

## Expected behavior
- From Shopping List, checking an item as purchased triggers a convert dialog
- Convert dialog collects expiry date (required) and optional storage location
- Convert action creates Inventory item and removes item from Shopping List
- Skip keeps item in Purchased section for later conversion
- Batch convert button processes all purchased items sequentially
- Works offline without requiring login
- Error and empty states handled

## Acceptance criteria (Definition of Done)
- [x] Convert dialog opens when a purchased item is checked
- [x] Convert dialog requires expiry date; validation prevents submit without date
- [x] Convert action creates Inventory item with:
  - name, category (if present), quantity/unit
  - expiry_date (from dialog)
  - purchase_date (set to now)
  - location (optional selection)
  - status = available
- [x] Converted item removed from Shopping List (unpurchased/purchased sections update)
- [x] Skip leaves item in Purchased section with no changes
- [x] Batch convert button processes all purchased items with per-item dialog
- [x] Telemetry events emitted:
  - `shopping_converted` { item_id, entry_method: "shopping_convert", had_location: bool }
  - `shopping_convert_skipped` { item_id }
- [x] Unit/widget/integration tests added or updated
- [x] Offline-first behavior verified
- [x] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud sync
- Receipt scanning
- Household sharing

## Implementation notes
- Follow design tokens in theme.
- Keep domain/data/ui separation.
- Convert dialog is a bottom sheet with date picker + optional location dropdown
- After convert, schedule notification using existing item repository flow
- Use repository layer: ShoppingListRepository + ItemRepository
- Avoid text-based widget finds in tests; use keys

## Test plan
**Automated:**
- Widget test: checking item opens convert dialog
- Widget test: cannot submit without expiry date
- Widget test: submit creates inventory item and removes list item
- Widget test: skip keeps item in purchased section
- Widget test: batch convert processes multiple purchased items
- Unit test: conversion maps fields correctly to Item model

**Manual:**
1. Check a shopping item → convert dialog appears
2. Enter expiry date + location → convert → item appears in Inventory
3. Verify item removed from Shopping List
4. Use batch convert for 2+ purchased items
5. Skip conversion and confirm item remains in Purchased

## Dependencies
- M2/101 shopping list repository persistence
- M2/140 add item screen (for consistent item field handling)
