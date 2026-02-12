import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/receipt_batches_screen.dart';

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
    return _batches.firstWhere((b) => b.id == id);
  }
}

void main() {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(batches),
          ),
        ],
        child: const MaterialApp(home: ReceiptBatchesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receipt Batches'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('receipt_batch_card_batch-1')),
      findsOneWidget,
    );
  });
}
