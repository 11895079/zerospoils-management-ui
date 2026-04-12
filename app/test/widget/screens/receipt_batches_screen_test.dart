import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/receipt_batches_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

class MockReceiptBatchRepository implements ReceiptBatchRepository {
  final List<ReceiptBatch> _batches;
  MockReceiptBatchRepository(this._batches);

  @override
  Future<void> init() async {}

  @override
  Future<List<ReceiptBatch>> getAllBatches() async => _batches;

  @override
  Future<void> saveBatch(ReceiptBatch batch) async {}

  @override
  Future<ReceiptBatch?> getBatch(String id) async {
    for (final batch in _batches) {
      if (batch.id == id) {
        return batch;
      }
    }
    return null;
  }
}

void main() {
  Future<void> pumpReceiptBatchesScreen(
    WidgetTester tester, {
    required List<ReceiptBatch> batches,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(batches),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const ReceiptBatchesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Receipt batches screen renders list', (
    WidgetTester tester,
  ) async {
    final batches = [
      ReceiptBatch(
        id: 'batch-1',
        createdAt: DateTime(2026, 2, 9),
        source: ReceiptBatchSource.shoppingList,
        items: const [],
      ),
    ];

    await pumpReceiptBatchesScreen(tester, batches: batches);

    expect(find.byKey(const Key('screen_receipt_batches')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('receipt_batch_card_batch-1')),
      findsOneWidget,
    );
  });

  testWidgets('Receipt batches screen uses dark theme surfaces', (
    WidgetTester tester,
  ) async {
    final batches = [
      ReceiptBatch(
        id: 'batch-1',
        createdAt: DateTime(2026, 2, 9),
        source: ReceiptBatchSource.shoppingList,
        items: const [],
      ),
    ];

    await pumpReceiptBatchesScreen(
      tester,
      batches: batches,
      themeMode: ThemeMode.dark,
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final batchCard = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('receipt_batch_card_batch-1')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container && widget.decoration is BoxDecoration,
            ),
          )
          .first,
    );
    final decoration = batchCard.decoration as BoxDecoration;
    final theme = Theme.of(tester.element(find.byType(ReceiptBatchesScreen)));

    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
    expect(decoration.color, theme.cardColor);
  });

  testWidgets('Receipt batches screen shows goods photo count when present', (
    WidgetTester tester,
  ) async {
    final batches = [
      ReceiptBatch(
        id: 'batch-1',
        createdAt: DateTime(2026, 2, 9),
        purchasedAt: DateTime(2026, 4, 10),
        storeName: 'Costco',
        totalAmount: 126.40,
        source: ReceiptBatchSource.shoppingList,
        items: const [],
        receiptImagePaths: const ['receipt-1.jpg'],
        goodsImagePaths: const ['goods-1.jpg', 'goods-2.jpg'],
      ),
    ];

    await pumpReceiptBatchesScreen(tester, batches: batches);

    final titleFinder = find.byKey(
      const Key('receipt_batch_card_title_batch-1'),
    );
    final summaryFinder = find.byKey(
      const Key('receipt_batch_card_summary_batch-1'),
    );

    expect(titleFinder, findsOneWidget);
    expect(summaryFinder, findsOneWidget);

    final titleText = tester.widget<Text>(titleFinder);
    final summaryText = tester.widget<Text>(summaryFinder);
    expect(titleText.data, contains('Costco'));
    expect(summaryText.data, contains('2 goods photos'));
    expect(summaryText.data, contains('1 receipts'));
  });
}
