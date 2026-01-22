import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

/// Mock repository for testing without Hive file I/O
class MockItemRepository extends HiveItemRepository {
  final Map<String, Item> _items = {};
  bool _initialized = false;

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

  @override
  Future<void> close() async {
    // No-op for mock
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockItemRepository repository;

  setUp(() {
    repository = MockItemRepository();
    repository.init(); // Initialize before use
  });

  testWidgets('saving new item calls repository.saveItem', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    // Wait for initial build
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Test Milk');
    await tester.enterText(find.byType(TextFormField).at(1), '2');

    // Scroll to make button visible and tap
    await tester.ensureVisible(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton).first);

    // Wait for async save operation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.name, 'Test Milk');
    expect(items.first.quantity, 2);
  });

  testWidgets('edit mode loads existing item from repository', (tester) async {
    final existingItem = Item(
      id: 'edit-1',
      name: 'Carrots',
      category: ItemCategory.produce,
      location: StorageLocation.fridge,
      quantity: 3,
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      status: ItemStatus.available,
      wasteReason: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    await repository.init();
    await repository.saveItem(existingItem);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: ItemFormScreen(itemId: existingItem.id)),
      ),
    );

    // Wait for async load
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify form is populated
    final nameField = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(nameField).controller?.text, 'Carrots');

    // Clear and update the name
    await tester.enterText(nameField, 'Baby Carrots');

    // Scroll to button and tap
    await tester.ensureVisible(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton).first);

    // Wait for save
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final updated = await repository.getItem(existingItem.id);
    expect(updated?.name, 'Baby Carrots');
    expect(updated?.quantity, 3);
  });
}
