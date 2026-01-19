# UX Patterns & Component Library

This document defines the reusable UI components and interaction patterns used across ZeroSpoils screens. All implementations should follow these patterns for consistency.

## Core Components

### 1. AppBar (56pt height)
**Purpose:** Screen header with title, back button, and action buttons.

**Structure:**
```
[←] Title                          [⚙️] [⋮]
```

**States:**
- Standard (title centered)
- With back button (left-aligned)
- With menu button (right-aligned)

**Implementation Notes:**
- Back button always on left when present
- Title left-aligned after back button
- Action buttons (settings, menu) on right
- Tap targets ≥44pt
- Material 3 elevation: 0dip on light theme

**Accessibility:**
- Back button labeled "Back" or page-specific "Back to Inventory"
- Menu button labeled "More options" or similar
- AppBar title announced by screen reader

---

### 2. SearchBar (48pt height)
**Purpose:** Filter items by text search across name, category, or notes.

**Structure:**
```
🔍 [Search items...        ]  ✕
```

**States:**
- Unfocused (gray background, placeholder text)
- Focused (blue border, keyboard visible)
- With results (show matching count)
- Empty (no matches found)

**Behavior:**
- Type to filter in real-time
- X button clears search when text present
- Debounce search queries (300ms)
- Case-insensitive matching
- Match against: item name, category, notes

**Telemetry:**
- `search_initiated` - {query: str}
- `search_cleared` - {}
- `search_results_count` - {count: int}

**Accessibility:**
- Label: "Search items"
- Screen reader announces result count changes
- Keyboard: Enter submits, Escape clears

---

### 3. ItemCard (64pt height)
**Purpose:** Display single item with category, name, expiry status.

**Structure:**
```
🥛 Milk                    3d
📅 Expires Thu 14 Mar     →
```

**Components:**
- Category emoji (24pt)
- Item name (16pt, semi-bold)
- Days left (12pt, right-aligned, color-coded)
- Expiry label + date (12pt, gray)
- Tap target (full card, 64pt)

**Color Coding:**
- White background: >3 days
- Light yellow (#FFF9E6): 1-3 days
- Light orange (#FFE6CC): <1 day
- Light red (#FFE6E6): Expired

**States:**
- Normal (white bg)
- Hovered (slight elevation)
- Swiped (delete button revealed on left)
- Urgent (yellow/orange/red bg)

**Interactions:**
- Tap: Navigate to detail
- Swipe left: Reveal delete button
- Long-press: Context menu (optional v2)

**Telemetry:**
- `item_tapped` - {item_id: str, category: str, days_left: int}
- `item_swiped_delete` - {item_id: str}

**Accessibility:**
- Role: "button"
- Label: "{Category} {Item name}, expires {date}, {days} days left"
- Tap target ≥44pt
- Emoji alt text (e.g., "milk emoji")

---

### 4. FAB - Floating Action Button (56pt diameter)
**Purpose:** Primary action—add new item.

**Visual:**
```
    ⊕
  (Blue circle, white plus icon)
```

**Placement:**
- Bottom-right corner
- 16pt margin from edges
- Floats above content (elevation: 6dip)

**States:**
- Normal (blue, white icon)
- Hovered (darker blue, slight lift)
- Pressed (animation feedback)

**Behavior:**
- Tap opens "Add Item" modal
- Always visible, even when scrolling
- Disabled if: add form already open

**Telemetry:**
- `fab_tapped` - {from_screen: str}

**Accessibility:**
- Label: "Add item"
- Tap target: 56pt (meets 44pt minimum)
- Screen reader: "Button, add item, double-tap to activate"

---

### 5. Modal Overlay
**Purpose:** Display forms (Add Item, Delete Confirmation) on top of content.

**Structure:**
```
┌─────────────────────┐
│ Title            ✕  │  ← Header (close button)
├─────────────────────┤
│ Content (form)      │  ← Scrollable if needed
│                     │
│ [Cancel] [Save]     │  ← Action buttons
└─────────────────────┘
(Dimmed background)
```

**Behavior:**
- Dims background (80% opacity)
- Prevents interaction with content below
- Tap outside modal: Close (with confirmation if form has changes)
- Esc key: Close
- X button: Close (with confirmation if form has changes)

**States:**
- Default (content visible)
- Loading (save in progress, disable buttons, show spinner)
- Error (show error toast + stay open)

**Accessibility:**
- Modal has role="dialog"
- Focus trapped within modal (tab cycles through buttons)
- Screen reader announces modal title on open
- Close button labeled "Close" or "Cancel"

---

### 6. Button Variants

#### Primary Button (Save, Add)
```
    [  Save  ]  (Blue, white text)
```
- Background: Material Blue (primary color from design tokens)
- Text: White, semi-bold
- Size: 48pt height min
- Tap target: ≥44pt

#### Secondary Button (Cancel, Delete)
```
    [  Cancel  ]  (White, gray text, gray border)
```
- Background: White
- Border: 1pt gray
- Text: Gray, semi-bold
- Size: 48pt height min

#### Danger Button (Delete confirmation)
```
    [  Delete  ]  (Red, white text)
```
- Background: Error red
- Text: White, semi-bold
- Size: 48pt height min
- Warning: Shown only in confirmation dialog

#### Tertiary Button (Mark as Used)
```
    [  Mark as Used  ]  (Transparent, gray text)
```
- Background: Transparent
- Text: Gray, semi-bold
- Size: 48pt height min

---

### 7. Category Dropdown
**Purpose:** Select item category from predefined list.

**Structure:**
```
Category *
┌────────────────────┐
│ Dairy           ▼  │  ← Selected value + toggle
└────────────────────┘
```

**Expanded:**
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

**Behavior:**
- Tap to expand list
- Tap item to select
- Auto-close on selection
- Keyboard: Arrow keys to navigate, Enter to select, Esc to close

**Telemetry:**
- `dropdown_opened` - {field: "category"}
- `category_selected` - {category: str}

**Accessibility:**
- Label: "Category" (or field name)
- Role: "combobox"
- ARIA: expanded state, selected value announced

---

### 8. DatePicker
**Purpose:** Select expiry date.

**Structure:**
```
Expiry Date *
[📅 Mar 14, 2025]  ▼
```

**Behavior:**
- Tap field to open native date picker
- iOS: CupertinoDatePicker (wheel)
- Android: Material DatePicker
- Default: Today + 7 days
- Range: Today to +365 days
- Disable past dates

**Validation:**
- Required field
- Must be future date or today
- Show error: "Expiry date must be today or later"

**Telemetry:**
- `date_picker_opened` - {}
- `date_selected` - {date: ISO8601, days_from_today: int}

**Accessibility:**
- Label: "Expiry date"
- Format: "Mar 14, 2025" (readable, not ISO)
- Keyboard accessible: Tab to field, Space to open picker

---

### 9. TextInput / TextField
**Purpose:** Enter item name, notes, or search query.

**Structure:**
```
Label *
[________________]  (input field)
```

**States:**
- Empty (gray placeholder)
- Focused (blue border, cursor)
- With error (red border, error text below)
- Disabled (gray bg, no interaction)

**Validation:**
- Required: Show "*" after label
- Max length: Display counter (e.g., "10/50 chars")
- Error on blur or save attempt
- Error message: Red text, ≥4.5:1 contrast

**Behavior:**
- Single-line: No wrapping
- Multi-line (Notes): Auto-expand up to 5 lines
- Clear button (X): Shows when field has text
- Undo/redo: Standard keyboard support

**Telemetry:**
- `input_focused` - {field: str}
- `input_cleared` - {field: str}

**Accessibility:**
- Label associated with input (via htmlFor or semantic label)
- Placeholder not a substitute for label
- Error message linked to input (via aria-describedby)
- Font: min 16pt to avoid zoom on iOS focus

---

### 10. EmptyState
**Purpose:** User-friendly message when no items exist.

**Structure:**
```
┌─────────────────────┐
│                     │
│    📭 No items      │  ← Icon (48pt)
│                     │
│  "Add your first    │  ← Message text
│   item to get       │
│   started"          │
│                     │
│   [Add Item]        │  ← CTA button
│                     │
└─────────────────────┘
```

**Variations:**
- **No items:** Icon = 📭, CTA = "Add Item" → FAB
- **No search results:** Icon = 🔍, Message = "No matches found", CTA = "Clear search"
- **No expiring items:** Icon = ✅, Message = "Nothing expiring soon"
- **Error state:** Icon = ⚠️, Message = "Couldn't load items. Try again."

**Behavior:**
- Centered on screen
- Tap CTA button → Execute action
- Icon is decorative (not interactive)

**Accessibility:**
- Heading: "No items"
- Message text descriptive, not icon-only
- CTA button follows button a11y rules

---

## Interaction Patterns

### Navigation
1. **Back Navigation:**
   - Tap back button → Pop screen
   - Swipe from left edge (iOS) → Pop screen
   - Android back gesture → Pop screen

2. **Tab Navigation:**
   - Tap tab → Switch to tab screen
   - Show 4 tabs max (Home, Shopping, Expiring, Settings)
   - Active tab highlighted (color + underline)

3. **Deep Links (v2+):**
   - `/item/:id` → Item detail
   - `/settings` → Settings
   - Handled by GoRouter

### Form Submission
1. User fills form (name, category, date, notes)
2. User taps Save button
3. Validate inputs (required fields, date format, etc.)
4. Show loading state (button disabled, spinner)
5. Send to backend
6. On success: Close modal, show toast "Item added", refresh list
7. On error: Show error toast, keep modal open, allow retry

### Deletion
1. User taps Delete button
2. Show confirmation dialog: "Delete {item}? Cannot be undone."
3. If Cancel → Close dialog, return to detail
4. If Delete → Remove from backend, close modal, return to list with toast

### Search
1. User taps SearchBar or starts typing
2. Real-time filter as user types
3. Show filtered results instantly
4. Show result count: "3 items found"
5. User taps item → Navigate to detail
6. User taps X → Clear search, show all items again

---

## Color Palette & Contrast

**Primary Colors:**
- Blue (primary action): #2196F3
- Green (success, good status): #4CAF50
- Yellow (warning, 1-3 days): #FFC107
- Orange (urgent, <1 day): #FF9800
- Red (critical, expired or error): #F44336
- Gray (neutral, labels): #666666

**Background & Text:**
- White background: #FFFFFF
- Dark text: #212121 (≥7:1 contrast)
- Light gray bg: #F5F5F5
- Borders: #E0E0E0

**Validation:**
- All text ≥16pt for accessibility
- Color not sole indicator (use icons + text)
- Required fields: Asterisk (*) + text
- Error text: Red (#F44336) with icon (⚠️)

---

## Animation Guidelines

- **Transitions:** 200-300ms easing (smooth curve)
- **Modals:** Fade in (200ms), scale up (slightly)
- **Button press:** Color feedback + ripple (100ms)
- **List scroll:** Smooth, not janky
- **Tab switch:** Fade or slide (consistent)
- **No: Flash animations, parallax, bouncy easing** (too distracting)

---

## Responsive Design

**Breakpoints:**
- Mobile: 320px - 428px (primary target)
- Tablet: 768px+ (v2+, optional)

**Layout Rules:**
- Full-width content (no fixed widths >320px)
- Padding: 16pt on sides (8pt on compact layouts)
- Buttons: Full width on mobile
- AppBar: Fixed, sticky at top
- FAB: Fixed in corner

**Typography Scaling:**
- Base font: 14pt
- Headings: 24pt (large), 18pt (medium)
- Scale up to 2x without breaking layout
- No inline code or monospace (accessible to all)

---

## Testing Checklist for Components

- [ ] Renders correctly on light/dark theme
- [ ] All tap targets ≥44pt
- [ ] Labels visible, not placeholder-only
- [ ] Contrast ≥4.5:1 for text
- [ ] Scales to 2x font size without overflow
- [ ] Screen reader announces purpose & state
- [ ] Keyboard navigation works (Tab, Enter, Esc)
- [ ] Focus visible (outline or highlight)
- [ ] No color-only indicators (emoji, text, or icon required)
- [ ] Telemetry events fire on interaction
- [ ] Error states clear and recoverable

---

## Related Documentation
- [Navigation Flow Diagram](./navigation-flow.md) - Complete navigation architecture
- [Wireframe 01: Inventory List](./wireframes/01-inventory-list.md)
- [Wireframe 02: Add Item Modal](./wireframes/02-add-item-modal.md)
- [Wireframe 03: Item Detail](./wireframes/03-item-detail.md)
- [Wireframe 04: Expiring Soon](./wireframes/04-expiring-soon-tab.md)
