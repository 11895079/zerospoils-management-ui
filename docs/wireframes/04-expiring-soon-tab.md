# Wireframe 4: Expiring Soon Tab

## Purpose
User sees items expiring in next 7 days at a glance. Quick prioritization of what to use first.

## Layout
```
┌─────────────────────────────────┐
│ Expiring Soon                ⚙️  │  ← Tab title, settings button
├─────────────────────────────────┤
│                                 │
│  🚨 3 items expiring this week  │  ← Alert banner (if any urgent items)
│                                 │
├─────────────────────────────────┤
│ TODAY (1 item)                  │  ← Day section header (red)
├─────────────────────────────────┤
│ 🥬 Spinach (wilting)        USE  │  ← Urgent item card
│ 📅 Expires Today           →    │
├─────────────────────────────────┤
│ TOMORROW (1 item)               │  ← Day section header (orange)
├─────────────────────────────────┤
│ 🧀 Cheddar (open)          1d   │
│ 📅 Expires Fri 13 Mar     →    │
├─────────────────────────────────┤
│ IN 2-3 DAYS (1 item)            │  ← Day section header (yellow)
├─────────────────────────────────┤
│ 🥛 Milk                    3d   │
│ 📅 Expires Thu 14 Mar     →    │
├─────────────────────────────────┤
│                                 │
│  ✅ No more items expiring     │  ← Rest of week message
│     this week                  │
│                                 │
│                                 │
│                             ⊕    │  ← FAB: Add Item
└─────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| Tab Header | 56pt | "Expiring Soon" title + settings |
| Alert Banner | 48pt | Summary of urgent items (red bg) |
| DayHeader | 40pt | Date range label (TODAY, TOMORROW, IN 2-3 DAYS) |
| ItemCard | 64pt | Item with emoji, name, days/status, expiry date |
| FAB | 56pt | Add Item button |

## Day Groupings
- **TODAY:** Items expiring on today's date (red header, "USE NOW" status)
- **TOMORROW:** Items expiring tomorrow (orange header)
- **IN 2-3 DAYS:** Items expiring in 2-3 days (yellow header)
- **IN 4-7 DAYS:** Items expiring in 4-7 days (light blue header, optional collapse)

## Item Card Variations
- **TODAY:** Shows "USE NOW" in red, category emoji, no "days left" count
- **TOMORROW:** Shows "1D" or "Tomorrow"
- **LATER:** Shows "2D", "3D", etc.

## Alert Banner
Shows only if items expiring TODAY or TOMORROW:
```
┌─────────────────────────────────┐
│ 🚨 3 items expiring this week   │  ← Red bg, emoji + count
│    Use or store carefully        │
└─────────────────────────────────┘
```

If no urgent items: Hide banner, show message below.

## Interactions
1. **Tap item** → Navigate to item detail screen
2. **Swipe left on item** → Reveal delete button, confirm to delete
3. **Tap FAB** → Open "Add Item" modal
4. **Tap day header** → Collapse/expand day section (optional v1, default expanded)

## Empty States

### Scenario 1: No Items Expiring This Week
```
┌─────────────────────────────────┐
│ Expiring Soon                ⚙️  │
├─────────────────────────────────┤
│                                 │
│                                 │
│          ✅ No items expiring   │
│             this week           │
│                                 │
│        Check back soon!         │
│                                 │
│                                 │
│                             ⊕    │
└─────────────────────────────────┘
```

### Scenario 2: No Items at All
```
┌─────────────────────────────────┐
│ Expiring Soon                ⚙️  │
├─────────────────────────────────┤
│                                 │
│        📭 No items yet          │
│                                 │
│    "Start adding items to       │
│     your inventory to track     │
│     expiry dates"              │
│                                 │
│          [Add Item]             │
│                                 │
│                             ⊕    │
└─────────────────────────────────┘
```

## Accessibility
- [ ] Tap targets ≥44pt (item cards, FAB, day header collapse)
- [ ] Color not sole indicator—use day labels + text descriptions
- [ ] Alert banner uses icon + text, not color-only
- [ ] Day header is semantic heading
- [ ] Item cards follow same a11y rules as inventory list
- [ ] Font scales to 2x without breaking layout
- [ ] Red text for "USE NOW" has sufficient contrast (≥4.5:1)

## Sorting & Display Logic
1. Sort by expiry date (nearest first)
2. Group by day
3. If >5 items in a day, allow scroll within group (no collapse by default)
4. Re-calculate on each screen open (fresh data)
5. Real-time updates if item expires while app open (v2+)

## Telemetry Events
- `expiring_soon_opened` - {total_expiring: int, urgent_count: int}
- `item_tapped` - {item_id: str, category: str, days_left: int}
- `add_item_tapped` - {from_screen: "expiring_soon"}
- `day_section_collapsed` - {day: "TODAY" | "TOMORROW" | "IN_2_3_DAYS"}
- `alert_banner_viewed` - {urgent_count: int}

## Performance Considerations
- Pre-fetch expiring items when app loads (M1/090 home shell)
- Cache for 1 hour or until item added/deleted
- Lazy-load items beyond 7-day window (v2+)
- Use date arithmetic server-side to reduce client logic

## Notes
- Tab should refresh every time user opens it (pull data fresh)
- Expired items (past expiry) do NOT appear here; handle in item detail or separate tab (v2)
- Color scheme matches home screen (yellow=warning, orange=urgent, red=critical)
- This tab encourages waste reduction by highlighting immediate action items
