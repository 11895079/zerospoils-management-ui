import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/domain/repositories/receipt_batch_stats_service.dart';

void main() {
  group('ReceiptBatchStatsService', () {
    test('computes consumed, wasted, remaining totals', () {
      final batch = ReceiptBatch(
        id: 'batch-1',
        createdAt: DateTime(2026, 2, 9),
        source: ReceiptBatchSource.shoppingList,
        items: [
          ReceiptBatchItem(
            id: 'r1',
            name: 'Milk',
            price: 4.99,
            quantity: 1,
            destination: ReceiptBatchDestination.inventory,
            inventoryItemId: 'i1',
          ),
          ReceiptBatchItem(
            id: 'r2',
            name: 'Apples',
            price: 3.49,
            quantity: 1,
            destination: ReceiptBatchDestination.inventory,
            inventoryItemId: 'i2',
          ),
          ReceiptBatchItem(
            id: 'r3',
            name: 'Bread',
            price: 2.50,
            quantity: 1,
            destination: ReceiptBatchDestination.inventory,
            inventoryItemId: 'i3',
          ),
        ],
      );

      final inventoryItems = [
        Item(
          id: 'i1',
          name: 'Milk',
          category: ItemCategory.dairy,
          location: StorageLocation.fridge,
          purchasePrice: 4.99,
          status: ItemStatus.consumed,
          createdAt: DateTime(2026, 2, 9),
          updatedAt: DateTime(2026, 2, 10),
        ),
        Item(
          id: 'i2',
          name: 'Apples',
          category: ItemCategory.produce,
          location: StorageLocation.fridge,
          purchasePrice: 3.49,
          status: ItemStatus.wasted,
          createdAt: DateTime(2026, 2, 9),
          updatedAt: DateTime(2026, 2, 11),
        ),
        Item(
          id: 'i3',
          name: 'Bread',
          category: ItemCategory.grains,
          location: StorageLocation.pantry,
          purchasePrice: 2.50,
          status: ItemStatus.available,
          createdAt: DateTime(2026, 2, 9),
          updatedAt: DateTime(2026, 2, 9),
        ),
      ];

      final service = ReceiptBatchStatsService();
      final stats = service.build(batch: batch, inventoryItems: inventoryItems);

      expect(stats.totalSpend, 10.98);
      expect(stats.consumedValue, 4.99);
      expect(stats.wastedValue, 3.49);
      expect(stats.remainingValue, 2.50);
    });

    test('treats shopping list items as remaining value', () {
      final batch = ReceiptBatch(
        id: 'batch-2',
        createdAt: DateTime(2026, 2, 10),
        source: ReceiptBatchSource.shoppingList,
        items: [
          ReceiptBatchItem(
            id: 'r1',
            name: 'Eggs',
            price: 5.25,
            quantity: 1,
            destination: ReceiptBatchDestination.shoppingList,
            shoppingListItemId: 's1',
          ),
        ],
      );

      final service = ReceiptBatchStatsService();
      final stats = service.build(batch: batch, inventoryItems: const []);

      expect(stats.totalSpend, 5.25);
      expect(stats.consumedValue, 0);
      expect(stats.wastedValue, 0);
      expect(stats.remainingValue, 5.25);
    });
  });
}
