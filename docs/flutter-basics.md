# Flutter & Dart Basics for Beginners

> **Who is this for?** Developers new to Flutter/Dart who need a quick foundation.
>
> **Time to read:** ~8 minutes
>
> **What you'll learn:** Core Dart syntax and Flutter concepts needed to understand ZeroSpoils

## What is Flutter?

**Flutter** is a framework for building mobile apps (iOS, Android) and web apps from a **single codebase** using **Dart**.

**Key advantage:** Write once, run on iOS, Android, and web. No need to learn Swift or Kotlin.

---

## What is Dart?

**Dart** is the programming language that Flutter uses. It's similar to JavaScript, Python, or Kotlin, but optimized for building UIs.

### Basic Dart Syntax

#### 1. Variables

```dart
// Type inference - Dart figures out the type
var name = 'John';
var age = 30;

// Explicit types
String greeting = 'Hello';
int count = 5;
double price = 9.99;
bool isActive = true;

// final - value can't change after assignment
final constantValue = 42;  // Set once, never change

// const - compile-time constant (more restrictive)
const maxUsers = 100;
```

#### 2. Null Safety (Important!)

```dart
// In Dart, variables are non-null by default
String name = 'John';
name = null;  // ❌ ERROR - can't assign null to String

// To allow null, add '?'
String? nickname;  // Can be null
nickname = 'JD';   // Or a string

// Use '!' to assert it's not null (unsafe!)
String safeName = nickname!;  // ❌ Crashes if nickname is null

// Safe way - check before using
if (nickname != null) {
  print(nickname.length);  // Safe
}

// Elvis operator - use default if null
String displayName = nickname ?? 'Unknown';  // Use nickname, or 'Unknown' if null
```

#### 3. Functions

```dart
// Simple function
void greet(String name) {
  print('Hello, $name!');
}
greet('Alice');

// Function with return value
int add(int a, int b) {
  return a + b;
}
print(add(2, 3));  // 5

// Arrow function (single expression)
int multiply(int a, int b) => a * b;

// Optional parameters
void printInfo(String name, [String? age]) {
  print('Name: $name, Age: $age');
}
printInfo('Bob');           // Age is null
printInfo('Bob', '25');     // Age is 25

// Named parameters
void createUser({required String name, int age = 0}) {
  print('$name is $age years old');
}
createUser(name: 'Alice');           // age defaults to 0
createUser(name: 'Bob', age: 30);   // age is 30
```

#### 4. Classes

```dart
class User {
  final String name;
  final int age;

  // Constructor
  User({required this.name, required this.age});

  // Method
  void introduce() {
    print('I am $name, $age years old');
  }
}

final user = User(name: 'Alice', age: 30);
user.introduce();  // Prints: I am Alice, 30 years old
```

#### 5. Lists and Maps

```dart
// List - ordered collection
List<String> fruits = ['apple', 'banana', 'orange'];
print(fruits[0]);      // 'apple'
fruits.add('grape');   // Add item

// Map - key-value pairs (like dictionary/object)
Map<String, int> ages = {
  'Alice': 30,
  'Bob': 25,
  'Charlie': 35,
};
print(ages['Alice']);  // 30

// Access with default
String city = data['city'] ?? 'Unknown';
```

#### 6. Control Flow

```dart
// if-else
if (age < 13) {
  print('Child');
} else if (age < 18) {
  print('Teen');
} else {
  print('Adult');
}

// for loop
for (int i = 0; i < 5; i++) {
  print(i);
}

// for-each loop
for (var fruit in fruits) {
  print(fruit);
}

// while loop
int count = 0;
while (count < 5) {
  print(count);
  count++;
}

// switch
switch (day) {
  case 'Monday':
    print('Start of week');
    break;
  case 'Friday':
    print('Almost weekend');
    break;
  default:
    print('Regular day');
}
```

---

## Flutter Basics

### Widgets - The Building Blocks

Everything in Flutter is a **Widget**. Widgets are UI components.

```dart
// Button widget
ElevatedButton(
  onPressed: () {
    print('Button pressed!');
  },
  child: const Text('Click Me'),
)

// Text widget
Text(
  'Hello, Flutter!',
  style: TextStyle(fontSize: 24, color: Colors.blue),
)

// Container - a box to hold and style other widgets
Container(
  width: 200,
  height: 100,
  color: Colors.blue,
  child: const Center(
    child: Text('Inside box'),
  ),
)
```

### Layouts - Arranging Widgets

```dart
// Column - stack widgets vertically (top to bottom)
Column(
  children: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
  ],
)

// Row - arrange widgets horizontally (left to right)
Row(
  children: [
    Icon(Icons.star),
    Text('5 stars'),
  ],
)

// Scaffold - standard app structure
Scaffold(
  appBar: AppBar(title: const Text('My App')),
  body: Center(child: const Text('Content goes here')),
  floatingActionButton: FloatingActionButton(
    onPressed: () {},
    child: const Icon(Icons.add),
  ),
)
```

### Stateless vs Stateful Widgets

#### StatelessWidget - Doesn't Change

```dart
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('This never changes');
  }
}
```

**Use when:**
- Widget just displays static data
- No user interactions that change data in this widget
- Simple display components

#### StatefulWidget - Changes Over Time

```dart
class MyCounter extends StatefulWidget {
  const MyCounter({super.key});

  @override
  State<MyCounter> createState() => _MyCounterState();
}

class _MyCounterState extends State<MyCounter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++;  // Update state
            });
          },
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**Key concept: `setState()`**
- Call `setState()` to tell Flutter the data changed
- Flutter rebuilds the widget with new data
- Without `setState()`, the UI won't update!

**Use when:**
- Widget has data that changes
- User interactions update the widget
- Example: counters, form inputs, toggles

---

## String Interpolation (Super Important!)

```dart
// Embed variables in strings using $
String name = 'Alice';
int age = 30;

print('Hello, $name!');           // Hello, Alice!
print('I am $age years old');     // I am 30 years old

// For complex expressions, use ${}
print('Next year I will be ${age + 1}');  // Next year I will be 31
print('Name length: ${name.length}');     // Name length: 5
```

---

## Common Flutter Widgets

| Widget | Purpose |
|--------|---------|
| `Text` | Display text |
| `ElevatedButton` | Clickable button |
| `TextField` | Input field |
| `ListView` | Scrollable list |
| `GridView` | Grid of items |
| `Card` | Elevated container |
| `Icon` | Icon display |
| `Image` | Display image |
| `Scaffold` | App structure |
| `AppBar` | Top bar |
| `FloatingActionButton` | Floating action button |
| `Dialog` | Modal popup |

---

## The Widget Build Process

When Flutter runs:

```
1. StatelessWidget.build() is called
   ↓
2. Returned widget tree is rendered on screen
   ↓
3. User interacts (taps, types, etc.)
   ↓
4. setState() called (for StatefulWidgets only)
   ↓
5. Widget.build() called again with new data
   ↓
6. UI updates with new widget tree
```

**Example:**
```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    // This is called EVERY TIME state changes
    return Column(
      children: [
        Text('Count: $count'),  // ← Shows current count
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++;  // Trigger rebuild
            });
          },
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

When you tap the button:
1. `onPressed` callback is called
2. `setState()` is called inside
3. Flutter calls `build()` again
4. `Text` widget now shows new count
5. UI updates instantly

---

## Hot Reload

One of Flutter's superpowers is **hot reload**:

1. Make code change
2. Press `r` in terminal (or Cmd+S in VS Code with Flutter extension)
3. App updates in 1-2 seconds **without restarting**
4. State is preserved!

```bash
flutter run
# Make a change to your code, then:
# Press 'r' to hot reload
# Press 'R' to hot restart (restarts the app, clears state)
```

This makes development **super fast**.

---

## const vs final (Important for Performance)

```dart
// const - compile-time constant
const maxUsers = 100;      // Must be known at compile time
const colors = [Colors.red, Colors.blue];

// final - runtime constant (can't change, but computed at runtime)
final randomNum = Random().nextInt(100);  // ✅ OK with final
final randomNum = const Random().nextInt(100);  // ❌ Wrong with const

// In widgets, use 'const' for better performance
const Text('Hello');      // ✅ Good for performance
Text('Hello');            // ⚠️ OK but less efficient

// const constructor means the widget is immutable and never rebuilds
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});  // ← const constructor
  
  @override
  Widget build(BuildContext context) {
    return const Text('Unchanging');  // ← const widget
  }
}
```

**Rule of thumb:**
- Use `const` on widgets and constructors when possible (improves performance)
- Use `final` for variables that won't change
- Use `var` for local variables (Dart infers the type)

---

## Common Mistakes

### ❌ Mistake 1: Forgetting setState()

```dart
// ❌ UI won't update
onPressed: () {
  count++;  // Changed data, but didn't tell Flutter
},

// ✅ Correct
onPressed: () {
  setState(() {
    count++;  // Now Flutter knows to rebuild
  });
},
```

### ❌ Mistake 2: Assigning null to non-nullable

```dart
// ❌ Error
String name = null;

// ✅ Correct
String? name = null;  // The '?' means it can be null
```

### ❌ Mistake 3: Forgetting 'required' on parameters

```dart
// ❌ User might forget to pass email
class LoginWidget extends StatelessWidget {
  final String email;
  
  const LoginWidget(this.email);
}

// ✅ Correct - email is required
class LoginWidget extends StatelessWidget {
  final String email;
  
  const LoginWidget({required this.email});
}

// Usage
LoginWidget(email: 'user@example.com');  // Clear and required
```

---

## Next Steps

1. **Understand ZeroSpoils architecture** → Read [ARCHITECTURE.md](ARCHITECTURE.md)
2. **See code patterns** → Read [code-patterns.md](docs/code-patterns.md)
3. **Run the app:**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```
4. **Experiment:**
   - Make a small change to a widget
   - Hot reload with `r`
   - See the UI update instantly

---

## Resources

- [Dart Official Docs](https://dart.dev)
- [Flutter Official Docs](https://flutter.dev)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design overview
- [code-patterns.md](code-patterns.md) - Practical code examples
- [gradle-guide.md](gradle-guide.md) - Android build system (for troubleshooting)

