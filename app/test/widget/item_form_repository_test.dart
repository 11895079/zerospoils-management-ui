import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:zerospoils/data/adapters/item_adapter.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveItemRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(ItemAdapter().typeId)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemCategoryAdapter().typeId)) {
      Hive.registerAdapter(ItemCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(StorageLocationAdapter().typeId)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemStatusAdapter().typeId)) {
      Hive.registerAdapter(ItemStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(WasteReasonAdapter().typeId)) {
      Hive.registerAdapter(WasteReasonAdapter());
    }

    // Open the box before creating repository to avoid init race conditions
    await Hive.openBox<Item>('items');

    repository = HiveItemRepository(hive: Hive);
    await repository.init();
  });

  tearDown(() async {
    await repository.close();
    await Hive.close();
    try {
      await Hive.deleteFromDisk();
    } catch (_) {
      // Ignore deletion errors in tests
    }
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  });

  testWidgets('saving new item writes to Hive repository', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Test Milk');
    await tester.enterText(find.byType(TextFormField).at(1), '2');

    // Find the ElevatedButton (AppButton) for submit
    final addItemButton = find.byType(ElevatedButton).first;
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();

    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.name, 'Test Milk');
    expect(items.first.quantity, 2);
  });

  testWidgets('edit route loads existing item and saves updates', (
    tester,
  ) async {
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
        overrides: [hiveItemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: ItemFormScreen(itemId: existingItem.id)),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller?.text, 'Carrots');

    await tester.enterText(find.byType(TextFormField).first, 'Baby Carrots');

    // Find the ElevatedButton (AppButton) for submit
    final updateItemButton = find.byType(ElevatedButton).first;
    await tester.tap(updateItemButton);
    await tester.pumpAndSettle();

    final updated = await repository.getItem(existingItem.id);
    expect(updated?.name, 'Baby Carrots');
    expect(updated?.quantity, 3);
    expect(
      updated?.createdAt,
      existingItem.createdAt,
    ); // Verify createdAt preserved
  });
}
