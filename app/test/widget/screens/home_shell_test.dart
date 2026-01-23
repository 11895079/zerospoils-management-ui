// Widget tests for HomeShell navigation
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/screens/home_shell.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';

/// Lightweight in-memory mock to avoid Hive I/O during widget tests
class MockItemRepository extends HiveItemRepository {
  bool _initialized = false;
  final Map<String, Item> _items = {};

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<Item>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.toList();
  }

  @override
  Future<Item?> getItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items[id];
  }

  @override
  Future<void> saveItem(Item item) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items.remove(id);
  }
}

void main() {
  late MockItemRepository mockRepo;

  setUp(() {
    mockRepo = MockItemRepository();
    mockRepo.init();
  });

  testWidgets('Tab navigation switches between screens', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget with mock repository
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(mockRepo)],
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify we start on Inventory tab
    expect(find.text('Inventory'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap on Expiring tab
    await tester.tap(find.text('Expiring'));
    await tester.pumpAndSettle();

    // Verify Expiring screen is shown (allow multiple matches for title + tab label)
    expect(find.text('Expiring Soon'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Tap on Shopping tab
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    // Verify Shopping List screen is shown
    expect(find.text('Shopping List'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown
    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Inventory screen displays Add Item FAB', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget with mock repository
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(mockRepo)],
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Inventory screen (tab 0) is visible with FAB
    expect(find.text('Inventory'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('+'), findsOneWidget);

    // Switch to Settings tab (tab 3)
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown without FAB
    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Switch back to Inventory tab (tab 0)
    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    // Verify FAB is back
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
  });
}
