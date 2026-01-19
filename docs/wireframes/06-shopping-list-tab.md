# Wireframe 6: Shopping List Tab

## Purpose
User creates and manages curated shopping lists with suggested items based on inventory + recipes (future), organized by category. Items can be added directly or from Inventory screen.

## Cross-Tab Integration (New in M1)
**From Inventory List:** Long-press or tap menu on any item → "Add to Shopping List" → Select list from dropdown → Toast confirmation → Item appears in Shopping List tab. See [Wireframe 01: Inventory List](./01-inventory-list.md) for details.

## Layout
```
┌─────────────────────────────────┐
│ Shopping List              ⚙️    │  ← Tab title, settings button
├─────────────────────────────────┤
│  🔍 [Search items...      ]     │  ← SearchBar (48pt height)
├─────────────────────────────────┤
│  ✏️ [Add New Item]               │  ← Quick add button
├─────────────────────────────────┤
│ MY LISTS (1 active list)        │  ← Section header
├─────────────────────────────────┤
│ ▼ Weekly Groceries (5 items)    │  ← List accordion header (expandable)
├─────────────────────────────────┤
│ ☐ 🥛 Milk          qty: 1      │  ← Checkbox item, quantity
│ ☐ 🧀 Cheddar        qty: 1      │
│ ☑️ 🥕 Carrots        qty: 2      │  ← Checked item
│ ☐ 🥬 Spinach        qty: 1      │
│ ☐ 🥦 Broccoli       qty: 1      │
├─────────────────────────────────┤
│ SUGGESTED (Based on Inventory)  │  ← Suggested section
├─────────────────────────────────┤
│ ☐ 🥔 Potatoes       qty: 5      │  ← Suggestion from low stock
│ ☐ 🍎 Apples         qty: 4      │
├─────────────────────────────────┤
│  [Checkout / Share List]        │  ← Action button
│                                 │
└─────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| AppBar | 56pt | Title + settings |
| SearchBar | 48pt | Filter list by item name |
| Add Item Button | 48pt | Quick add to current list |
| List Header (Accordion) | 40pt | List title + item count, collapsible |
| List Item | 48pt | Item checkbox + emoji + name + quantity |
| Suggested Section | 40pt | Header for AI/rule-based suggestions |
| Suggested Item | 48pt | Item checkbox + name, quantity editable |
| Action Button | 48pt | Share, export, or checkout CTA |

---

## Interactions
1. **Tap SearchBar** → Filter items by name/category across all lists
2. **Tap checkbox on item** → Toggle item purchased (strikethrough or lighter color)
3. **Tap item row** → Expand/edit quantity, notes, or remove
4. **Tap Add New Item button** → Open quick-add form (same modal as Inventory Add Item)
5. **Tap list accordion header** → Collapse/expand items in that list
6. **Swipe left on item** → Delete from list, show undo
7. **Long-press item** → Show context menu (edit, delete, move to another list)
8. **Tap Checkout button** → Share or export list (SMS, email, clipboard)

---

## List Management
| Action | Behavior |
|--------|----------|
| **Create new list** | Tap "+" next to "My Lists", name it (e.g., "Weekly Groceries") |
| **Rename list** | Tap menu (⋮) on list accordion, select "Rename" |
| **Delete list** | Tap menu (⋮), confirm deletion |
| **Archive list** | Tap menu, "Archive" (hides but doesn't delete) |
| **Duplicate list** | Tap menu, "Duplicate" (clone for recurring lists) |

---

## Quantity Management
- **Default:** 1 unit
- **Adjust:** Tap item row to open quantity picker (spinner or +/- buttons)
- **Units:** Count-based (1, 2, 3...) for MVP, pounds/kg in v2
- **Display:** Show as "qty: 2" or "2× Milk"

---

## Accessibility
- [ ] Checkboxes large enough (≥44pt tap target)
- [ ] Item rows full width (easy to tap)
- [ ] Strikethrough vs. disabled state clear (not color-only)
- [ ] List headers semantic structure (h2 or role="heading")
- [ ] Quantity input accessible (spinner with +/- buttons)
- [ ] Context menu items labeled (edit, delete, move)
- [ ] Font scales to 2x without breaking layout
- [ ] Emoji alt text provided for screen readers

---

## Empty State

### Scenario 1: No Lists
```
┌─────────────────────────────────┐
│ Shopping List              ⚙️    │
├─────────────────────────────────┤
│  🔍 [Search items...      ]     │
├─────────────────────────────────┤
│  ✏️ [Add New Item]               │
├─────────────────────────────────┤
│                                 │
│        🛒 No lists yet          │
│                                 │
│     "Create your first          │
│      shopping list to get       │
│      started"                   │
│                                 │
│     [Create List]               │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Scenario 2: No Items in List
```
┌─────────────────────────────────┐
│ Shopping List              ⚙️    │
├─────────────────────────────────┤
│ ▼ Weekly Groceries (0 items)    │
├─────────────────────────────────┤
│                                 │
│      🛒 List is empty           │
│                                 │
│     "Add items or view          │
│      suggestions from your      │
│      inventory"                 │
│                                 │
│     [Add Item] [View Suggestions]
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

## Suggested Items Logic
- **Trigger:** Auto-generated based on low-stock items in Inventory
- **Frequency:** Refreshed when list opened (1 hour cache)
- **Examples:**
  - Item expires in <3 days → suggest related items
  - Item low in quantity → suggest replenishment
  - Category patterns → suggest complementary items (e.g., if "Milk" → suggest "Bread")
- **Dismissal:** Remove suggestion (don't show again), or add to list

---

## Telemetry Events
- `shopping_list_opened` - {list_count: int, suggested_count: int}
- `list_created` - {list_name: str, source: "manual" | "suggested"}
- `item_added_to_list` - {item_name: str, list_name: str, quantity: int}
- `item_checked` - {item_name: str, checked: bool}
- `item_deleted_from_list` - {item_name: str, list_name: str}
- `list_shared` - {list_name: str, method: "sms" | "email" | "clipboard"}
- `suggested_item_viewed` - {item_name: str}
- `suggested_item_added` - {item_name: str, list_name: str}

---

## Notes
- Sync: Shopping lists sync to backend for multi-device access (v2+)
- Offline: Lists available offline, sync when online
- Recurring lists: Allow marking lists as "recurring" (weekly, monthly) for auto-creation
- Integration: Link from Inventory "Add to Shopping List" button (M1 — implemented via long-press menu)
- Voice input: "Add milk to grocery list" via voice assistant (v2+)
- Sharing: QR code option for sharing lists with family (v2+)
- **Future Feature (v2):** Display inventory quantity next to shopping list items:
  ```
  ☐ 🥛 Milk (2 in inventory)    qty: 1
  ☐ 🥕 Carrots (none left)      qty: 2
  ☐ 🥬 Spinach (1 wilting)      qty: 1
  ```
  This helps users see what they already have while shopping, reducing overbuying and food waste.
