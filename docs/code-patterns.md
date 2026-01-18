# ZeroSpoils Code Patterns & Examples

> **Who is this for?** Developers who understand Flutter basics and want to see how to implement common patterns.
>
> **Time to read:** ~10 minutes
>
> **Prerequisite:** Read [ARCHITECTURE.md](../ARCHITECTURE.md) and [flutter-basics.md](flutter-basics.md) first

## Table of Contents

1. [Navigation Patterns](#navigation-patterns)
2. [State Management with Riverpod](#state-management-with-riverpod)
3. [Building Screens](#building-screens)
4. [Working with Lists & Grids](#working-with-lists--grids)
5. [Handling User Input](#handling-user-input)
6. [Error Handling](#error-handling)
7. [Testing Patterns](#testing-patterns)

---

## Navigation Patterns

### Pattern 1: Simple Navigation

**Goal:** User taps a button and goes to another screen.

```dart
// In a widget, navigate when button is pressed
ElevatedButton(
  onPressed: () {
    context.go('/my-screen');
  },
  child: const Text('Go to My Screen'),
)

// GoRouter config in router.dart
GoRoute(
  path: '/my-screen',
  builder: (context, state) => const MyScreen(),
),
```

**File references:**
- Router config: `app/lib/presentation/routing/router.dart`
- Example screen: `app/lib/presentation/screens/home_shell.dart` (see `_showAddItemModal`)

---

### Pattern 2: Navigation with Parameters

**Goal:** Pass data to another screen via URL parameter.

```dart
// Navigate with ID parameter
context.go('/item/$itemId');  // itemId = '123'

// In router.dart, extract the parameter
GoRoute(
  path: '/item/:id',
  builder: (context, state) {
    final itemId = state.pathParameters['id']!;
    return ItemDetailScreen(itemId: itemId);
  },
),

// In ItemDetailScreen
class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  
  const ItemDetailScreen({required this.itemId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Item: $itemId')),
      body: Center(child: Text('Showing item $itemId')),
    );
  }
}
```

**File references:**
- Router patterns: `app/lib/presentation/routing/router.dart`

---

### Pattern 3: Going Back

```dart
// Pop (go back one screen)
context.pop();

// In a button
ElevatedButton(
  onPressed: () => context.pop(),
  child: const Text('Back'),
)
```

---

## State Management with Riverpod

### Pattern 1: Creating a Simple Provider

**Goal:** Share data that doesn't change (like a service).

```dart
// In service_locator.dart
final myServiceProvider = Provider<MyService>((ref) {
  return MyService();  // ← Created once, reused everywhere
});

// Use it in a widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(myServiceProvider);
    
    return ElevatedButton(
      onPressed: () => service.doSomething(),
      child: const Text('Do Something'),
    );
  }
}
```

**File references:**
- Service locator: `app/lib/presentation/di/service_locator.dart`

---

### Pattern 2: StreamProvider for Real-Time Data

**Goal:** Watch a stream and update UI when data changes.

```dart
// In service_locator.dart
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
});

// Use it in a widget
class ConnectionStatus extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityProvider);

    return isOnlineAsync.when(
      data: (isOnline) {
        return Text(
          isOnline ? '🟢 Online' : '🔴 Offline',
          style: TextStyle(color: isOnline ? Colors.green : Colors.red),
        );
      },
      loading: () => const Text('Checking...'),
      error: (err, stack) => const Text('❌ Error'),
    );
  }
}
```

**Explanation:**
- `StreamProvider` watches a stream for changes
- `.when()` handles three states: `data`, `loading`, `error`
- UI automatically updates when stream emits new data

**File references:**
- Stream provider example: `app/lib/presentation/di/service_locator.dart` (connectivityProvider)

---

### Pattern 3: Dependent Providers

**Goal:** One provider depends on another.

```dart
// Base provider
final userProvider = Provider<User>((ref) {
  return User(name: 'Alice', age: 30);
});

// Dependent provider - uses userProvider
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider);  // ← Watch another provider
  return '${user.name} (${user.age})';
});

// Use it
class UserInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(userDisplayNameProvider);
    return Text(displayName);  // Shows: Alice (30)
  }
}
```

---

## Building Screens

### Pattern 1: Basic Screen Structure

```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      appBar: AppBar(
        title: const Text('My Screen'),
        centerTitle: true,
        elevation: 0,
      ),
      
      // Main content
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Content goes here
          const Text('Hello, World!'),
        ],
      ),
      
      // Floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**File references:**
- Example: `app/lib/presentation/screens/home_shell.dart`

---

### Pattern 2: Tab Navigation

```dart
class TabScreen extends StatefulWidget {
  const TabScreen({super.key});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.home)),
          BottomNavigationBarItem(label: 'Search', icon: Icon(Icons.search)),
          BottomNavigationBarItem(label: 'Profile', icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeTab();
      case 1:
        return const SearchTab();
      case 2:
        return const ProfileTab();
      default:
        return const SizedBox();
    }
  }
}
```

**File references:**
- Example: `app/lib/presentation/screens/home_shell.dart`

---

### Pattern 3: Modal Dialog

```dart
// Show a dialog/modal
void _showModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Item'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Item name'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),  // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Do something
              context.pop();  // Close after action
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

// Call it
ElevatedButton(
  onPressed: () => _showModal(context),
  child: const Text('Show Modal'),
)
```

**File references:**
- Example: `app/lib/presentation/screens/home_shell.dart` (see `_showAddItemModal`)

---

## Working with Lists & Grids

### Pattern 1: Simple List

```dart
class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['Apple', 'Banana', 'Orange'];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
          onTap: () {
            // Handle tap
            context.go('/item/${items[index]}');
          },
        );
      },
    );
  }
}
```

**Key concepts:**
- `ListView.builder` - lazy loading (only builds visible items)
- `itemCount` - total number of items
- `itemBuilder` - builds each item

---

### Pattern 2: List with Cards

```dart
class ItemCardList extends StatelessWidget {
  final List<Item> items;
  
  const ItemCardList({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text(item.name),
            subtitle: Text(item.expiryDate),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Delete item
              },
            ),
          ),
        );
      },
    );
  }
}
```

---

### Pattern 3: Grid View

```dart
class ItemGrid extends StatelessWidget {
  final List<Item> items;
  
  const ItemGrid({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,  // 2 columns
        childAspectRatio: 1,  // Square items
        spacing: 12,  // Space between items
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.food_bank, size: 48),
              const SizedBox(height: 8),
              Text(item.name, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Handling User Input

### Pattern 1: Text Input

```dart
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final email = _emailController.text;
            final password = _passwordController.text;
            print('Email: $email, Password: $password');
          },
          child: const Text('Login'),
        ),
      ],
    );
  }
}
```

**Key concepts:**
- `TextEditingController` - read/write text input
- Always `dispose()` controllers in `dispose()` method
- `obscureText: true` - hides password input

---

### Pattern 2: Dropdown

```dart
class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({super.key});

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  String _selectedCategory = 'Vegetables';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedCategory,
      onChanged: (value) {
        setState(() => _selectedCategory = value!);
      },
      items: const [
        DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
        DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
        DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
      ],
    );
  }
}
```

---

### Pattern 3: Checkbox & Toggle

```dart
class ItemOptions extends StatefulWidget {
  const ItemOptions({super.key});

  @override
  State<ItemOptions> createState() => _ItemOptionsState();
}

class _ItemOptionsState extends State<ItemOptions> {
  bool _isPinned = false;
  bool _isArchived = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Pin to top'),
          value: _isPinned,
          onChanged: (value) {
            setState(() => _isPinned = value ?? false);
          },
        ),
        SwitchListTile(
          title: const Text('Archive'),
          value: _isArchived,
          onChanged: (value) {
            setState(() => _isArchived = value);
          },
        ),
      ],
    );
  }
}
```

---

## Error Handling

### Pattern 1: Try-Catch

```dart
Future<void> loadData() async {
  try {
    final data = await fetchFromAPI();
    print('Data: $data');
  } catch (e) {
    print('Error: $e');
    // Show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

---

### Pattern 2: Async/Await with UI

```dart
class AsyncDataWidget extends StatefulWidget {
  const AsyncDataWidget({super.key});

  @override
  State<AsyncDataWidget> createState() => _AsyncDataWidgetState();
}

class _AsyncDataWidgetState extends State<AsyncDataWidget> {
  late Future<List<Item>> itemsFuture;

  @override
  void initState() {
    super.initState();
    itemsFuture = fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Item>>(
      future: itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }
        
        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(items[index].name));
          },
        );
      },
    );
  }
}
```

---

## Testing Patterns

### Pattern 1: Widget Test

```dart
// File: test/widget_test.dart
void main() {
  testWidgets('Home screen displays 4 tabs', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: ZeroSpoilsApp()));

    // Check if tabs are present
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Expiring'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tapping tab changes content', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZeroSpoilsApp()));

    // Tap second tab
    await tester.tap(find.byIcon(Icons.warning));
    await tester.pumpAndSettle();

    // Verify content changed
    expect(find.text('Expiring Soon'), findsOneWidget);
  });
}
```

**File references:**
- Examples: `app/test/widget_test.dart`, `app/test/widget/screens/home_shell_test.dart`

---

### Pattern 2: Unit Test

```dart
// File: test/unit/services/my_service_test.dart
void main() {
  group('MyService', () {
    test('doSomething returns correct value', () {
      final service = MyService();
      expect(service.doSomething(), equals(42));
    });

    test('getValue returns expected data', () {
      final service = MyService();
      expect(service.getValue(), isNotEmpty);
    });
  });
}
```

**File references:**
- Examples: `app/test/unit/di/service_locator_test.dart`, `app/test/unit/routing/router_test.dart`

---

### Pattern 3: Provider Override in Tests

```dart
void main() {
  testWidgets('Widget works with mocked provider', (WidgetTester tester) async {
    // Override a provider for testing
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myServiceProvider.overrideWithValue(MockMyService()),
        ],
        child: const ZeroSpoilsApp(),
      ),
    );

    // Test with mocked provider
    expect(find.text('Expected text'), findsOneWidget);
  });
}
```

---

## Quick Reference

### Common Imports

```dart
// Flutter basics
import 'package:flutter/material.dart';

// State management
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation
import 'package:go_router/go_router.dart';

// Testing
import 'package:flutter_test/flutter_test.dart';

// Our app
import 'package:zerospoils/presentation/di/service_locator.dart';
import 'package:zerospoils/presentation/routing/router.dart';
```

### Common Functions

```dart
// Navigation
context.go('/path');           // Navigate to path
context.pop();                 // Go back

// State updates
setState(() => variable = value);

// Show messages
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
);

// Dialogs
showDialog(context: context, builder: (ctx) => ...);

// Async
await Future.delayed(Duration(seconds: 1));
```

---

## Next Steps

1. **Try each pattern** in the code
2. **Modify existing screens** using these patterns
3. **Write tests** for your changes
4. **Hot reload** to see changes instantly
5. **Ask questions** if something is unclear

---

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [flutter-basics.md](flutter-basics.md) - Language fundamentals
- Actual code in `app/lib/` - Real implementations
- Test files in `app/test/` - Test examples

