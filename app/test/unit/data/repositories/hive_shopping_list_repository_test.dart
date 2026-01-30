import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:zerospoils/domain/models/shopping_list_item.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';

void main() {
  group('HiveShoppingListRepository', () {
    late HiveShoppingListRepository repository;

    setUp(() async {
      // Initialize Hive for testing
      await setUpTestHive();
      repository = HiveShoppingListRepository();
      await repository.init();
      await repository.clear();
    });

    test('saveShoppingListItem persists and retrieves', () async {
      final item = ShoppingListItem(
        id: '1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        estimatedCost: 3.5,
        isPurchased: false,
        purchasedAt: null,
        notes: 'Organic',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.saveShoppingListItem(item);
      final all = await repository.getAllItems();
      expect(all.length, 1);
      expect(all.first, item);
    });

    test('getAllItems returns all shopping list items', () async {
      final now = DateTime.now();
      final items = [
        ShoppingListItem(id: '1', name: 'Milk', createdAt: now, updatedAt: now),
        ShoppingListItem(id: '2', name: 'Eggs', createdAt: now, updatedAt: now),
      ];
      for (final item in items) {
        await repository.saveShoppingListItem(item);
      }
      final all = await repository.getAllItems();
      expect(all.length, 2);
      expect(all, containsAll(items));
    });

    test('getPurchased filters correctly', () async {
      final now = DateTime.now();
      final purchased = ShoppingListItem(
        id: '1',
        name: 'Bread',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final unpurchased = ShoppingListItem(
        id: '2',
        name: 'Butter',
        isPurchased: false,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveShoppingListItem(purchased);
      await repository.saveShoppingListItem(unpurchased);
      final result = await repository.getPurchased();
      expect(result.length, 1);
      expect(result.first, purchased);
    });

    test('getUnpurchased filters correctly', () async {
      final now = DateTime.now();
      final purchased = ShoppingListItem(
        id: '1',
        name: 'Bread',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final unpurchased = ShoppingListItem(
        id: '2',
        name: 'Butter',
        isPurchased: false,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveShoppingListItem(purchased);
      await repository.saveShoppingListItem(unpurchased);
      final result = await repository.getUnpurchased();
      expect(result.length, 1);
      expect(result.first, unpurchased);
    });

    test('deleteItem removes from storage', () async {
      final now = DateTime.now();
      final item = ShoppingListItem(
        id: '1',
        name: 'Juice',
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveShoppingListItem(item);
      await repository.deleteItem('1');
      final all = await repository.getAllItems();
      expect(all, isEmpty);
    });

    test('markAsPurchased updates purchased_at timestamp', () async {
      final now = DateTime.now();
      final item = ShoppingListItem(
        id: '1',
        name: 'Apples',
        isPurchased: false,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveShoppingListItem(item);
      await repository.markAsPurchased('1');
      final updated = (await repository.getAllItems()).first;
      expect(updated.isPurchased, true);
      expect(updated.purchasedAt, isNotNull);
    });

    test('markAsUnpurchased clears purchased_at', () async {
      final now = DateTime.now();
      final item = ShoppingListItem(
        id: '1',
        name: 'Bananas',
        isPurchased: true,
        purchasedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveShoppingListItem(item);
      await repository.markAsUnpurchased('1');
      final updated = (await repository.getAllItems()).first;
      expect(updated.isPurchased, false);
      expect(updated.purchasedAt, isNull);
    });

    test('Data persists across app restarts', () async {
      // Skipped: hive_test uses in-memory storage, so persistence across restarts cannot be validated in this environment.
      // This test should be run as an integration test with real Hive storage.
      expect(
        true,
        true,
        reason: 'Persistence test skipped in hive_test environment.',
      );
    }, skip: true);

    tearDown(() async {
      await Hive.close();
    });
  });
}
