# Wireframe 2: Add Item Modal

## Purpose
User inputs item name, selects category, sets expiry date. Modal overlay on home screen.

## Layout
```
┌────────────────────────────────────────┐
│ Inventory                          ⚙️    │  ← Dimmed home screen below
├────────────────────────────────────────┤
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ← Modal overlay
│ ┌──────────────────────────────────┐   │
│ │  Add Item                     ✕  │   │  ← Modal header + close button
│ ├──────────────────────────────────┤   │
│ │                                  │   │
│ │  Item Name *                     │   │
│ │  [_____________________]         │   │  ← TextInput, placeholder "e.g. Milk"
│ │                                  │   │
│ │  Category *                      │   │
│ │  ┌──────────────────────────────┐│   │
│ │  │ Dairy                      ▼ ││   │  ← Dropdown, shows "Dairy" (selected)
│ │  └──────────────────────────────┘│   │
│ │                                  │   │
│ │  Expiry Date *                   │   │
│ │  [📅 Mar 14, 2025]            ▼ │   │  ← Date picker field
│ │                                  │   │
│ │  Notes (optional)                │   │
│ │  [_____________________]         │   │  ← TextInput, multiline hint "e.g. Open"
│ │                                  │   │
│ │  ┌──────────────┐  ┌───────────┐│   │
│ │  │  Cancel      │  │  Save     ││   │  ← 2 buttons, Save primary (blue)
│ │  └──────────────┘  └───────────┘│   │
│ │                                  │   │
│ └──────────────────────────────────┘   │
│                                        │
│  (Dimmed inventory list below)         │
└────────────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| Modal header | 56pt | Title + close button (X) |
| TextInput (Item Name) | 48pt | Single-line input |
| Dropdown (Category) | 48pt | Select from category list |
| DatePicker | 48pt | Tap to select expiry date |
| TextInput (Notes) | 96pt | Multi-line optional field |
| ButtonPrimary (Save) | 48pt | Confirm and close modal |
| ButtonSecondary (Cancel) | 48pt | Discard and close modal |

## Interactions
1. **Tap Item Name field** → Focus input, show keyboard
2. **Tap Category dropdown** → Expand dropdown menu showing all categories
3. **Select category** → Update dropdown value, close menu
4. **Tap Expiry Date field** → Open date picker (native iOS/Android picker)
5. **Select date** → Update field, close picker
6. **Tap Save** → Validate inputs, POST to backend, close modal, refresh inventory
7. **Tap Cancel or X** → Close modal without saving
8. **Tap outside modal** → Close modal (optional; confirm first?)

## Validation
- **Item Name:** Required, max 50 chars, trim whitespace
- **Category:** Required, one of predefined list (Dairy, Vegetables, Grains, etc.)
- **Expiry Date:** Required, must be today or future date, reject past dates
- **Notes:** Optional, max 200 chars
- **On Save error:** Show toast with error message (e.g., "Failed to save. Try again.")

## Accessibility
- [ ] All inputs have visible labels (not just placeholders)
- [ ] Tap targets ≥44pt (inputs, buttons, dropdown toggle)
- [ ] Close button (X) is large enough and labeled "Close"
- [ ] Error messages linked to input via ARIA (or semantic equivalent)
- [ ] Date picker keyboard accessible (keyboard shortcuts)
- [ ] Modal focuses first input on open
- [ ] Escape key closes modal
- [ ] Color not sole indicator for required fields—use asterisk (*) + text

## Category List
Shown when dropdown is expanded:
```
▼ Dairy
  Vegetables
  Grains
  Meat & Fish
  Prepared Foods
  Condiments
  Beverages
  Other
```

## Date Picker (Native)
- iOS: Use `CupertinoDatePicker` (wheel-style)
- Android: Use `showDatePicker` (Material date picker)
- Default to today + 1 week (common shelf life)
- Allow selection up to 1 year future

## Empty Validation State
If user taps Save with empty fields:
```
Item Name → Red border, error text "Required"
Category → Red border, error text "Required"
Expiry Date → Red border, error text "Required"
```

## Telemetry Events
- `add_item_modal_opened` - {from_screen: "inventory_list" | "shopping_list"}
- `category_selected` - {category: str}
- `date_picker_opened` - {}
- `add_item_saved` - {category: str, days_to_expiry: int, has_notes: bool}
- `add_item_cancelled` - {}

## Notes
- Modal dimmed background prevents interaction with home screen
- Form saves are async; show loading state if >500ms delay
- Success: close modal, show toast "Item added", refresh inventory list
- Failure: keep modal open, show error toast with retry option
