import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/vision/batch_goods_photo_service.dart';
import 'package:zerospoils/presentation/receipt_batch/receipt_review_item_merger.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_review_screen.dart';

import '../../../fixtures/receipt_public_sample_review.dart';

void main() {
  BatchGoodsPhotoSuggestion suggestion(String name, double confidence) {
    return BatchGoodsPhotoSuggestion(
      name: name,
      confidence: confidence,
      source: 'goods-photo-test',
    );
  }

  group('ReceiptReviewItemMerger', () {
    test(
      'marks matched OCR items and appends only unmatched goods suggestions',
      () {
        final merger = ReceiptReviewItemMerger();

        final merged = merger.merge(
          parsedItems: [
            ParsedReceiptItem(name: 'BNNS', price: 1.25),
            ParsedReceiptItem(name: 'WHL MLK', price: 3.49),
          ],
          goodsSuggestions: [
            suggestion('Banana', 0.97),
            suggestion('Whole milk', 0.95),
            suggestion('Greek yogurt', 0.89),
          ],
        );

        expect(merged, hasLength(3));
        expect(merged[0].sourceLabel, 'Receipt OCR + goods photo');
        expect(merged[1].sourceLabel, 'Receipt OCR + goods photo');
        expect(merged[2].name, 'Greek yogurt');
        expect(merged[2].sourceLabel, 'Goods photo');
      },
    );

    test('matches reviewed public merge samples', () {
      final merger = ReceiptReviewItemMerger();

      for (final sample in ReceiptPublicSampleReview.mergeSamples) {
        final merged = merger.merge(
          parsedItems: sample.receiptLines
              .map((line) => ParsedReceiptItem(name: line, price: 1.0))
              .toList(),
          goodsSuggestions: sample.goodsSuggestions
              .map((name) => suggestion(name, 0.9))
              .toList(),
        );

        expect(
          merged.map((item) => item.sourceLabel).toList(),
          sample.expectedSourceLabels,
          reason: '${sample.dataset} ${sample.styleBucket}',
        );
        expect(
          merged
              .skip(sample.receiptLines.length)
              .map((item) => item.name)
              .toList(),
          sample.expectedTrailingGoodsOnly,
          reason: sample.notes,
        );
      }
    });

    test('suppresses lower-ranked sibling goods suggestions after a match', () {
      final merger = ReceiptReviewItemMerger();

      final merged = merger.merge(
        parsedItems: [ParsedReceiptItem(name: 'CHKN', price: 4.99)],
        goodsSuggestions: [
          suggestion('Chicken thighs', 0.94),
          suggestion('Chicken breast', 0.62),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.sourceLabel, 'Receipt OCR + goods photo');
    });

    test(
      'infers compact style from the batch and explains the winning match',
      () {
        final merger = ReceiptReviewItemMerger();

        final merged = merger.merge(
          parsedItems: [
            ParsedReceiptItem(name: 'BNNS', price: 1.25),
            ParsedReceiptItem(name: 'CHKN', price: 7.99),
          ],
          goodsSuggestions: [
            suggestion('Banana', 0.97),
            suggestion('Chicken thighs', 0.75),
            suggestion('Chicken breast', 0.75),
          ],
        );

        expect(merged, hasLength(2));
        expect(merged[1].sourceLabel, 'Receipt OCR + goods photo');
        expect(merged[1].matchExplanation, contains('Chicken breast'));
        expect(merged[1].matchExplanation, contains('compact-chain-grocery'));
      },
    );
  });
}
