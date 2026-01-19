# Navigation Flow Diagram

This document provides a visual representation of the navigation structure for ZeroSpoils MVP, including tab navigation, modal flows, and back button behavior.

## High-Level Navigation Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ZeroSpoils App                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Bottom Tab Navigation                     │
│   ┌──────────┬──────────┬──────────┬──────────┐            │
│   │ Inventory│ Expiring │ Shopping │ Settings │            │
│   │   (Home) │   Soon   │   List   │          │            │
│   └────┬─────┴─────┬────┴─────┬────┴─────┬────┘            │
└────────┼───────────┼──────────┼──────────┼─────────────────┘
         │           │          │          │
         ▼           ▼          ▼          ▼
    [Screen 1]  [Screen 2] [Screen 3] [Screen 4]
```

## Tab Structure (Bottom Navigation)

The app uses a bottom tab bar with 4 primary screens. Each tab maintains its own navigation stack.

```
┌──────────────────────────────────────────────────────┐
│                                                       │
│              [Current Screen Content]                │
│                                                       │
│                                                       │
│                                          ⊕ (FAB)     │
├───────────────────────────────────────────────────────┤
│  🏠          ⏰          🛒           ⚙️              │
│ Inventory  Expiring   Shopping    Settings           │
│  (Active)    Soon       List                         │
└──────────────────────────────────────────────────────┘
```

**Tab Behavior:**
- Tapping a tab switches to that tab's root screen
- Each tab has its own navigation stack
- Tapping an active tab scrolls to top (if scrollable)
- FAB (Floating Action Button) is visible on Inventory and Expiring Soon tabs

## Complete Navigation Flow

### Tab 1: Inventory (Home)

```
┌─────────────────────────────────────┐
│     01. Inventory List (Root)       │
│  • Search bar                       │
│  • Item cards (list)                │
│  • FAB (add item)                   │
└─────┬──────────────┬────────────────┘
      │              │
      │              │ Tap FAB
      │              ▼
      │         ┌─────────────────────┐
      │         │ 02. Add Item Modal  │◄──── Modal overlay
      │         │  • Name field       │      (not in nav stack)
      │         │  • Category dropdown│
      │         │  • Expiry date      │
      │         │  • Notes field      │
      │         │  • [Cancel] [Save]  │
      │         └─────────────────────┘
      │              │
      │              │ Save → Close modal, refresh list
      │              │ Cancel → Close modal
      │              │ Tap outside → Close (if no changes)
      │              │ X button → Close (confirm if changes)
      │
      │ Tap item card
      ▼
┌─────────────────────────────────────┐
│     03. Item Detail Screen          │
│  • Back button (←)                  │
│  • Item info (read-only)            │
│  • [Edit] button                    │
│  • [Mark as Used] button            │
│  • [Delete] button                  │
└─────┬──────────────┬────────────────┘
      │              │
      │              │ Tap Edit
      │              ▼
      │         ┌─────────────────────┐
      │         │ Edit Item Modal     │◄──── Modal overlay
      │         │  (Same as Add Item) │
      │         │  • Pre-filled fields│
      │         │  • [Cancel] [Save]  │
      │         └─────────────────────┘
      │              │
      │              │ Save → Close modal, update detail
      │              │ Cancel → Close modal
      │
      │ Tap Delete
      ▼
┌─────────────────────────────────────┐
│   Delete Confirmation Dialog        │◄──── Modal overlay
│  "Delete [Item]? Cannot be undone." │      (alert dialog)
│                                     │
│       [Cancel]    [Delete]          │
└─────────────────────────────────────┘
      │              │
      │              │ Delete → Close, pop to list
      └──────────────┘ Cancel → Close dialog
```

### Tab 2: Expiring Soon

```
┌─────────────────────────────────────┐
│   04. Expiring Soon Tab (Root)      │
│  • Today section (0 days)           │
│  • This week section (1-3 days)     │
│  • Next week section (4-7 days)     │
│  • FAB (add item)                   │
└─────┬──────────────┬────────────────┘
      │              │
      │              │ Tap FAB → Same as Inventory
      │              │
      │ Tap item card
      ▼
┌─────────────────────────────────────┐
│     03. Item Detail Screen          │◄──── Shared screen
│  (Same navigation as Inventory tab) │      (same component)
└─────────────────────────────────────┘
```

### Tab 3: Shopping List (Future)

```
┌─────────────────────────────────────┐
│   Shopping List Tab (Root)          │
│  • Suggested items                  │
│  • Add to list                      │
└─────────────────────────────────────┘
      │
      │ (MVP: Minimal, v2: Full feature)
      ▼
```

### Tab 4: Settings (Future)

```
┌─────────────────────────────────────┐
│   Settings Screen (Root)            │
│  • Notification preferences         │
│  • About app                        │
│  • Privacy settings                 │
└─────────────────────────────────────┘
```

## Back Button Behavior

### Platform-Specific Back Gestures

```
iOS:
┌──────────────────────────────────┐
│  ← Back                          │  ← Back button in AppBar
│                                  │
│  [Screen Content]                │
│                                  │
│◄────                             │  ← Swipe from left edge
└──────────────────────────────────┘

Android:
┌──────────────────────────────────┐
│  ← Back                          │  ← Back button in AppBar
│                                  │
│  [Screen Content]                │
│                                  │
└──────────────────────────────────┘
   ▲
   └─ System back gesture (swipe from left/right edge)
      OR hardware/software back button
```

### Back Navigation Rules

1. **From Detail Screen → List Screen:**
   - Back button/gesture: Pop to previous screen (Inventory List or Expiring Soon)
   - Navigation stack: `[Inventory] → [Detail]` becomes `[Inventory]`

2. **From Root Tab Screen:**
   - Back button/gesture: Exit app (if no other screens in stack)
   - Tab bar always visible

3. **From Modal:**
   - Back button in modal header: Close modal (no navigation pop)
   - System back gesture: Close modal (no navigation pop)
   - Tap outside modal (if no changes): Close modal
   - If form has changes: Show confirmation "Discard changes?"

4. **Modal Stack Behavior:**
   ```
   Navigation Stack:     [Inventory] → [Detail]
   Modal Overlay:        [Edit Modal] (not in nav stack)
   
   Close modal:          Navigation stack unchanged
   System back:          Close modal first, then pop navigation if pressed again
   ```

## Modal Flow Patterns

### Add/Edit Item Modal Flow

```
Any Screen with FAB or Edit button
         │
         │ User action (tap FAB/Edit)
         ▼
    ┌─────────────────────────────────┐
    │       Modal Overlay             │
    │  ┌───────────────────────────┐  │
    │  │  X  Add/Edit Item Modal   │  │
    │  ├───────────────────────────┤  │
    │  │  Name: [_____________]    │  │
    │  │  Category: [Dairy ▼]      │  │
    │  │  Expiry: [Mar 14, 2025 ▼] │  │
    │  │  Notes: [_____________]   │  │
    │  │                           │  │
    │  │  [Cancel]      [Save]     │  │
    │  └───────────────────────────┘  │
    │                                 │
    │  (Dimmed background - 80%)      │
    └─────────────────────────────────┘
         │           │           │
         │           │           │
         ▼           ▼           ▼
    Tap outside   Cancel      Save
    (if clean)    button      button
         │           │           │
         └───────────┴───────────┘
                     │
                     ▼
              Close modal
              Update underlying screen
              Show toast confirmation
```

### Delete Confirmation Flow

```
Item Detail Screen
         │
         │ Tap Delete button
         ▼
    ┌─────────────────────────────────┐
    │     Confirmation Dialog         │
    │  ┌───────────────────────────┐  │
    │  │  Delete [Item Name]?      │  │
    │  │                           │  │
    │  │  This action cannot be    │  │
    │  │  undone.                  │  │
    │  │                           │  │
    │  │  [Cancel]    [Delete]     │  │
    │  └───────────────────────────┘  │
    │                                 │
    │  (Dimmed background)            │
    └─────────────────────────────────┘
         │                    │
         │                    │
         ▼                    ▼
    Cancel button       Delete button
         │                    │
         │                    ▼
         │              Delete from DB
         │              Close dialog
         │              Pop to list
         │              Show toast "Item deleted"
         │
         ▼
    Close dialog
    Stay on detail screen
```

## Deep Link Navigation (v2)

```
Deep Link URL: zerospoils://item/123
         │
         ▼
┌─────────────────────────────────────┐
│   App Launch or Background Resume   │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Router (GoRouter)                 │
│   Parse URL path & parameters       │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Navigate to Item Detail           │
│   • Load item ID: 123               │
│   • Push screen on Inventory stack  │
│   • Show back button to Inventory   │
└─────────────────────────────────────┘
```

## Navigation State Management

### Tab State Persistence

Each tab maintains its own navigation stack:

```
Tab 1 (Inventory):    [Inventory List] → [Item Detail A]
Tab 2 (Expiring Soon): [Expiring Soon List] → [Item Detail B]
Tab 3 (Shopping):      [Shopping List]
Tab 4 (Settings):      [Settings]

User switches tabs:
- Current stack preserved
- Switching back restores previous position
- No data loss when switching tabs
```

### Modal Overlay State

Modals are rendered on top of the current screen, not in navigation stack:

```
Navigation Stack:     [Screen A] → [Screen B]
Presentation Layer:   [Modal C] (overlaid)

Closing modal:        Stack remains [Screen A] → [Screen B]
System back:          Close modal first, then pop [Screen B] on second press
```

## Edge Cases & Special Behaviors

### 1. Unsaved Changes in Modal

```
User fills form → Taps outside/back/cancel
         │
         ▼
Has changes? ────Yes───→ Show confirmation dialog
         │               "Discard changes?"
         No              [Stay] [Discard]
         │                    │         │
         ▼                    ▼         ▼
    Close modal          Close modal   Stay in modal
```

### 2. System Back Button (Android)

```
Screen Hierarchy:     [Tab Root] → [Detail] + [Modal Open]

First back press:     Close modal
Second back press:    Pop to [Tab Root]
Third back press:     Exit app
```

### 3. Tab Re-Selection

```
User on:              [Inventory] → [Detail A] → [Detail B]
User taps Inventory tab again:
         │
         ▼
Pop entire stack to root:   [Inventory]
Scroll to top (if scrollable)
```

## Implementation Notes

### Flutter Navigation 2.0 (GoRouter)

- Use declarative routing with `GoRouter`
- Tab bar uses `IndexedStack` to preserve state
- Modals use `showDialog()` or `showModalBottomSheet()`
- Back button uses `Navigator.pop()` or `GoRouter.pop()`

### Navigation Keys

```dart
// Tab navigation
bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  },
)

// Modal navigation (not in nav stack)
showDialog(
  context: context,
  builder: (context) => AddItemModal(),
);

// Screen navigation (in nav stack)
context.push('/item/$itemId');
```

## Testing Checklist

Navigation flows to test:

- [ ] Tab switching preserves state
- [ ] Back button pops to previous screen
- [ ] Back button on root tab exits app
- [ ] Modal close does not affect navigation stack
- [ ] System back button closes modal first, then pops screen
- [ ] Tab re-selection pops to root and scrolls to top
- [ ] Deep links navigate to correct screen
- [ ] Unsaved changes prompt confirmation before closing modal
- [ ] Delete confirmation prevents accidental deletion
- [ ] iOS swipe-from-edge gesture works
- [ ] Android system back gesture works

## Related Documentation

- [UX Patterns](./ux-patterns.md) - Component interaction patterns
- [Wireframe 01: Inventory List](./wireframes/01-inventory-list.md)
- [Wireframe 02: Add Item Modal](./wireframes/02-add-item-modal.md)
- [Wireframe 03: Item Detail](./wireframes/03-item-detail.md)
- [Wireframe 04: Expiring Soon](./wireframes/04-expiring-soon-tab.md)
