# Wireframe 8: Empty States Guide

## Purpose
Comprehensive reference for empty state designs across all ZeroSpoils screens, ensuring consistent messaging and visual treatment when no data is available.

---

## Empty State Principles

### Structure
Every empty state should include:
1. **Icon** (48–64pt) – Decorative emoji or illustration representing the situation
2. **Headline** (16–18pt, semi-bold) – What's missing ("No items yet", "List is empty")
3. **Description** (14pt, regular) – Why it's empty + benefit of adding content
4. **Call-to-Action** (optional) – Primary button to create/add first item

### Tone
- Friendly, encouraging, not apologetic
- Explain the benefit of taking action
- Suggest next steps without being pushy

### Visual Treatment
- Centered on screen (vertical & horizontal)
- Icon color: Primary blue (#2196F3) or neutral gray
- Headline in dark text (#212121)
- Description in medium gray (#666666)
- Button primary blue for primary action

---

## Screen-by-Screen Empty States

### 1. Onboarding (No empty state)
N/A — Onboarding screens always have content.

---

### 2. Inventory List

#### Scenario A: No Items at All
```
┌─────────────────────────────────┐
│ Home                        ⚙️    │
├─────────────────────────────────┤
│  🔍 [Search items...      ]     │
├─────────────────────────────────┤
│                                 │
│                                 │
│         📭 No items yet         │
│                                 │
│    "Start tracking your food    │
│     to reduce waste and save    │
│     money"                      │
│                                 │
│         [Add Item]              │
│                                 │
│                             ⊕    │
│                                 │
└─────────────────────────────────┘
```

#### Scenario B: Search with No Results
```
┌─────────────────────────────────┐
│ Home                        ⚙️    │
├─────────────────────────────────┤
│  🔍 [Olive oil        ]  ✕      │
├─────────────────────────────────┤
│                                 │
│         🔍 No matches           │
│                                 │
│    "No items found matching     │
│     'Olive oil'"               │
│                                 │
│     [Clear Search]              │
│                                 │
│                             ⊕    │
│                                 │
└─────────────────────────────────┘
```

---

### 3. Add Item Modal

#### Empty Inputs (No Error)
```
Modal shows:
- Item Name field: empty, placeholder "e.g., Milk"
- Category field: shows default "Dairy"
- Expiry Date: shows today + 7 days (pre-filled)
- Notes: empty, placeholder "e.g., Open"
```

#### Validation Errors (Post-Save Attempt)
```
Item Name: red border, error text "Required"
Category: red border, error text "Required"
Expiry Date: red border, error text "Must be today or later"
```

---

### 4. Item Detail

#### Scenario: Item No Longer Exists
```
┌─────────────────────────────────┐
│ ← Item Details              ⋮    │
├─────────────────────────────────┤
│                                 │
│      ⚠️ Item Not Found          │
│                                 │
│    "This item has been         │
│     deleted from your          │
│     inventory"                 │
│                                 │
│     [Back to Inventory]         │
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

### 5. Expiring Soon Tab

#### Scenario A: No Items Expiring This Week
```
┌─────────────────────────────────┐
│ Expiring Soon               ⚙️    │
├─────────────────────────────────┤
│                                 │
│                                 │
│      ✅ All good!               │
│                                 │
│    "No items expiring this     │
│     week. Check back soon!"    │
│                                 │
│                                 │
│                             ⊕    │
│                                 │
└─────────────────────────────────┘
```

#### Scenario B: No Items at All
```
┌─────────────────────────────────┐
│ Expiring Soon               ⚙️    │
├─────────────────────────────────┤
│                                 │
│      📭 No items yet            │
│                                 │
│    "Start adding items to      │
│     track expiry dates"        │
│                                 │
│     [Add Item]                  │
│                                 │
│                             ⊕    │
│                                 │
└─────────────────────────────────┘
```

---

### 6. Shopping List Tab

#### Scenario A: No Lists Created
```
┌─────────────────────────────────┐
│ Shopping List              ⚙️    │
├─────────────────────────────────┤
│  🔍 [Search items...      ]     │
│  ✏️ [Add New Item]               │
├─────────────────────────────────┤
│                                 │
│      🛒 No lists yet            │
│                                 │
│    "Create your first list     │
│     for meal planning"         │
│                                 │
│   [Create List]                │
│                                 │
│                                 │
└─────────────────────────────────┘
```

#### Scenario B: List is Empty
```
┌─────────────────────────────────┐
│ Shopping List              ⚙️    │
├─────────────────────────────────┤
│ ▼ Weekly Groceries (0)          │
├─────────────────────────────────┤
│                                 │
│      🛒 List is empty           │
│                                 │
│    "Add items or view          │
│     suggestions from your      │
│     inventory"                 │
│                                 │
│ [Add Item] [View Suggestions]  │
│                                 │
└─────────────────────────────────┘
```

---

### 7. Settings Screen

#### No Empty State
Settings always has content (toggles, preferences, links).

---

### 8. Error States (Cross-Screen)

#### Network Error
```
┌─────────────────────────────────┐
│ [Screen Title]              ⚙️    │
├─────────────────────────────────┤
│                                 │
│      ⚠️ Connection Error        │
│                                 │
│    "Unable to sync data.       │
│     Working offline. Try       │
│     again when online."        │
│                                 │
│     [Retry]   [Dismiss]        │
│                                 │
│                                 │
└─────────────────────────────────┘
```

#### Server Error
```
┌─────────────────────────────────┐
│ [Screen Title]              ⚙️    │
├─────────────────────────────────┤
│                                 │
│      ⚠️ Server Error            │
│                                 │
│    "Something went wrong.      │
│     Please try again later."   │
│                                 │
│     [Retry]   [Contact Support]│
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

## Empty State Components

| Component | Size | Purpose |
|-----------|------|---------|
| Icon | 48–64pt | Emoji or illustration |
| Headline | 16–18pt | What's missing |
| Description | 14pt | Why + benefit |
| Primary Button | 48pt | Create/add action |
| Secondary Button | 48pt | Alternative (dismiss, retry) |

---

## Accessibility

- [ ] Icon is decorative (alt text: "empty state illustration")
- [ ] Headline is semantic (h2 or role="heading")
- [ ] Description text clear and actionable
- [ ] Buttons ≥44pt × 44pt tap targets
- [ ] Color not sole indicator (use emoji + text)
- [ ] Text scales to 2x without overflow
- [ ] CTA button clearly labeled ("Add Item", not just "Go")

---

## Telemetry Events

- `empty_state_viewed` - {screen: str, state_type: "no_items" | "no_results" | "error"}
- `empty_state_cta_tapped` - {screen: str, action: "add_item" | "create_list" | "retry"}
- `empty_state_dismissed` - {screen: str, method: "button" | "back"}

---

## Best Practices for Implementation

### When to Show Empty State
1. **No data fetched yet:** Network request still loading → show skeleton loader, not empty state
2. **Data fetch complete, zero results:** Show empty state with icon + message
3. **User cleared all data:** Show empty state with recovery option ("Undo", "Create first item")

### When NOT to Show Empty State
1. **Loading:** Show progress indicator instead
2. **Error:** Show error message with retry button (separate from empty state)
3. **Filtered list:** Show "no results" variant if filter is active

### Copy Guidelines
- **Headline:** 2–4 words, positive tone
- **Description:** 1–2 sentences, explains benefit of action
- **Button:** Action verb ("Add Item", "Create List"), not generic ("OK", "Go")

### Examples by Screen

#### Inventory (No items)
- Headline: "📭 No items yet"
- Description: "Start tracking your food to reduce waste and save money"
- Button: "Add Item" → FAB interaction

#### Shopping List (No lists)
- Headline: "🛒 No lists yet"
- Description: "Create your first list for meal planning"
- Button: "Create List" → Open new list modal

#### Expiring Soon (No items expiring)
- Headline: "✅ All good!"
- Description: "No items expiring this week. Check back soon!"
- Button: None (or "Add Item" optional)

---

## Offline-First Considerations

- Empty state may indicate offline + zero local data (vs. network error)
- Show clear message: "You're offline. No items synced yet."
- Offer option to add items locally (sync when online)
- Do NOT show "error" state for offline—expected behavior in MVP

---

## Related Documentation
- [Wireframe 01: Inventory List](./01-inventory-list.md)
- [Wireframe 04: Expiring Soon](./04-expiring-soon-tab.md)
- [Wireframe 06: Shopping List](./06-shopping-list-tab.md)
- [UX Patterns: EmptyState Component](../ux-patterns.md#10-emptystate)
