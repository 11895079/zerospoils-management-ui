import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HiveItemRepository', () {
    late HiveItemRepository repository;
    late Item testItem;
    late Directory tempDir;

    setUpAll(() async {
      // Create temp directory for tests
      tempDir = Directory.systemTemp.createTempSync('hive_test_');
      Hive.init(tempDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ItemCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(StorageLocationAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ItemStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WasteReasonAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ItemTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(UnitAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      repository = HiveItemRepository();
      await repository.init();
      await repository.clear();

      testItem = Item(
        id: 'test-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() async {
      try {
        await repository.clear();
        await repository.close();
      } catch (e) {
        // Ignore errors if box is already closed
      }
    });

    test('saveItem persists item', () async {
      await repository.saveItem(testItem);
      final items = await repository.getAllItems();
      expect(items.length, equals(1));
      expect(items.first.id, equals('test-1'));
    });

    test('getAllItems returns all items', () async {
      await repository.saveItem(testItem);
      await repository.saveItem(
        testItem.copyWith(id: 'test-2', name: 'Cheese'),
      );

      final items = await repository.getAllItems();
      expect(items.length, equals(2));
    });

    test('getItem returns specific item by id', () async {
      await repository.saveItem(testItem);
      final retrieved = await repository.getItem('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Milk'));
    });

    test('deleteItem removes item', () async {
      await repository.saveItem(testItem);
      await repository.deleteItem('test-1');

      final items = await repository.getAllItems();
      expect(items.length, equals(0));
    });

    test('getItemsByCategory filters by category', () async {
      final dairyItem = testItem;
      final meatItem = testItem.copyWith(
        id: 'meat-1',
        name: 'Chicken',
        category: ItemCategory.meat,
      );

      await repository.saveItem(dairyItem);
      await repository.saveItem(meatItem);

      final filtered = await repository.getItemsByCategory(ItemCategory.dairy);
      expect(filtered.length, equals(1));
      expect(filtered.first.category, equals(ItemCategory.dairy));
    });

    test('getItemsExpiringSoon returns items expiring within days', () async {
      final expiringItem = testItem.copyWith(
        id: 'expiring-1',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
      );
      final notExpiringItem = testItem.copyWith(
        id: 'fresh-1',
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );

      await repository.saveItem(expiringItem);
      await repository.saveItem(notExpiringItem);

      final expiring = await repository.getItemsExpiringSoon(3);
      expect(expiring.length, equals(1));
      expect(expiring.first.id, equals('expiring-1'));
    });

    test('clear removes all items', () async {
      await repository.saveItem(testItem);
      await repository.saveItem(testItem.copyWith(id: 'test-2'));
      expect((await repository.getAllItems()).length, equals(2));

      await repository.clear();
      expect((await repository.getAllItems()).length, equals(0));
    });

    test('persistence across restarts', () async {
      await repository.saveItem(testItem);
      await repository.close();

      // Reopen repository
      final newRepository = HiveItemRepository();
      await newRepository.init();

      final items = await newRepository.getAllItems();
      expect(items.length, equals(1));
      expect(items.first.id, equals('test-1'));

      await newRepository.close();
    });
  });
}
