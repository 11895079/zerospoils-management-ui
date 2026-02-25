import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/item_model.dart' show Item;
import 'package:zerospoils/domain/models/shopping_list_item.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    show TelemetryClient, telemetryClientProvider;
import 'package:zerospoils/presentation/screens/shopping_list_screen.dart';

class MockShoppingListRepository extends HiveShoppingListRepository {
  bool _initialized = false;
  final Map<String, ShoppingListItem> _items = {};

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<void> saveShoppingListItem(ShoppingListItem item) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items[item.id] = item;
  }

  @override
  Future<List<ShoppingListItem>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.toList();
  }

  @override
  Future<ShoppingListItem?> getItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items[id];
  }

  @override
  Future<void> deleteItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items.remove(id);
  }

  @override
  Future<List<ShoppingListItem>> getPurchased() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.where((item) => item.isPurchased).toList();
  }

  @override
  Future<List<ShoppingListItem>> getUnpurchased() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.where((item) => !item.isPurchased).toList();
  }

  @override
  Future<void> markAsPurchased(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    final item = _items[id];
    if (item == null) return;
    _items[id] = item.copyWith(
      isPurchased: true,
      purchasedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAsUnpurchased(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    final item = _items[id];
    if (item == null) return;
    _items[id] = item.copyWith(
      isPurchased: false,
      purchasedAt: null,
      updatedAt: DateTime.now(),
    );
  }
}

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
  Future<void> saveItem(Item item) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items[item.id] = item;
  }
}

void main() {
  setUp(() {
    // Initialize SharedPreferences for telemetry consent provider
    SharedPreferences.setMockInitialValues({'analytics_consent': true});
  });

  testWidgets('Shopping list shows empty state when no items', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping_empty_state')), findsOneWidget);
  });

  testWidgets('Shopping list renders purchased and unpurchased sections', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(id: '1', name: 'Milk', createdAt: now, updatedAt: now),
    );
    await repository.saveShoppingListItem(
      ShoppingListItem(
        id: '2',
        name: 'Bread',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shopping_unpurchased_section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shopping_purchased_section')), findsOneWidget);
    expect(find.byKey(const Key('shopping_item_tile_1')), findsOneWidget);
    expect(find.byKey(const Key('shopping_item_tile_2')), findsOneWidget);
    expect(find.byKey(const Key('shopping_item_checkbox_1')), findsOneWidget);
    expect(find.byKey(const Key('shopping_item_checkbox_2')), findsOneWidget);
  });

  testWidgets('Checking item opens convert dialog', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(id: '1', name: 'Milk', createdAt: now, updatedAt: now),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_item_checkbox_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item_entry_sheet')), findsOneWidget);
  });

  testWidgets('Convert requires expiry date and saves inventory item', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(id: '1', name: 'Milk', createdAt: now, updatedAt: now),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_item_checkbox_1')));
    await tester.pumpAndSettle();

    final convertButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('item_entry_save')),
    );
    expect(convertButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('item_entry_expiry_1w')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle).first);
    await tester.pumpAndSettle();

    final enabledConvertButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('item_entry_save')),
    );
    expect(enabledConvertButton.onPressed, isNotNull);

    final saveButton = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping_item_tile_1')), findsNothing);
    final inventoryItems = await itemRepository.getAllItems();
    expect(inventoryItems.length, 1);
    expect(inventoryItems.first.quantity, 2);
  });

  testWidgets('Skip conversion keeps item purchased', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(id: '1', name: 'Bread', createdAt: now, updatedAt: now),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_item_checkbox_1')));
    await tester.pumpAndSettle();

    final skipButton = find.byKey(const Key('item_entry_skip'));
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping_item_tile_1')), findsOneWidget);
    expect(find.byKey(const Key('shopping_purchased_section')), findsOneWidget);
  });

  testWidgets('Batch convert processes purchased items', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(
        id: '1',
        name: 'Milk',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.saveShoppingListItem(
      ShoppingListItem(
        id: '2',
        name: 'Eggs',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_convert_batch_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_entry_expiry_1w')));
    await tester.pumpAndSettle();
    final firstSave = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(firstSave);
    await tester.tap(firstSave);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_entry_expiry_1w')));
    await tester.pumpAndSettle();
    final secondSave = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(secondSave);
    await tester.tap(secondSave);
    await tester.pumpAndSettle();

    final inventoryItems = await itemRepository.getAllItems();
    expect(inventoryItems.length, 2);
  });

  testWidgets('Batch convert apply-to-all skips repeated sheets', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    final telemetryClient = TelemetryClient(consentEnabled: true);
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(
        id: '1',
        name: 'Milk',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.saveShoppingListItem(
      ShoppingListItem(
        id: '2',
        name: 'Eggs',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
          telemetryClientProvider.overrideWith((ref) => telemetryClient),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_convert_batch_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_entry_expiry_1w')));
    await tester.pumpAndSettle();
    final applyAll = find.byKey(const Key('item_entry_apply_all'));
    await tester.ensureVisible(applyAll);
    await tester.tap(applyAll);
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item_entry_sheet')), findsNothing);
    final inventoryItems = await itemRepository.getAllItems();
    expect(inventoryItems.length, 2);
  });

  testWidgets('Add item creates entry and persists to repository', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping_empty_state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shopping_empty_cta')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('shopping_add_field')), 'Milk');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shopping_add_confirm')));
    await tester.pumpAndSettle();

    // Verify item appears in unpurchased section
    expect(
      find.byKey(const Key('shopping_unpurchased_section')),
      findsOneWidget,
    );
    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.name, 'Milk');
    // Verify the item tile exists (key generated from actual item ID)
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('Toggle purchased moves item between sections', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();
    final now = DateTime.now();

    await repository.saveShoppingListItem(
      ShoppingListItem(id: '1', name: 'Bread', createdAt: now, updatedAt: now),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: const MaterialApp(home: ShoppingListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shopping_unpurchased_section')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('shopping_item_checkbox_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item_entry_sheet')), findsOneWidget);

    final skipButton = find.byKey(const Key('item_entry_skip'));
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopping_purchased_section')), findsOneWidget);
    final item = await repository.getItem('1');
    expect(item?.isPurchased, true);

    await tester.tap(find.byKey(const Key('shopping_item_checkbox_1')));
    await tester.pumpAndSettle();

    final updatedItem = await repository.getItem('1');
    expect(updatedItem?.isPurchased, false);
  });
}
