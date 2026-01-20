# Interactive Tutorial Implementation Guide

**Status**: Planning  
**Target Milestone**: M1 (Foundations)  
**Library**: `tutorial_coach_mark: ^1.2.11`  
**Purpose**: Hands-on guided walkthrough with demo data after onboarding screens

## Overview

After users complete the 8-screen onboarding flow, launch an interactive tutorial that:
- Loads demo data into the app (3-4 inventory items, 2 shopping list items)
- Guides users through 6-8 core actions using tooltips/spotlights
- Validates each action before advancing to next step
- Teaches by doing (users tap real UI elements)
- Can be skipped or exited anytime

## Tutorial Flow (6 Steps)

### Step 1: View Inventory
**Target**: Inventory tab (bottom nav)  
**Tooltip**: "Welcome! Here are some demo items in your inventory. Let's explore how the app works."  
**Action**: User acknowledges (tap "Next" or anywhere on overlay)  
**Demo Data Loaded**:
- 🥛 Milk (Fridge, expires Jan 22, 2026 — 3 days)
- 🥕 Carrots (Fridge, expires Jan 25, 2026 — 6 days)
- 🍚 Cooked Rice (Freezer, prepared Jan 10, expires Feb 10)
- 🧀 Cheese (Fridge, expires Jan 28, 2026 — 9 days)

---

### Step 2: Open Item Detail
**Target**: First inventory item card (Milk)  
**Tooltip**: "Tap this item to see details and available actions."  
**Action**: User taps milk card → navigates to item-detail screen  
**Validation**: Wait for navigation to item-detail screen before advancing

---

### Step 3: Mark as Consumed
**Target**: "Consumed" button on item-detail screen  
**Tooltip**: "When you use an item, mark it as consumed. This helps track your waste reduction!"  
**Action**: User taps "Consumed" button → confirmation toast → returns to inventory  
**Validation**: Item removed from demo inventory, toast shown  
**Result**: Milk removed from inventory list

---

### Step 4: Check Expiring Soon
**Target**: "Expiring Soon" tab (bottom nav)  
**Tooltip**: "This tab shows items about to expire so you can prioritize eating them first."  
**Action**: User taps "Expiring Soon" tab → sees carrots (3 days left)  
**Validation**: Navigation to expiring-soon screen

---

### Step 5: Add to Shopping List
**Target**: "Shopping" tab (bottom nav)  
**Tooltip**: "Let's add something you need to buy. Go to the Shopping List tab."  
**Action**: User taps Shopping tab  
**Demo Data Loaded**:
- ☑️ Bread (purchased, ready to convert)
- ⬜ Eggs (not purchased yet)

---

### Step 6: Convert Purchased Item
**Target**: "Convert Purchased" button on shopping-list screen  
**Tooltip**: "When you buy items on your list, mark them purchased and convert to inventory. Try it now!"  
**Action**: User taps "Convert Purchased" → modal opens asking for expiry → user enters date → item moves to inventory  
**Validation**: Bread moves to inventory tab  
**Result**: Shows connection between shopping list and inventory

---

### Step 7: Completion
**Tooltip**: "🎉 Great job! You've learned the basics. Now clear this demo data and add your real items."  
**Action**: "Clear Demo Data" button + "Start Fresh" button  
**Result**: Demo data wiped, user at empty inventory with FAB to add first real item

---

## Flutter Implementation

### 1. Add Dependencies

**`pubspec.yaml`**:
```yaml
dependencies:
  tutorial_coach_mark: ^1.2.11
  shared_preferences: ^2.2.2  # To track if tutorial completed
```

### 2. Demo Data Service

**`lib/data/services/demo_data_service.dart`**:
```dart
import 'package:zerospoils/domain/models/item.dart';

class DemoDataService {
  static List<Item> getDemoInventory() {
    return [
      Item(
        id: 'demo-1',
        name: 'Milk',
        category: 'Dairy',
        location: 'Fridge',
        expiryDate: DateTime.now().add(Duration(days: 3)),
        emoji: '🥛',
        isDemo: true,
      ),
      Item(
        id: 'demo-2',
        name: 'Carrots',
        category: 'Produce',
        location: 'Fridge',
        expiryDate: DateTime.now().add(Duration(days: 6)),
        emoji: '🥕',
        isDemo: true,
      ),
      Item(
        id: 'demo-3',
        name: 'Cooked Rice',
        category: 'Prepared',
        location: 'Freezer',
        preparedDate: DateTime.now().subtract(Duration(days: 9)),
        expiryDate: DateTime.now().add(Duration(days: 22)),
        emoji: '🍚',
        isDemo: true,
        isPrepared: true,
      ),
      Item(
        id: 'demo-4',
        name: 'Cheese',
        category: 'Dairy',
        location: 'Fridge',
        expiryDate: DateTime.now().add(Duration(days: 9)),
        emoji: '🧀',
        isDemo: true,
      ),
    ];
  }

  static List<ShoppingItem> getDemoShoppingList() {
    return [
      ShoppingItem(
        id: 'demo-shop-1',
        name: 'Bread',
        isPurchased: true,
        emoji: '🍞',
        isDemo: true,
      ),
      ShoppingItem(
        id: 'demo-shop-2',
        name: 'Eggs',
        isPurchased: false,
        emoji: '🥚',
        isDemo: true,
      ),
    ];
  }

  static Future<void> clearDemoData(Repository repo) async {
    await repo.removeWhere((item) => item.isDemo == true);
  }
}
```

### 3. Tutorial Service

**`lib/presentation/tutorials/interactive_tutorial.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class InteractiveTutorial {
  final BuildContext context;
  final GlobalKey inventoryTabKey;
  final GlobalKey firstItemKey;
  final GlobalKey consumedButtonKey;
  final GlobalKey expiringTabKey;
  final GlobalKey shoppingTabKey;
  final GlobalKey convertButtonKey;
  final VoidCallback onComplete;

  late TutorialCoachMark tutorialCoachMark;

  InteractiveTutorial({
    required this.context,
    required this.inventoryTabKey,
    required this.firstItemKey,
    required this.consumedButtonKey,
    required this.expiringTabKey,
    required this.shoppingTabKey,
    required this.convertButtonKey,
    required this.onComplete,
  }) {
    _initTargets();
  }

  void _initTargets() {
    final targets = [
      // Step 1: View Inventory
      TargetFocus(
        identify: "inventory-view",
        keyTarget: inventoryTabKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome! 👋",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Here are some demo items in your inventory. Let's explore how the app works.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Step 1 of 6",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Step 2: Open Item Detail
      TargetFocus(
        identify: "tap-item",
        keyTarget: firstItemKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTooltip(
                title: "Tap to View Details",
                description: "Tap this item to see details and available actions.",
                step: "Step 2 of 6",
              );
            },
          ),
        ],
      ),

      // Step 3: Mark as Consumed
      TargetFocus(
        identify: "mark-consumed",
        keyTarget: consumedButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTooltip(
                title: "Mark as Consumed ✓",
                description: "When you use an item, mark it as consumed. This helps track your waste reduction!",
                step: "Step 3 of 6",
              );
            },
          ),
        ],
      ),

      // Step 4: Check Expiring Soon
      TargetFocus(
        identify: "expiring-tab",
        keyTarget: expiringTabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTooltip(
                title: "Check What's Expiring ⏰",
                description: "This tab shows items about to expire so you can prioritize eating them first.",
                step: "Step 4 of 6",
              );
            },
          ),
        ],
      ),

      // Step 5: Go to Shopping List
      TargetFocus(
        identify: "shopping-tab",
        keyTarget: shoppingTabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTooltip(
                title: "Shopping List 🛒",
                description: "Let's add something you need to buy. Go to the Shopping List tab.",
                step: "Step 5 of 6",
              );
            },
          ),
        ],
      ),

      // Step 6: Convert Purchased Items
      TargetFocus(
        identify: "convert-purchased",
        keyTarget: convertButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTooltip(
                title: "Convert to Inventory 📦",
                description: "When you buy items on your list, mark them purchased and convert to inventory. Try it now!",
                step: "Step 6 of 6",
              );
            },
          ),
        ],
      ),
    ];

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      onFinish: () {
        _showCompletionDialog();
      },
      onClickTarget: (target) {
        // Log analytics event
        print('Tutorial step clicked: ${target.identify}');
      },
      onSkip: () {
        _showSkipConfirmation();
        return true;
      },
    );
  }

  Widget _buildTooltip({
    required String title,
    required String description,
    required String step,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            step,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 Tutorial Complete!'),
        content: Text(
          "Great job! You've learned the basics. Now clear this demo data and add your real items.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onComplete();
            },
            child: Text('Clear Demo Data & Start Fresh'),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Tutorial?'),
        content: Text('You can always restart the tutorial from Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onComplete();
            },
            child: Text('Skip'),
          ),
        ],
      ),
    );
  }

  void show() {
    tutorialCoachMark.show(context: context);
  }
}
```

### 4. Integration in Main Screen

**`lib/presentation/screens/home_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/data/services/demo_data_service.dart';
import 'package:zerospoils/presentation/tutorials/interactive_tutorial.dart';

class HomeScreen extends StatefulWidget {
  final bool shouldShowTutorial;

  const HomeScreen({Key? key, this.shouldShowTutorial = false}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKeys for tutorial targets
  final GlobalKey _inventoryTabKey = GlobalKey();
  final GlobalKey _firstItemKey = GlobalKey();
  final GlobalKey _consumedButtonKey = GlobalKey();
  final GlobalKey _expiringTabKey = GlobalKey();
  final GlobalKey _shoppingTabKey = GlobalKey();
  final GlobalKey _convertButtonKey = GlobalKey();

  int _currentTab = 0;
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldShowTutorial) {
      _loadDemoDataAndStartTutorial();
    }
  }

  Future<void> _loadDemoDataAndStartTutorial() async {
    // Load demo data
    final demoInventory = DemoDataService.getDemoInventory();
    final demoShopping = DemoDataService.getDemoShoppingList();
    
    // Add to repository (assumes you have a repository/state management solution)
    await context.read<InventoryRepository>().addAll(demoInventory);
    await context.read<ShoppingRepository>().addAll(demoShopping);

    // Show tutorial after frame renders (so GlobalKeys are available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tutorialShown) {
        _showTutorial();
        setState(() => _tutorialShown = true);
      }
    });
  }

  void _showTutorial() {
    final tutorial = InteractiveTutorial(
      context: context,
      inventoryTabKey: _inventoryTabKey,
      firstItemKey: _firstItemKey,
      consumedButtonKey: _consumedButtonKey,
      expiringTabKey: _expiringTabKey,
      shoppingTabKey: _shoppingTabKey,
      convertButtonKey: _convertButtonKey,
      onComplete: _onTutorialComplete,
    );
    tutorial.show();
  }

  Future<void> _onTutorialComplete() async {
    // Clear demo data
    await DemoDataService.clearDemoData(context.read<InventoryRepository>());
    await DemoDataService.clearDemoData(context.read<ShoppingRepository>());

    // Mark tutorial as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ Demo data cleared. Add your first item!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          InventoryListScreen(firstItemKey: _firstItemKey),
          ExpiringScreen(key: _expiringTabKey),
          ShoppingListScreen(convertButtonKey: _convertButtonKey),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory, key: _inventoryTabKey),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time, key: _expiringTabKey),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, key: _shoppingTabKey),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

### 5. Trigger Tutorial After Onboarding

**`lib/presentation/screens/onboarding/get_started_screen.dart`**:
```dart
// In the "Get Started" button callback:
ElevatedButton(
  onPressed: () async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to home with tutorial flag
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(shouldShowTutorial: true),
      ),
    );
  },
  child: Text('Add First Item'),
);
```

---

## Edge Cases & Considerations

### 1. User Skips Tutorial
- Show confirmation dialog: "Skip tutorial? You can restart from Settings."
- Still clear demo data when they skip
- Add "Restart Tutorial" option in Settings → Help

### 2. User Exits App Mid-Tutorial
- Use `shared_preferences` to track tutorial state: `tutorial_in_progress: true`
- On app restart, check flag and prompt: "Resume tutorial?" or "Clear demo data?"
- After 24 hours, auto-clear demo data and mark tutorial abandoned

### 3. User Deletes Demo Items Manually
- Demo items have `isDemo: true` flag
- If user manually deletes demo item, detect via repository listener
- Adapt tutorial: skip step if target is missing, show alternate tooltip

### 4. Offline-First Behavior
- Demo data stored in local DB (Hive/sqflite) like real items
- Tutorial works 100% offline
- No network calls required

### 5. Accessibility
- Ensure tooltips have sufficient contrast (white text on dark overlay)
- Support TalkBack/VoiceOver: add semantic labels to tutorial content
- Allow dismissing with Escape key (desktop/web)
- Touch targets ≥44pt for all tutorial buttons

---

## Analytics Events

Track tutorial effectiveness:

```dart
// Tutorial started
analytics.logEvent(name: 'tutorial_started', parameters: {
  'source': 'onboarding_completion',
  'timestamp': DateTime.now().toIso8601String(),
});

// Step completed
analytics.logEvent(name: 'tutorial_step_completed', parameters: {
  'step_id': 'tap-item',
  'step_number': 2,
  'duration_seconds': 5,
});

// Tutorial completed
analytics.logEvent(name: 'tutorial_completed', parameters: {
  'total_duration_seconds': 120,
  'steps_completed': 6,
  'demo_data_cleared': true,
});

// Tutorial skipped
analytics.logEvent(name: 'tutorial_skipped', parameters: {
  'step_id': 'mark-consumed',
  'step_number': 3,
  'reason': 'user_initiated',
});
```

---

## Testing Plan

### Automated Tests
1. **Unit Test**: Demo data service generates correct items
2. **Widget Test**: Tutorial tooltips render with correct text
3. **Integration Test**: Tutorial completes successfully and clears demo data

### Manual Testing
1. Complete onboarding → verify tutorial launches automatically
2. Skip tutorial at step 3 → verify demo data clears and user at empty inventory
3. Complete all 6 steps → verify demo data cleared, success message shown
4. Exit app at step 4, relaunch → verify prompt to resume or skip tutorial
5. Tap targets with large fingers → verify all touch targets ≥44pt
6. Test with TalkBack enabled → verify screen reader announces steps

---

## Out of Scope (Future Enhancements)

- Multi-language tutorial content (M4: Localization)
- Adaptive tutorial (skips steps user already completed)
- Tutorial replay from Settings → Help (M3)
- Advanced tutorial for Pro features (M5)

---

## Dependencies

- `tutorial_coach_mark: ^1.2.11` — Core tutorial library
- `shared_preferences: ^2.2.2` — Persist tutorial completion state
- State management solution (Provider/Riverpod/Bloc) — Access repository for demo data
- Local database (Hive/sqflite) — Store demo items

---

## Related Issues/Docs

- **Onboarding Flow**: `planning/milestones/M1/060-clickable-prototype-walkthrough-capture-feedback-5-users.md`
- **Onboarding Wireframes**: `planning/docs/wireframes/onboarding-flow.md`
- **Data Model**: `planning/milestones/M1/080-define-v1-data-model-item-category-location-events.md`
- **Telemetry**: `planning/milestones/M1/040-define-telemetry-taxonomy-baseline-events.md`

---

## Success Criteria

✅ Tutorial launches automatically after onboarding completion  
✅ All 6 steps highlight correct UI elements with tooltips  
✅ User can skip tutorial at any point  
✅ Demo data loads correctly (4 inventory items, 2 shopping items)  
✅ Demo data clears after completion/skip  
✅ Tutorial completion tracked in analytics  
✅ Accessibility: TalkBack/VoiceOver compatible, 44pt touch targets  
✅ Tutorial can be restarted from Settings (future enhancement)

---

**Questions?** See `tutorial_coach_mark` docs: https://pub.dev/packages/tutorial_coach_mark
