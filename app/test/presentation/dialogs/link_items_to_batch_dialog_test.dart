library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/presentation/dialogs/link_items_to_batch_dialog.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

// Mock repository for testing
class MockItemRepository extends HiveItemRepository {
  Map<String, Item> items = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Item>> getAllItems() async => items.values.toList();

  @override
  Future<Item?> getItem(String id) async => items[id];

  @override
  Future<void> saveItem(Item item) async => items[item.id] = item;

  @override
  Future<void> deleteItem(String id) async => items.remove(id);

  @override
  Future<void> clear() async => items.clear();

  @override
  Future<void> close() async {}
}

void main() {
  group('LinkItemsToBatchDialog', () {
    late MockItemRepository mockItemRepository;
    late ReceiptBatch testBatch;

    setUp(() {
      mockItemRepository = MockItemRepository();
      testBatch = ReceiptBatch(
        id: 'batch-1',
        createdAt: DateTime.now(),
        source: ReceiptBatchSource.inventory,
        items: [],
      );
    });

    testWidgets('displays unlinked items', (WidgetTester tester) async {
      // Create test items - some linked, some not
      final now = DateTime.now();
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
        receiptBatchId: null, // unlinked
      );
      final item2 = Item(
        id: 'item-2',
        name: 'Bread',
        category: ItemCategory.grains,
        location: StorageLocation.pantry,
        createdAt: now,
        updatedAt: now,
        receiptBatchId: 'batch-1', // already linked to this batch
      );
      final item3 = Item(
        id: 'item-3',
        name: 'Cheese',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
        receiptBatchId: null, // unlinked
      );

      mockItemRepository.items = {
        'item-1': item1,
        'item-2': item2,
        'item-3': item3,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show title
      expect(find.text('Link Items to Batch'), findsOneWidget);

      // Should show only unlinked items (item1 and item3, not item2)
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cheese'), findsOneWidget);
      expect(find.text('Bread'), findsNothing); // item2 is already linked
    });

    testWidgets('allows selecting items', (WidgetTester tester) async {
      final now = DateTime.now();
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
      );
      final item2 = Item(
        id: 'item-2',
        name: 'Cheese',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
      );

      mockItemRepository.items = {'item-1': item1, 'item-2': item2};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap first checkbox
      final checkbox1 = find.byKey(const Key('link_item_checkbox_item-1'));
      expect(checkbox1, findsOneWidget);
      await tester.tap(checkbox1);
      await tester.pumpAndSettle();

      // Find and tap second checkbox
      final checkbox2 = find.byKey(const Key('link_item_checkbox_item-2'));
      expect(checkbox2, findsOneWidget);
      await tester.tap(checkbox2);
      await tester.pumpAndSettle();

      // Link button should be enabled
      final linkButton = find.widgetWithText(ElevatedButton, 'Link Selected');
      expect(linkButton, findsOneWidget);
    });

    testWidgets('links selected items to batch on confirm', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
        receiptBatchId: null,
      );
      final item2 = Item(
        id: 'item-2',
        name: 'Cheese',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
        receiptBatchId: null,
      );

      mockItemRepository.items = {'item-1': item1, 'item-2': item2};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select first item
      final checkbox1 = find.byKey(const Key('link_item_checkbox_item-1'));
      await tester.tap(checkbox1);
      await tester.pumpAndSettle();

      // Click link button
      final linkButton = find.widgetWithText(ElevatedButton, 'Link Selected');
      await tester.tap(linkButton);
      await tester.pumpAndSettle();

      // Verify item was saved with batch ID
      final savedItem = mockItemRepository.items['item-1'];
      expect(savedItem, isNotNull);
      expect(savedItem!.receiptBatchId, equals('batch-1'));

      // Second item should not be linked
      final notLinkedItem = mockItemRepository.items['item-2'];
      expect(notLinkedItem!.receiptBatchId, isNull);
    });

    testWidgets('shows error when no items selected', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
      );

      mockItemRepository.items = {'item-1': item1};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Click link button without selecting items
      final linkButton = find.widgetWithText(ElevatedButton, 'Link Selected');
      await tester.tap(linkButton);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Select at least one item to link'), findsOneWidget);
    });

    testWidgets('shows message when no unlinked items available', (
      WidgetTester tester,
    ) async {
      mockItemRepository.items = {};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No unlinked items available'), findsOneWidget);
    });

    testWidgets('closes dialog on cancel', (WidgetTester tester) async {
      final now = DateTime.now();
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        createdAt: now,
        updatedAt: now,
      );

      mockItemRepository.items = {'item-1': item1};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockItemRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: LinkItemsToBatchDialog(batch: testBatch)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Click cancel button
      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should pop without changes
      expect(find.byType(LinkItemsToBatchDialog), findsNothing);
    });
  });
}
