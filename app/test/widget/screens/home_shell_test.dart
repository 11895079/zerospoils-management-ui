// Widget tests for HomeShell navigation
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/screens/home_shell.dart';
import 'package:zerospoils/domain/models/item_model.dart' show Item;
import 'package:zerospoils/domain/models/zesto_model.dart';
import 'package:zerospoils/domain/repositories/zesto_service.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';
import 'package:zerospoils/domain/models/shopping_list_item.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/widgets/feedback_drawer.dart';

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

class MockShoppingListRepository extends HiveShoppingListRepository {
  bool _initialized = false;
  final Map<String, ShoppingListItem> _items = {};

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<ShoppingListItem>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.toList();
  }
}

void main() {
  late MockItemRepository mockRepo;
  late MockShoppingListRepository mockShoppingRepo;

  setUp(() {
    mockRepo = MockItemRepository();
    mockRepo.init();
    mockShoppingRepo = MockShoppingListRepository();
    mockShoppingRepo.init();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tab navigation switches between screens', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget with mock repository
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepo),
          shoppingListRepositoryProvider.overrideWithValue(mockShoppingRepo),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify we start on Inventory tab
    expect(find.byKey(const Key('screen_inventory')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsOneWidget);

    // Tap on Expiring tab
    await tester.tap(find.byKey(const Key('nav_expiring')));
    await tester.pumpAndSettle();

    // Verify Expiring screen is shown
    expect(find.byKey(const Key('screen_expiring_today')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsNothing);

    // Tap on Shopping tab
    await tester.tap(find.byKey(const Key('nav_shopping')));
    await tester.pumpAndSettle();

    // Verify Shopping List screen is shown
    expect(find.byKey(const Key('screen_shopping_list')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsNothing);

    // Tap on Progress tab
    await tester.tap(find.byKey(const Key('nav_progress')));
    await tester.pumpAndSettle();

    // Verify Progress screen is shown
    expect(find.byKey(const Key('screen_progress')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsNothing);
  });

  testWidgets('Inventory screen displays Add Item FAB', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget with mock repository
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepo),
          shoppingListRepositoryProvider.overrideWithValue(mockShoppingRepo),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Inventory screen (tab 0) is visible with FAB
    expect(find.byKey(const Key('screen_inventory')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsOneWidget);

    // Switch to Progress tab (tab 3)
    await tester.tap(find.byKey(const Key('nav_progress')));
    await tester.pumpAndSettle();

    // Verify Progress screen is shown without FAB
    expect(find.byKey(const Key('screen_progress')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsNothing);

    // Open drawer and navigate to Settings
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer_settings_item')));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown
    expect(find.byKey(const Key('screen_settings')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsNothing);

    // Switch back to Inventory tab (tab 0)
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_inventory')));
    await tester.pumpAndSettle();

    // Verify FAB is back
    expect(find.byKey(const Key('inventory_add_fab')), findsOneWidget);
  });

  testWidgets('Drawer feedback entry opens feedback drawer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepo),
          shoppingListRepositoryProvider.overrideWithValue(mockShoppingRepo),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('drawer_feedback_item')));
    await tester.pumpAndSettle();

    expect(find.byKey(feedbackDrawerKey), findsOneWidget);
  });

  testWidgets('shows visible Zesto overlay when mascot trigger fires', (
    WidgetTester tester,
  ) async {
    final zestoService = ZestoService(
      getSettings: () => const MascotSettings(
        enabled: true,
        frequency: MascotFrequency.always,
      ),
      getStorageTips: () => const {
        'general': ['Tip A', 'Tip B'],
        'produce': ['Produce tip'],
      },
      displayDuration: Duration.zero,
    );
    addTearDown(zestoService.dispose);

    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(mockRepo),
        shoppingListRepositoryProvider.overrideWithValue(mockShoppingRepo),
        zestoServiceProvider.overrideWithValue(zestoService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    await tester.pumpAndSettle();

    await container
        .read(zestoServiceProvider)
        .showMascot(MascotMessageType.firstItem);
    await tester.pump();

    expect(find.byKey(const Key('zesto_overlay')), findsOneWidget);
    expect(find.byKey(const Key('zesto_message_text')), findsOneWidget);

    container.read(zestoServiceProvider).dismissMascot();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
  });
}
