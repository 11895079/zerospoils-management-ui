# Wireframe 3: Item Detail Screen

## Purpose
User views full item details, edits, or deletes. Accessible via tapping item from inventory list.

## Layout
```
┌─────────────────────────────────┐
│ ← Item Details              ⋮   │  ← Back arrow, menu button (3 dots)
├─────────────────────────────────┤
│                                 │
│  🥛 Milk                        │  ← Category emoji + name (large)
│                                 │
├─────────────────────────────────┤
│  Status                         │
│  ┌──────────────────────────────┐
│  │ ✓ Good (3 days left)        │  ← Status badge (green/yellow/red)
│  └──────────────────────────────┘
├─────────────────────────────────┤
│  Category                       │
│  Dairy                          │
├─────────────────────────────────┤
│  Expiry Date                    │
│  Thursday, 14 March 2025        │
├─────────────────────────────────┤
│  Added                          │
│  2 weeks ago (11 March)         │
├─────────────────────────────────┤
│  Notes                          │
│  ┌──────────────────────────────┐
│  │ Open - store in back of      │
│  │ fridge                       │
│  └──────────────────────────────┘
├─────────────────────────────────┤
│  Quick Actions                  │
│  ┌─────────────┐  ┌──────────┐
│  │  ✏️ Edit    │  │  🗑️ Delete   │
│  └─────────────┘  └──────────┘
│                                 │
└─────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| AppBar | 56pt | Back button, title, menu (⋮) |
| Item Header | 64pt | Category emoji + name (large text) |
| Status Badge | 40pt | Color-coded status + text |
| Detail Row | 48pt | Label + value (editable field-like) |
| Notes Section | 96pt | Read-only multi-line text |
| ButtonRow | 48pt | Edit + Delete action buttons |

## Status Badge Colors
- **Green:** >3 days to expiry ("Good")
- **Yellow:** 1-3 days to expiry ("Expiring Soon")
- **Red:** <1 day to expiry or past expiry ("Use Today" or "Expired")

## Interactions
1. **Tap Back arrow** → Return to inventory list
2. **Tap menu (⋮)** → Show menu with Edit / Delete / Share options
3. **Tap Edit button** → Navigate to edit screen (same as Add Item modal but prefilled)
4. **Tap Delete button** → Show confirmation dialog
5. **Swipe back** → Return to inventory list (iOS standard)

## Menu Options (⋮ button)
```
┌──────────────────┐
│ Edit             │  → Opens edit modal with current values
│ Delete           │  → Shows delete confirmation
│ Mark as Used     │  → Remove item from inventory + telemetry
│ Share            │  → Copy item to clipboard or share (v2+)
└──────────────────┘
```

## Accessibility
- [ ] Back button is ≥44pt tap target
- [ ] Menu button is ≥44pt tap target
- [ ] Status badge uses color + icon + text (not color-only)
- [ ] Detail labels are semantic headings or labels
- [ ] Notes text has sufficient contrast (≥4.5:1)
- [ ] Font scales to 2x without breaking layout
- [ ] Screen reader announces item name on load
- [ ] All interactive elements (buttons) labeled

## Delete Confirmation Dialog
If user taps Delete or menu → Delete:
```
┌────────────────────────────────┐
│  Delete Item?                  │
├────────────────────────────────┤
│  Are you sure you want to      │
│  delete "Milk"?                │
│  This cannot be undone.        │
│                                │
│  ┌──────────┐  ┌────────────┐
│  │ Cancel   │  │ Delete     │  ← Red button
│  └──────────┘  └────────────┘
└────────────────────────────────┘
```

## Telemetry Events
- `item_detail_opened` - {item_id: str, category: str, days_left: int}
- `item_edit_tapped` - {item_id: str}
- `item_delete_tapped` - {item_id: str}
- `item_mark_used_tapped` - {item_id: str, category: str}
- `item_deleted` - {item_id: str, category: str, days_left_at_delete: int}
- `menu_tapped` - {item_id: str}

## Edit Behavior
When user taps Edit:
1. Navigate to edit screen (similar modal to Add Item)
2. Prefill with current values
3. Allow user to change name, category, expiry, notes
4. Validate same as Add Item
5. On save, update item on backend
6. Return to detail screen with updated values

## Notes
- Detail screen is read-only by default; edit via modal or menu
- Status updates in real-time as days pass (date-aware UI)
- "Added 2 weeks ago" calculates from item creation date
- If item expired, show clear warning at top: "🚨 This item has expired"

## Empty State
The Item Detail screen assumes a valid item context (navigated from an inventory list or deep link).
There is no separate "empty" variant of this screen; if the item cannot be loaded (e.g., deleted or missing),
the app should handle this by showing an error message and redirecting the user back to the inventory list
or a generic error/empty-state pattern defined for inventory navigation.
