// Tests for demo mode / manual items interactions and deletion safety
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/screens/inventory_screen.dart';
import 'package:zerospoils/presentation/screens/settings_screen.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/repositories/item_repository_base.dart';

class InMemoryItemRepository implements ItemRepositoryBase {
  final List<Item> _items;
  bool _initialized = false;

  InMemoryItemRepository({List<Item>? seed}) : _items = List.of(seed ?? []);

  @override
  Future<void> init() async {
    _initialized = true;
  }

  void _checkInit() {
    if (!_initialized) {
      throw StateError('Repository not initialized');
    }
  }

  @override
  Future<void> clear() async {
    _checkInit();
    _items.clear();
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteItem(String id) async {
    _checkInit();
    _items.removeWhere((i) => i.id == id);
  }

  @override
  Future<List<Item>> getAllItems() async {
    _checkInit();
    return List.unmodifiable(_items);
  }

  @override
  Future<Item?> getItem(String id) async {
    _checkInit();
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveItem(Item item) async {
    _checkInit();
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
  }
}

Item _sampleItem({String id = '1', String name = 'Milk'}) {
  return Item(
    id: id,
    name: name,
    category: ItemCategory.dairy,
    type: ItemType.raw,
    preparedDate: null,
    location: StorageLocation.fridge,
    quantity: 1,
    unit: Unit.count,
    expiryDate: DateTime.now().add(const Duration(days: 5)),
    purchasePrice: null,
    status: ItemStatus.available,
    wasteReason: null,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Deleting last real item clears manual flag and shows empty state',
    (tester) async {
      final repo = InMemoryItemRepository(seed: [_sampleItem()]);
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          demoModeProvider.overrideWith((ref) => false),
          hasManualItemsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: InventoryScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete icon, confirm dialog
      await tester.tap(find.byKey(const Key('item_card_delete_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory_delete_confirm')));
      await tester.pumpAndSettle();

      // Inventory should show empty state
      expect(find.byKey(const Key('inventory_empty_state')), findsOneWidget);

      // Manual items flag should be reset
      expect(container.read(hasManualItemsProvider), isFalse);
    },
  );

  testWidgets('Toggling demo mode switches databases without clearing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = InMemoryItemRepository(seed: [_sampleItem()]);
    await repo.init();

    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repo),
        demoModeProvider.overrideWith((ref) => true),
        hasManualItemsProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    // Verify demo mode is on and has seed item
    var items = await repo.getAllItems();
    expect(items.length, 1);
    expect(container.read(demoModeProvider), isTrue);

    // Toggle demo mode off
    final demoTile = find.ancestor(
      of: find.byIcon(Icons.bug_report),
      matching: find.byType(ListTile),
    );
    final demoSwitch = find.descendant(
      of: demoTile,
      matching: find.byType(Switch),
    );
    await tester.tap(demoSwitch);
    await tester.pumpAndSettle();

    // Demo data should NOT be cleared - toggling just switches the database
    items = await repo.getAllItems();
    expect(
      items.length,
      1,
      reason: 'Demo data should persist when switching databases',
    );
    expect(container.read(demoModeProvider), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('demo_mode_enabled'), isFalse);
  });

  testWidgets(
    'Adding item after demo off updates manual flag without provider mutation errors',
    (tester) async {
      final repo = InMemoryItemRepository();
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          demoModeProvider.overrideWith((ref) => false),
          hasManualItemsProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: InventoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(container.read(hasManualItemsProvider), isFalse);

      await repo.init();
      await repo.saveItem(_sampleItem(id: '2', name: 'Eggs'));
      container.invalidate(itemsFutureProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inventory_item_card_2')), findsOneWidget);
      expect(container.read(hasManualItemsProvider), isTrue);
    },
  );
}
