# ZeroSpoils Architecture Guide

> **Who is this for?** Developers new to Flutter who need to understand this codebase quickly.
>
> **Time to read:** ~12 minutes
>
> **Prerequisite knowledge:** Basic understanding of Dart (see [flutter-basics.md](docs/flutter-basics.md) for a quick primer)

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Key Technologies](#key-technologies)
4. [How Data Flows](#how-data-flows)
5. [Understanding the Code](#understanding-the-code)
6. [Common Patterns](#common-patterns)

---

## Architecture Overview

ZeroSpoils uses **clean architecture** with clear separation of concerns. Think of it as organized layers:

```
┌─────────────────────────────────┐
│   UI Layer (Screens, Widgets)   │  What users see & interact with
├─────────────────────────────────┤
│   State Management (Riverpod)   │  Manages data flow & dependencies
├─────────────────────────────────┤
│   Routing (GoRouter)            │  Navigation & deep linking
├─────────────────────────────────┤
│   Data Layer (Repositories)     │  Fetches data from local DB or API
├─────────────────────────────────┤
│   Local Storage (Hive)          │  SQLite-like database on device
└─────────────────────────────────┘
```

**Benefits of this structure:**
- 🧩 **Testable**: Each layer can be tested independently
- 🔄 **Maintainable**: Changes in one layer don't break others
- 👥 **Scalable**: Easy to add features without tangling code
- 📱 **Offline-first**: Data lives on device, can sync later

---

## Project Structure

```
app/
├── lib/
│   ├── main.dart                    # Entry point - initializes app
│   ├── core/
│   │   └── constants/
│   │       └── design_tokens.dart   # Colors, spacing, typography (design system)
│   └── presentation/
│       ├── di/
│       │   └── service_locator.dart # Dependency injection setup (Riverpod)
│       ├── routing/
│       │   └── router.dart          # Navigation configuration (GoRouter)
│       ├── themes/
│       │   └── app_theme.dart       # Material 3 theme
│       ├── screens/
│       │   └── home_shell.dart      # Main navigation shell (tabs)
│       └── widgets/
│           └── base_components.dart # Reusable UI components
│
└── test/
    ├── widget_test.dart             # UI component tests
    └── unit/
        ├── di/
        │   └── service_locator_test.dart
        └── routing/
            └── router_test.dart
```

**Key point:** Currently, we have the **presentation** layer (UI). The **data** and **domain** layers will be added in future milestones as we implement features.

---

## Key Technologies

### 1. **GoRouter** - Navigation & Deep Linking

**What it is:** A package that manages app navigation (screens, routing, deep links).

**Why we use it:**
- ✅ Type-safe routing (no magic strings)
- ✅ Deep linking support (open app via URLs)
- ✅ Nested navigation (tabs within screens)
- ✅ Route parameters (e.g., `/item/123`)

**Example from our code:**

```dart
// app/lib/presentation/routing/router.dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final itemId = state.pathParameters['id']!;
        return ItemDetailScreen(itemId: itemId);
      },
    ),
  ],
);
```

**Where you'll use it:**
- Navigate between screens: `context.go('/item/123')`
- Get route parameters: `GoRouterState.of(context).pathParameters['id']`

---

### 2. **Riverpod** - State Management & Dependency Injection

**What it is:** A package that manages app state and provides dependencies (like service instances).

**Why we use it:**
- ✅ Reactive state (when data changes, UI automatically updates)
- ✅ Dependency injection (centralized access to services)
- ✅ Easy to test (providers can be overridden)
- ✅ Works great with async data (API calls, database queries)

**Example from our code:**

```dart
// app/lib/presentation/di/service_locator.dart
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
});
```

**Think of providers as:**
- 📦 **Containers** that hold data or logic
- 🔄 **Reactive** - when the data changes, widgets listening to it automatically update
- 🔗 **Dependency injection** - instead of manually creating instances, ask Riverpod for them

**Where you'll use it:**
```dart
// In a widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get data from a provider
    final isOnline = ref.watch(connectivityProvider);
    
    return Text(isOnline.when(
      data: (online) => online ? 'Online' : 'Offline',
      loading: () => 'Checking...',
      error: (err, st) => 'Error',
    ));
  }
}
```

---

### 3. **Hive** - Local Database

**What it is:** A lightweight, on-device database (like SQLite, but simpler).

**Why we use it:**
- ✅ No setup needed (just save/load objects)
- ✅ Fast (written in Dart/C)
- ✅ Encrypted storage (for security)
- ✅ Perfect for offline-first apps

**Example:**
```dart
// Open a box (like a table)
final itemBox = await Hive.openBox('items');

// Save data
await itemBox.put('item_1', itemData);

// Load data
final item = itemBox.get('item_1');
```

**In our app:**
- Initialized in `main.dart` before the app starts
- Used by repositories to store and fetch data
- Will be used for offline inventory, shopping lists, etc.

---

### 4. **Material 3** - Design System

**What it is:** Google's modern design language built into Flutter.

**Why we use it:**
- ✅ Beautiful, modern UI out of the box
- ✅ Consistent across iOS and Android
- ✅ Accessibility features built-in
- ✅ Dark mode support

**Example from our code:**

```dart
// app/lib/core/constants/design_tokens.dart
class DesignTokens {
  static const Color primaryColor = Color(0xFF2D5016);  // Green
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  // ... more tokens
}

// app/lib/presentation/themes/app_theme.dart
final theme = ThemeData.light(useMaterial3: true);
  .copyWith(
    primaryColor: DesignTokens.primaryColor,
    scaffoldBackgroundColor: DesignTokens.backgroundColor,
  );
```

---

## How Data Flows

Let's trace a simple example: **User opens app → sees home screen with tabs**

### Step 1: App Starts
```dart
// main.dart - Entry point
void main() async {
  // 1. Initialize local database
  await Hive.initFlutter();
  
  // 2. Run the app
  runApp(const ZeroSpoilsApp());
}
```

### Step 2: App Widget Wraps Everything
```dart
// main.dart
class ZeroSpoilsApp extends StatelessWidget {
  const ZeroSpoilsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(  // ← Riverpod wrapper
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,  // ← GoRouter
      ),
    );
  }
}
```

**What's happening:**
- `ProviderScope` - enables Riverpod throughout the app
- `MaterialApp.router` - enables GoRouter for navigation
- `routerConfig: router` - uses our GoRouter configuration

### Step 3: Router Shows Initial Route
```dart
// router.dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),  // ← Shows this screen
    ),
  ],
);
```

### Step 4: HomeShell Screen Renders
```dart
// home_shell.dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),  // ← Shows current tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(label: 'Inventory', icon: Icon(Icons.list)),
          BottomNavigationBarItem(label: 'Expiring', icon: Icon(Icons.warning)),
          // ... more tabs
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemModal(context),  // ← FAB action
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Summary of flow:**
```
main.dart (initialize Hive)
    ↓
ZeroSpoilsApp (setup Riverpod + GoRouter + theme)
    ↓
GoRouter shows '/' route
    ↓
HomeShell screen displays
    ↓
User sees 4 tabs + FAB
```

---

## Understanding the Code

### A. Reading a Widget

**File:** `app/lib/presentation/screens/home_shell.dart`

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  
  // ✅ StatefulWidget - widget that manages its own state (tab selection)
  
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;  // ← Track which tab is selected
  
  @override
  Widget build(BuildContext context) {
    // ← Called whenever setState() is triggered
    return Scaffold(
      body: _buildScreen(_selectedIndex),      // Top section
      bottomNavigationBar: BottomNavigationBar( // Bottom tabs
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);  // ← Update tab
        },
        // ... rest of config
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const PlaceholderScreen(title: 'Inventory');
      case 1:
        return const PlaceholderScreen(title: 'Expiring Soon');
      case 2:
        return const PlaceholderScreen(title: 'Shopping List');
      case 3:
        return const PlaceholderScreen(title: 'Settings');
      default:
        return const PlaceholderScreen(title: 'Unknown');
    }
  }
}
```

**Key concepts:**
- `StatefulWidget` - widget that maintains state (like tab selection)
- `setState()` - tells Flutter "data changed, rebuild me"
- `Scaffold` - provides standard app structure (app bar, body, FAB, etc.)

### B. Dependency Injection with Riverpod

**File:** `app/lib/presentation/di/service_locator.dart`

```dart
// A "provider" is like a container that provides data/services
final connectivityProvider = StreamProvider<bool>((ref) {
  // This runs once, then watches for changes
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
});

// Another provider that depends on the first one
final telemetryProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});
```

**When you need to use these providers:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Watch" the provider - widget rebuilds when data changes
    final isOnline = ref.watch(connectivityProvider);
    
    final telemetry = ref.watch(telemetryProvider);
    
    return Text(isOnline.when(
      data: (online) => 'Online: $online',
      loading: () => 'Loading...',
      error: (err, _) => 'Error: $err',
    ));
  }
}
```

**Key concepts:**
- Providers are defined once, used everywhere
- No need to manually pass instances through constructors
- Changes automatically propagate to listening widgets

### C. Navigation with GoRouter

**File:** `app/lib/presentation/routing/router.dart`

```dart
final router = GoRouter(
  routes: [
    // Home route
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),
    ),
    
    // Item detail route (with parameter)
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        // Extract the 'id' parameter from the URL
        final itemId = state.pathParameters['id']!;
        return ItemDetailScreen(itemId: itemId);
      },
    ),
  ],
);
```

**Using it in your code:**
```dart
// Navigate to home
context.go('/');

// Navigate with parameter
context.go('/item/123');

// Go back
context.pop();
```

---

## Common Patterns

### Pattern 1: Create a New Screen

1. **Create the widget** in `lib/presentation/screens/my_screen.dart`:
```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(
        child: Text('Hello!'),
      ),
    );
  }
}
```

2. **Add a route** in `lib/presentation/routing/router.dart`:
```dart
GoRoute(
  path: '/my-screen',
  builder: (context, state) => const MyScreen(),
),
```

3. **Navigate to it:**
```dart
context.go('/my-screen');
```

### Pattern 2: Add a Dependency (Service)

1. **Create the service** in `lib/data/services/my_service.dart`:
```dart
class MyService {
  void doSomething() {
    print('Doing something!');
  }
}
```

2. **Add a provider** in `lib/presentation/di/service_locator.dart`:
```dart
final myServiceProvider = Provider<MyService>((ref) {
  return MyService();
});
```

3. **Use it in a widget:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(myServiceProvider);
    return Text(service.doSomething());
  }
}
```

### Pattern 3: Store Data in Hive

1. **Open a box** (usually in `main.dart` or initialization):
```dart
final itemBox = await Hive.openBox('items');
```

2. **Save data:**
```dart
await itemBox.put('item_1', {
  'name': 'Milk',
  'expiryDate': '2026-01-20',
});
```

3. **Load data:**
```dart
final item = itemBox.get('item_1');
print(item['name']);  // 'Milk'
```

---

## Next Steps

Once you understand this document:

1. **Read [flutter-basics.md](docs/flutter-basics.md)** - for Dart/Flutter fundamentals
2. **Read [code-patterns.md](docs/code-patterns.md)** - for detailed code patterns and examples
3. **Explore the actual code:**
   - Start with `app/lib/main.dart` - see how it all connects
   - Then look at `app/lib/presentation/screens/home_shell.dart` - see the main UI
   - Check `app/lib/presentation/routing/router.dart` - understand navigation
   - Check `app/lib/presentation/di/service_locator.dart` - understand DI

4. **Run the app locally:**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

5. **Explore with breakpoints:**
   - Set a breakpoint in `main.dart`
   - Run the app in debug mode
   - Step through the code to see execution flow

---

## Glossary

| Term | Meaning |
|------|---------|
| **Provider** | A Riverpod container that holds data or a service |
| **Route** | A path/screen in the app (e.g., `/`, `/item/123`) |
| **Widget** | A UI component in Flutter |
| **StatefulWidget** | A widget that maintains its own state |
| **StatelessWidget** | A widget that doesn't change (immutable) |
| **setState()** | Tells Flutter to rebuild a StatefulWidget |
| **ConsumerWidget** | A widget that can access Riverpod providers |
| **GoRoute** | A single route definition in GoRouter |
| **Scaffold** | Standard Flutter app structure (app bar, body, FAB, etc.) |
| **Hive Box** | A container/table in Hive for storing data |

---

## Questions?

If something is unclear:
1. Check the code files mentioned in each section
2. Read the inline comments in the code
3. Search the Riverpod/GoRouter documentation
4. Ask in team discussions - document the answer for future reference!

