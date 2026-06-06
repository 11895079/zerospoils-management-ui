import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/domain/models/receipt_line_item.dart';
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

  testWidgets(
    'review screen renders OCR overlay boxes for parsed receipt items',
    (tester) async {
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
                  name: 'PREMIUM BANANA',
                  price: 2.07,
                  receiptPhotoIndex: 0,
                  receiptBox: const ReceiptOcrBox(
                    left: 24,
                    top: 160,
                    right: 300,
                    bottom: 214,
                  ),
                ),
              ],
              batchId: 'batch-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receipt_review_overlay_0')), findsOneWidget);
      expect(
        find.byKey(const Key('receipt_review_overlay_box_0_0')),
        findsOneWidget,
      );
    },
  );

  testWidgets('excluded rows appear in hidden section and can be promoted', (
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
            parsedItems: const [],
            excludedRows: const [
              ReceiptClassifiedRow(
                text: 'HST 1.25',
                photoIndex: 0,
                box: ReceiptOcrBox(left: 24, top: 120, right: 200, bottom: 160),
                classification: ReceiptRowClassification.tax,
              ),
            ],
            batchId: 'batch-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hidden receipt lines (1)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('receipt_hidden_lines_section')),
      findsOneWidget,
    );

    await tester.tap(find.text('Hidden receipt lines (1)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('receipt_hidden_item_0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_hidden_promote_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('receipt_hidden_item_0')), findsNothing);
    expect(find.textContaining('HST 1.25'), findsWidgets);
  });

  testWidgets('included rows can be demoted into hidden section', (
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
            parsedItems: [ParsedReceiptItem(name: 'MILK', price: 5.49)],
            batchId: 'batch-3',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final demoteButton = find.byIcon(Icons.visibility_off_outlined).first;
    await tester.ensureVisible(demoteButton);
    await tester.pumpAndSettle();
    await tester.tap(demoteButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Hidden receipt lines'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('Hidden receipt lines'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_hidden_item_0')), findsOneWidget);
  });

  testWidgets('review screen shows a collapsible receipt summary footer', (
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
            parsedItems: [ParsedReceiptItem(name: 'MILK', price: 5.49)],
            batchId: 'batch-4',
            receiptTaxAmount: 0.58,
            receiptTotalAmount: 31.61,
            receiptSavingsAmount: 0.50,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_summary_footer')), findsOneWidget);
    expect(find.byKey(const Key('receipt_summary_toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_summary_toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_summary_subtotal_value')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_summary_tax_value')), findsOneWidget);
    expect(
      find.byKey(const Key('receipt_summary_savings_value')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_summary_total_value')),
      findsOneWidget,
    );

    expect(
      tester
          .widget<Text>(find.byKey(const Key('receipt_summary_subtotal_value')))
          .data,
      r'$31.03',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('receipt_summary_tax_value')))
          .data,
      r'$0.58',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('receipt_summary_savings_value')))
          .data,
      r'$0.50',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('receipt_summary_total_value')))
          .data,
      r'$31.61',
    );
  });
}
