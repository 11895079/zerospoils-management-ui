import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/vision/receipt_alias_corpus.dart';

void main() {
  group('ReceiptAliasCorpus', () {
    test('infers compact chain style from multiple compact aliases', () {
      final inferred = ReceiptAliasCorpus.inferPreferredStoreStyle([
        'BNNS',
        'BRST CHKN',
      ]);

      expect(inferred, 'compact-chain-grocery');
    });

    test('infers generic dairy style from generic dairy aliases', () {
      final inferred = ReceiptAliasCorpus.inferPreferredStoreStyle([
        'ORG MLK',
        'GRK YGT',
      ]);

      expect(inferred, 'generic-grocery-dairy');
    });

    test('returns null when there is no recognizable style evidence', () {
      final inferred = ReceiptAliasCorpus.inferPreferredStoreStyle([
        'HANDWRITTEN NOTE',
      ]);

      expect(inferred, isNull);
    });
  });
}
