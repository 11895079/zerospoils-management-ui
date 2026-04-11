import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_review_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

void main() {
  testWidgets('review screen shows explanation cue for matched items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: ReceiptBatchReviewScreen(
            source: ReceiptBatchSource.inventory,
            photoPaths: const ['receipt-1.jpg'],
            parsedItems: [
              ParsedReceiptItem(
                name: 'CHKN',
                price: 7.99,
                sourceLabel: 'Receipt OCR + goods photo',
                matchExplanation:
                    'Matched to Chicken breast from goods photo (75% confidence, compact-chain-grocery style).',
              ),
            ],
            batchId: 'batch-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final explanation = tester.widget<Text>(
      find.byKey(const Key('receipt_review_item_explanation_0')),
    );

    expect(explanation.data, contains('Chicken breast'));
    expect(explanation.data, contains('75% confidence'));
  });
}
