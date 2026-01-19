# Navigation Flow Diagram

**Comprehensive navigation architecture for all 8 ZeroSpoils screens,** including tab navigation, modal flows, back button behavior, and onboarding.

## Wireframe Reference
1. [05 - Onboarding Flow](./wireframes/05-onboarding-flow.md) – Welcome, permissions, tutorial (3 screens, first-time only)
2. [01 - Inventory List](./wireframes/01-inventory-list.md) – Home tab, category grouping, search, FAB
3. [02 - Add Item Modal](./wireframes/02-add-item-modal.md) – Form overlay for new items
4. [03 - Item Detail](./wireframes/03-item-detail.md) – View/edit/delete item
5. [04 - Expiring Soon Tab](./wireframes/04-expiring-soon-tab.md) – Quick view of urgent items
6. [06 - Shopping List Tab](./wireframes/06-shopping-list-tab.md) – List management, suggestions
7. [07 - Settings Screen](./wireframes/07-settings-screen.md) – Preferences, account, help
8. [08 - Empty States Guide](./wireframes/08-empty-states-guide.md) – Cross-screen empty state patterns

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

The app uses a bottom tab bar with 4 primary screens. Each tab maintains its own navigation stack (state preserved when switching tabs).

```
┌──────────────────────────────────────────────────────┐
│                                                       │
│              [Current Screen Content]                │
│                                                       │
│                                          ⊕ (FAB)     │  ← FAB on Inventory & Expiring
│                                                       │
├──────────────────────────────────────────────────────┤
│  🏠          ⏰          🛒           ⚙️              │
│ Inventory  Expiring   Shopping    Settings           │
│  (Tab 1)    Soon       List        (Tab 4)           │
│            (Tab 2)    (Tab 3)                        │
└──────────────────────────────────────────────────────┘
```

### Tab Behavior
- **Tapping a tab:** Switch to that tab's root screen
- **Each tab has its own stack:** State preserved when switching tabs (IndexedStack keeps screens in memory)
- **Tapping active tab:** Scroll to top (if screen is scrollable, like list)
- **FAB:** Visible on Tab 1 (Inventory) and Tab 2 (Expiring Soon) for adding items
- **Back button on root tab:** Exit app (entire tab stack pops)
- **Tab switching preserves scroll position:** Users can pause work and return to same position

## Onboarding Flow (First-Time Users Only)

Onboarding screens appear once on app launch, then never again:

```
App Start
   │
   ├─ Check SharedPreferences.hasSeenOnboarding()
   │
   ├─ If FALSE: Show Onboarding
   │   ├─ Screen 1: Welcome (App benefits, tagline)
   │   ├─ Screen 2: Permissions (Notification request)
   │   ├─ Screen 3: Tutorial (3-step feature overview)
   │   └─ [Start Using App] → Mark hasSeenOnboarding = TRUE, show home
   │
   └─ If TRUE: Skip to Home (Inventory tab)
```

See [Wireframe 05: Onboarding Flow](./wireframes/05-onboarding-flow.md) for detailed screens.

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

### Tab 3: Shopping List

**Question: How do users navigate FROM Inventory TO Shopping List?**

Answer: Via **Add to Shopping List** button on item cards (long-press menu or context menu).

**M1 Flow (Implemented):**
```
Inventory List (Tab 1)
   │
   │ Long-press or tap menu on item
   ▼
┌──────────────────────────────────────────┐
│ Context Menu                             │
│ • View Details → Item Detail            │
│ • Add to Shopping List ← NEW            │
│ • Delete                                 │
└──────────────────────────────────────────┘
   │
   │ Tap "Add to Shopping List"
   ▼
┌──────────────────────────────────────────┐
│ Select List Dropdown                     │
│ ┌──────────────────────────────────────┐ │
│ │ Select list to add "Milk" to:       │ │
│ │                                      │ │
│ │ ○ Weekly Groceries (active)         │ │
│ │ ○ Trader Joe's                      │ │
│ │ ○ Whole Foods                       │ │
│ │ + Create New List                   │ │
│ └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
   │
   │ Select list
   ▼
┌──────────────────────────────────────────┐
│ ✓ Added to Weekly Groceries              │  ← Toast (2-3 sec)
│                                          │
│ (Tap to go to Shopping List)            │
└──────────────────────────────────────────┘
   │                              │
   │ (auto-dismiss)              │ (tap toast)
   │                              ▼
   └──────────────────────► Switch to Tab 3
                           (Shopping List)
```

**User's Choice:**
1. Continue shopping in Inventory (toast dismisses automatically)
2. Tap toast to jump to Shopping List and see the item

**M1 Implementation Details:**
- Toast auto-dismisses after 2-3 seconds
- Toast message: "✓ Added to [List Name]"
- Dismissing toast does NOT navigate away
- Tapping toast switches to Shopping List tab
- Item added to selected list immediately (no confirmation needed)
- Multiple items can be added to same list without re-selecting

**Future Enhancement (v2):**
```
Shopping List Item Display:
┌──────────────────────────────────────────┐
│ ☐ 🥛 Milk (2 in inventory)    qty: 1    │ ← Show inventory count
│ ☐ 🥕 Carrots (none left)       qty: 2    │   to reduce overbuying
│ ☐ 🥬 Spinach (1 wilting)        qty: 1    │
└──────────────────────────────────────────┘

This helps users:
- See what they already have at home
- Avoid buying duplicates
- Reduce food waste
```

See [Wireframe 01: Inventory List](./wireframes/01-inventory-list.md) and [Wireframe 06: Shopping List Tab](./wireframes/06-shopping-list-tab.md) for detailed interactions.

### Tab 4: Settings

```
┌──────────────────────────────────────────────────────────────┐
│   07. Settings Screen (Root)                                 │
│  • Account & Data                                            │
│  • Notifications & Alerts                                    │
│  • Preferences                                               │
│  • Support & Feedback                                        │
│  • Legal (Privacy, Terms)                                    │
└──────────────────────────────────────────────────────────────┘
      │
      │ Tap menu item → Navigate to sub-screen (future)
      │ For MVP: All options in collapsed/toggle form
      ▼
(No sub-screens in M1; Settings is single root screen)
```

See [Wireframe 07: Settings Screen](./wireframes/07-settings-screen.md) for details.

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

> **Note:** Deep linking will use universal links (iOS) and app links (Android) with HTTPS URLs instead of custom URL schemes to avoid conflicts and improve security.
> 
> **Configuration Requirements:**
> - iOS: Add `Associated Domains` entitlement and `.well-known/apple-app-site-association` file on web server
> - Android: Add `intent-filter` with `autoVerify="true"` and `.well-known/assetlinks.json` on web server
> - See [Flutter deep linking documentation](https://docs.flutter.dev/ui/navigation/deep-linking) for setup details

```
Deep Link URL: https://your-domain.com/item/123
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
- Tab bar uses `IndexedStack` to preserve state across tab switches
- Modals use `showDialog()` or `showModalBottomSheet()`
- Back button uses `Navigator.pop()` or `GoRouter.pop()`

### Navigation Implementation Examples

```dart
// Tab navigation with IndexedStack (preserves state)
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lazy initialization - screens created once and preserved
  late final List<Widget> _screens = [
    InventoryListScreen(),
    ExpiringSoonScreen(),
    ShoppingListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // Screens kept in memory, state preserved
      ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Expiring'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

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

- [UX Index](./ux.md) - Overview of all 8 screens and design system
- [Design Tokens](./design-tokens.md) - Color, typography, spacing, animations
- [UX Patterns](./ux-patterns.md) - Component interaction patterns
- **Wireframes:**
  - [05 - Onboarding Flow](./wireframes/05-onboarding-flow.md)
  - [01 - Inventory List](./wireframes/01-inventory-list.md)
  - [02 - Add Item Modal](./wireframes/02-add-item-modal.md)
  - [03 - Item Detail](./wireframes/03-item-detail.md)
  - [04 - Expiring Soon](./wireframes/04-expiring-soon-tab.md)
  - [06 - Shopping List Tab](./wireframes/06-shopping-list-tab.md)
  - [07 - Settings Screen](./wireframes/07-settings-screen.md)
  - [08 - Empty States Guide](./wireframes/08-empty-states-guide.md)
