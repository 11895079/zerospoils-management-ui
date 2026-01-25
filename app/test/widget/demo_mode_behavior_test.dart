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

  testWidgets('Settings toggle is disabled when manual items exist', (
    tester,
  ) async {
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
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.onChanged, isNull);
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
      await tester.tap(find.text('🗑️').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Inventory should show empty state
      expect(find.text('No items yet'), findsOneWidget);

      // Manual items flag should be reset
      expect(container.read(hasManualItemsProvider), isFalse);
    },
  );

  testWidgets('Turning demo off clears repo and persists preference', (
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

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final items = await repo.getAllItems();
    expect(items, isEmpty);
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

      expect(find.text('Eggs'), findsOneWidget);
      expect(container.read(hasManualItemsProvider), isTrue);
    },
  );
}
