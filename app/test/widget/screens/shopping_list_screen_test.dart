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
import 'package:zerospoils/presentation/themes/app_theme.dart';

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
  Future<void> pumpShoppingListScreen(
    WidgetTester tester, {
    required MockShoppingListRepository repository,
    required MockItemRepository itemRepository,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const ShoppingListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

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

    await pumpShoppingListScreen(
      tester,
      repository: repository,
      itemRepository: itemRepository,
    );

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

    await pumpShoppingListScreen(
      tester,
      repository: repository,
      itemRepository: itemRepository,
    );

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

  testWidgets('Shopping list shows explicit delete button for each item', (
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

    await pumpShoppingListScreen(
      tester,
      repository: repository,
      itemRepository: itemRepository,
    );

    expect(find.byKey(const Key('shopping_item_delete_1')), findsOneWidget);
  });

  testWidgets('uses dark theme surfaces in dark mode', (
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

    await pumpShoppingListScreen(
      tester,
      repository: repository,
      itemRepository: itemRepository,
      themeMode: ThemeMode.dark,
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final tileContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const Key('shopping_item_checkbox_1')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container && widget.decoration is BoxDecoration,
            ),
          )
          .first,
    );
    final decoration = tileContainer.decoration as BoxDecoration;
    final theme = Theme.of(tester.element(find.byType(ShoppingListScreen)));

    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
    expect(decoration.color, theme.cardColor);
  });

  testWidgets('empty-state heading uses dark theme text color', (
    WidgetTester tester,
  ) async {
    final repository = MockShoppingListRepository();
    final itemRepository = MockItemRepository();
    await repository.init();
    await itemRepository.init();

    await pumpShoppingListScreen(
      tester,
      repository: repository,
      itemRepository: itemRepository,
      themeMode: ThemeMode.dark,
    );

    final heading = tester.widget<Text>(
      find.text('Your shopping list is empty'),
    );
    final theme = Theme.of(tester.element(find.byType(ShoppingListScreen)));

    expect(heading.style?.color, theme.textTheme.titleLarge?.color);
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

    final expiryOneWeekButton = find.byKey(const Key('item_entry_expiry_1w'));
    await tester.ensureVisible(expiryOneWeekButton);
    await tester.tap(expiryOneWeekButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('item_entry_brand_field')),
      'Fairlife',
    );
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
    expect(inventoryItems.first.brand, 'Fairlife');
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

    final firstExpiryButton = find.byKey(const Key('item_entry_expiry_1w'));
    await tester.ensureVisible(firstExpiryButton);
    await tester.tap(firstExpiryButton);
    await tester.pumpAndSettle();
    final firstSave = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(firstSave);
    await tester.tap(firstSave);
    await tester.pumpAndSettle();

    final secondExpiryButton = find.byKey(const Key('item_entry_expiry_1w'));
    await tester.ensureVisible(secondExpiryButton);
    await tester.tap(secondExpiryButton);
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

    final applyAllExpiryButton = find.byKey(const Key('item_entry_expiry_1w'));
    await tester.ensureVisible(applyAllExpiryButton);
    await tester.tap(applyAllExpiryButton);
    await tester.pumpAndSettle();
    final applyAll = find.byKey(const Key('item_entry_apply_all'));
    await tester.ensureVisible(applyAll);
    await tester.tap(applyAll);
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('item_entry_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Poll until apply-to-all has persisted both converted items and removed
    // the purchased shopping-list entries. This avoids CI timing flakes where
    // async sheet dismissal and repository updates can land out of order.
    var attempts = 0;
    List<Item> inventoryItems = await itemRepository.getAllItems();
    List<ShoppingListItem> remainingShoppingItems = await repository
        .getAllItems();
    while ((inventoryItems.length < 2 || remainingShoppingItems.isNotEmpty) &&
        attempts < 50) {
      await tester.pump(const Duration(milliseconds: 100));
      inventoryItems = await itemRepository.getAllItems();
      remainingShoppingItems = await repository.getAllItems();
      attempts++;
    }

    expect(find.byKey(const Key('item_entry_sheet')), findsNothing);
    expect(inventoryItems.length, 2);
    expect(remainingShoppingItems, isEmpty);
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
