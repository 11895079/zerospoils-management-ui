import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/data/repositories/item_repository_base.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_detail_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

class MockReceiptBatchRepository implements ReceiptBatchRepository {
  final ReceiptBatch batch;
  MockReceiptBatchRepository(this.batch);

  @override
  Future<void> init() async {}

  @override
  Future<List<ReceiptBatch>> getAllBatches() async => [batch];

  @override
  Future<void> saveBatch(ReceiptBatch batch) async {}

  @override
  Future<ReceiptBatch?> getBatch(String id) async => batch;
}

class MockItemRepository implements ItemRepositoryBase {
  final List<Item> _items;
  MockItemRepository(this._items);

  @override
  Future<void> init() async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<List<Item>> getAllItems() async => _items;

  @override
  Future<Item?> getItem(String id) async =>
      _items.firstWhere((item) => item.id == id);

  @override
  Future<void> saveItem(Item item) async {}
}

void main() {
  Future<void> pumpReceiptBatchDetailScreen(
    WidgetTester tester, {
    required ReceiptBatch batch,
    required List<Item> inventoryItems,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(batch),
          ),
          itemRepositoryProvider.overrideWithValue(
            MockItemRepository(inventoryItems),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const ReceiptBatchDetailScreen(batchId: 'batch-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Batch detail screen shows totals and items', (
    WidgetTester tester,
  ) async {
    final batch = ReceiptBatch(
      id: 'batch-1',
      createdAt: DateTime(2026, 2, 9),
      source: ReceiptBatchSource.inventory,
      items: [
        ReceiptBatchItem(
          id: 'r1',
          name: 'Milk',
          price: 4.99,
          quantity: 1,
          destination: ReceiptBatchDestination.inventory,
          inventoryItemId: 'i1',
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
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 9),
        updatedAt: DateTime(2026, 2, 9),
      ),
    ];

    await pumpReceiptBatchDetailScreen(
      tester,
      batch: batch,
      inventoryItems: inventoryItems,
    );

    expect(
      find.byKey(const Key('screen_receipt_batch_detail')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_batch_summary')), findsOneWidget);
    expect(find.byKey(const Key('receipt_batch_item_r1')), findsOneWidget);
  });

  testWidgets('Batch detail screen uses dark theme surfaces', (
    WidgetTester tester,
  ) async {
    final batch = ReceiptBatch(
      id: 'batch-1',
      createdAt: DateTime(2026, 2, 9),
      source: ReceiptBatchSource.inventory,
      items: [
        ReceiptBatchItem(
          id: 'r1',
          name: 'Milk',
          price: 4.99,
          quantity: 1,
          destination: ReceiptBatchDestination.inventory,
          inventoryItemId: 'i1',
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
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 9),
        updatedAt: DateTime(2026, 2, 9),
      ),
    ];

    await pumpReceiptBatchDetailScreen(
      tester,
      batch: batch,
      inventoryItems: inventoryItems,
      themeMode: ThemeMode.dark,
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final summaryContainer = tester.widget<Container>(
      find.byKey(const Key('receipt_batch_summary')),
    );
    final summaryDecoration = summaryContainer.decoration as BoxDecoration;
    final theme = Theme.of(
      tester.element(find.byType(ReceiptBatchDetailScreen)),
    );

    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
    expect(summaryDecoration.color, theme.cardColor);
  });

  testWidgets('Batch detail screen shows goods photo count when present', (
    WidgetTester tester,
  ) async {
    final batch = ReceiptBatch(
      id: 'batch-1',
      createdAt: DateTime(2026, 2, 9),
      purchasedAt: DateTime(2026, 4, 10),
      storeName: 'Costco',
      totalAmount: 126.40,
      source: ReceiptBatchSource.inventory,
      items: [
        ReceiptBatchItem(
          id: 'r1',
          name: 'Milk',
          price: 4.99,
          quantity: 1,
          destination: ReceiptBatchDestination.inventory,
          inventoryItemId: 'i1',
        ),
      ],
      receiptImagePaths: const ['receipt-1.jpg'],
      goodsImagePaths: const ['goods-1.jpg'],
    );

    final inventoryItems = [
      Item(
        id: 'i1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        purchasePrice: 4.99,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 9),
        updatedAt: DateTime(2026, 2, 9),
      ),
    ];

    await pumpReceiptBatchDetailScreen(
      tester,
      batch: batch,
      inventoryItems: inventoryItems,
    );

    expect(
      find.text('Costco · Apr 10, 2026 · 1 receipts · 1 goods photos'),
      findsOneWidget,
    );
    expect(find.text('1 items · \$126.40 total'), findsOneWidget);
  });
}
