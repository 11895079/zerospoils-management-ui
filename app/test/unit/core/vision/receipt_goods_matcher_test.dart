import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/vision/batch_goods_photo_service.dart';
import 'package:zerospoils/core/vision/receipt_alias_corpus.dart';
import 'package:zerospoils/core/vision/receipt_alias_seed_data.dart';
import 'package:zerospoils/core/vision/receipt_goods_matcher.dart';

import '../../../fixtures/receipt_public_sample_review.dart';

void main() {
  const matcher = ReceiptGoodsMatcher();

  BatchGoodsPhotoSuggestion suggestion(String name, double confidence) {
    return BatchGoodsPhotoSuggestion(
      name: name,
      confidence: confidence,
      source: 'test',
    );
  }

  group('ReceiptGoodsMatcher', () {
    test('uses a grouped reviewed seed dataset', () {
      expect(ReceiptAliasSeedData.groups.length, greaterThanOrEqualTo(4));
      expect(
        ReceiptAliasSeedData.groups.any(
          (group) => group.storeStyle == 'generic-grocery-dairy',
        ),
        isTrue,
      );
      expect(
        ReceiptAliasCorpus.entriesByStoreStyle['generic-grocery-protein']?.any(
              (entry) => entry.alias == 'chk thghs',
            ) ??
            false,
        isTrue,
      );
    });

    test('uses a structured corpus with phrase aliases first', () {
      expect(
        ReceiptAliasCorpus.phraseAliases.any(
          (entry) => entry.alias == 'chk thghs',
        ),
        isTrue,
      );
      expect(ReceiptAliasCorpus.tokenAliases['bns'], 'banana');
    });

    test('matches common grocery receipt shorthand cases', () {
      final cases = <({String receiptName, String goodsName})>[
        (receiptName: 'BAN', goodsName: 'Banana'),
        (receiptName: 'APL', goodsName: 'Apple'),
        (receiptName: 'APLS', goodsName: 'Apple'),
        (receiptName: 'AVOC', goodsName: 'Avocado'),
        (receiptName: 'BROC', goodsName: 'Broccoli'),
        (receiptName: 'CUKE', goodsName: 'Cucumber'),
        (receiptName: 'ROM LETT', goodsName: 'Romaine lettuce'),
        (receiptName: 'RMN LETT', goodsName: 'Romaine lettuce'),
        (receiptName: 'TOM', goodsName: 'Tomato'),
        (receiptName: 'TMTO SOUP', goodsName: 'Tomato soup'),
        (receiptName: 'SWT POT', goodsName: 'Sweet potato'),
        (receiptName: 'CHK BRST', goodsName: 'Chicken breast'),
        (receiptName: 'CHKN THGS', goodsName: 'Chicken thighs'),
        (receiptName: 'PK', goodsName: 'Pork'),
        (receiptName: 'SALM', goodsName: 'Salmon'),
        (receiptName: 'MLK', goodsName: 'Milk'),
        (receiptName: 'WMLK', goodsName: 'Whole milk'),
        (receiptName: 'GRK YGT', goodsName: 'Greek yogurt'),
        (receiptName: 'WMLK YOG', goodsName: 'Whole milk yogurt'),
        (receiptName: 'YGRT', goodsName: 'Yogurt'),
        (receiptName: 'STRWB', goodsName: 'Strawberry'),
      ];

      for (final testCase in cases) {
        final match = matcher.bestMatch(testCase.receiptName, [
          suggestion(testCase.goodsName, 0.9),
        ]);

        expect(match?.name, testCase.goodsName, reason: testCase.receiptName);
      }
    });

    test('matches reviewed public sample cases', () {
      for (final sample in ReceiptPublicSampleReview.matcherSamples) {
        final match = matcher.bestMatch(sample.receiptLine, [
          suggestion(sample.expectedGoodsName, 0.9),
        ]);

        expect(
          match?.name,
          sample.expectedGoodsName,
          reason:
              '${sample.dataset} ${sample.styleBucket} ${sample.receiptLine}',
        );
      }
    });

    test('avoids weak unrelated matches', () {
      final match = matcher.bestMatch('TOM SOUP', [suggestion('Banana', 0.99)]);

      expect(match, isNull);
    });

    test(
      'prefers the strongest relevant suggestion among multiple candidates',
      () {
        final match = matcher.bestMatch('BRST CHKN', [
          suggestion('Chicken breast', 0.74),
          suggestion('Chicken thighs', 0.99),
          suggestion('Pork', 0.98),
        ]);

        expect(match?.name, 'Chicken breast');
      },
    );

    test('uses confidence as a tie-break for equally relevant candidates', () {
      for (final sample in ReceiptPublicSampleReview.rankingSamples) {
        final match = matcher.bestMatch(
          sample.receiptLine,
          sample.goodsCandidates
              .map(
                (candidate) => suggestion(candidate.name, candidate.confidence),
              )
              .toList(),
          preferredStoreStyle: sample.preferredStoreStyle,
        );

        expect(match?.name, sample.expectedGoodsName, reason: sample.notes);
      }
    });
  });
}
