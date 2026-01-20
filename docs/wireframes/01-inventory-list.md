# Wireframe 1: Inventory List Screen

## Purpose
User sees all tracked items grouped by category. Tap to view details, swipe to delete, search to filter.

## Layout
```
┌─────────────────────────────────┐
│ Home                        ⚙️    │  ← App bar with settings button
├─────────────────────────────────┤
│  🔍 [Search items...        ]    │  ← SearchBar (48pt height)
├─────────────────────────────────┤
│ DAIRY (3 items)                 │  ← Category header
├─────────────────────────────────┤
│ 🥛 Milk                    3d   │  ← ItemCard: 64pt height
│ 📅 Expires Thu 14 Mar     →    │  ← Shows expiry & ">" arrow
├─────────────────────────────────┤
│ 🧈 Butter                  6d   │
│ 📅 Expires Sun 17 Mar     →    │
├─────────────────────────────────┤
│ 🧀 Cheddar (open)          2d   │  ← Urgent item (yellow bg)
│ 📅 Expires Tue 12 Mar     →    │
├─────────────────────────────────┤
│ VEGETABLES (2 items)            │
├─────────────────────────────────┤
│ 🥕 Carrots                  8d   │
│ 📅 Expires Mon 18 Mar     →    │
├─────────────────────────────────┤
│ 🥬 Spinach (wilting)        1d   │  ← Critical item (orange bg)
│ 📅 Expires Mon 12 Mar     →    │
├─────────────────────────────────┤
│                             ⊕    │  ← FAB: Add Item (56pt circle)
└─────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| AppBar | 56pt | Header with settings button |
| SearchBar | 48pt | Filter items by name/category |
| CategoryHeader | 40pt | Section label (caps, gray bg) |
| ItemCard | 64pt | Item with category emoji, name, days left, expiry date |
| FAB | 56pt | Floating action button to add item |

## Color Coding
- **Normal (white bg):** >3 days until expiry
- **Yellow bg:** 1-3 days until expiry
- **Orange bg:** <1 day until expiry
- **Gray text:** Category header, "Expires" label

## Interactions
1. **Tap item** → Navigate to item detail screen with edit/delete options
2. **Swipe left on item** → Reveal delete button, tap to confirm
3. **Tap SearchBar** → Enter search mode, show matching items only
4. **Tap category header** → Collapse/expand category (optional v1)
5. **Tap FAB** → Open "Add Item" modal (see wireframe 02)
6. **Tap settings** → Navigate to Settings screen
7. **Long-press item (or tap menu icon)** → Show context menu:
   - "View Details" → Navigate to Item Detail
   - "Add to Shopping List" → Show list selection dropdown
   - "Delete" → Delete confirmation
8. **Tap "Add to Shopping List"** → Show dropdown of available lists:
   ```
   Select List to Add To:
   [Weekly Groceries ✓] (active list)
   [Trader Joe's]
   [Whole Foods]
   [+ Create New List]
   ```
9. **Select list from dropdown** → Add item to that list, show toast:
   ```
   ✓ Added to Weekly Groceries
   (auto-dismisses in 2-3 seconds)
   ```
   - User can tap toast to navigate to Shopping List tab
   - Or continue browsing Inventory

## Accessibility
- [ ] Tap targets ≥44pt (ItemCard, FAB, SearchBar)
- [ ] SearchBar placeholder text visible
- [ ] Category headers semantic headings (`<h3>`)
- [ ] Emoji followed by text label (not emoji-only)
- [ ] Color not sole indicator—use text "EXPIRES IN 2D" or yellow bg + text
- [ ] Font scales to 2x size without overflow
- [ ] Date text has sufficient contrast (>4.5:1)

## Empty State
```
┌─────────────────────────────────┐
│ Home                        ⚙️    │
├─────────────────────────────────┤
│  🔍 [Search items...        ]    │
├─────────────────────────────────┤
│                                 │
│                                 │
│            📭 No items yet      │  ← Icon + message
│                                 │
│     "Add your first item to     │
│      start tracking food waste" │
│                                 │
│            [Add Item]           │  ← CTA button → FAB
│                                 │
│                                 │
└─────────────────────────────────┘
```

## Telemetry Events
- `inventory_opened` - {item_count: int, category_count: int}
- `item_tapped` - {item_id: str, category: str, days_left: int}
- `item_swiped_delete` - {item_id: str, category: str}
- `search_initiated` - {query: str}
- `add_item_tapped` - {from_screen: "inventory_list"}
- `add_to_shopping_list_tapped` - {item_id: str, item_name: str}
- `shopping_list_selected` - {item_id: str, list_name: str, list_id: str}
- `shopping_list_toast_shown` - {list_name: str, duration_ms: int}
- `shopping_list_toast_tapped` - {list_name: str} (navigate to Shopping tab)

## Notes
- Items sorted by days-to-expiry (most urgent first within category)
- Category grouping decided by backend; frontend receives sorted list
- ScrollView when >5 categories; smooth scrolling
- Pull-to-refresh clears search and reloads inventory (v2+)
