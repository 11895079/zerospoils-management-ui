import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';
import 'package:zerospoils/presentation/widgets/app_button.dart';

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

  setUp(() async {
    repository = MockItemRepository();
    await repository.init(); // Initialize before use
  });

  testWidgets('saving new item calls repository.saveItem', (tester) async {
    // Make the viewport large enough to avoid overflow/scroll issues
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Enter required fields
    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Test Milk');

    // Quantity field is the second TextFormField (after name)
    final quantityField = find.byType(TextFormField).at(1);
    await tester.enterText(quantityField, '2');

    await tester.pumpAndSettle();

    // Tap the primary action button (AppButton)
    final addButton = find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.text == 'Add Item',
    );
    await tester.tap(addButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.name, 'Test Milk');
    expect(items.first.quantity, 2);
  });

  testWidgets('edit mode loads existing item from repository', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await repository.saveItem(existingItem);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: ItemFormScreen(itemId: existingItem.id)),
      ),
    );

    await tester.pumpAndSettle();

    // Ensure existing data is shown
    final nameField = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(nameField).controller?.text, 'Carrots');

    await tester.enterText(nameField, 'Baby Carrots');
    await tester.pumpAndSettle();

    final updateButton = find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.text == 'Update Item',
    );
    await tester.tap(updateButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final updated = await repository.getItem(existingItem.id);
    expect(updated?.name, 'Baby Carrots');
    expect(updated?.quantity, 3);
  });

  testWidgets(
    'selecting prepared type applies defaults and saves prepared item',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [itemRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Prepared'));
      await tester.pumpAndSettle();

      expect(find.text('Prepared Date'), findsOneWidget);
      expect(find.text(StorageLocation.freezer.displayName), findsOneWidget);
      expect(find.textContaining('Expires:'), findsOneWidget);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Tomato Soup');
      await tester.pumpAndSettle();

      final addButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Add Item',
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final saved = (await repository.getAllItems()).single;
      expect(saved.type, ItemType.prepared);
      expect(saved.location, StorageLocation.freezer);
      expect(saved.preparedDate, isNotNull);
      expect(saved.expiryDate, isNotNull);
    },
  );

  testWidgets('invalid price shows validation error and prevents save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Price Test');

    final quantityField = find.byType(TextFormField).at(1);
    await tester.enterText(quantityField, '1');

    final priceField = find.byType(TextFormField).at(2);
    await tester.enterText(priceField, '-5');

    final addButton = find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.text == 'Add Item',
    );
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid price'), findsOneWidget);
    final items = await repository.getAllItems();
    expect(items, isEmpty);
  });

  testWidgets('tapping expiry opens date picker and applies selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Expires:'), findsOneWidget);
  });
}
