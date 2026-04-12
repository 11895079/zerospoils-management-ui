import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/utils/fresh_produce_ocr_parser.dart';

void main() {
  group('FreshProduceOcrParser', () {
    const parser = FreshProduceOcrParser();

    test(
      'detects fresh-produce label when price-per-weight exists and no barcode',
      () {
        const text =
            'ATLANTIC SALMON FILLET\n0.742 KG @ 24.99/KG\nTOTAL 18.54\nBEST BEFORE 04/24/2026';

        expect(
          parser.shouldUseFreshProduceMode(text, hasBarcodeDetected: false),
          isTrue,
        );
      },
    );

    test('does not trigger fresh-produce mode when barcode is present', () {
      const text =
          'CEREAL FAMILY SIZE\nUPC 0678000012345\n\$5.99\nBEST BEFORE 04/24/2026';

      expect(
        parser.shouldUseFreshProduceMode(text, hasBarcodeDetected: true),
        isFalse,
      );
    });

    test(
      'extracts key sticker fields and infers fish/seafood classification',
      () {
        const text =
            'ATLANTIC SALMON FILLET\n0.742 KG @ 24.99/KG\nTOTAL 18.54\nPACK DATE 04/21/2026\nBEST BEFORE 04/24/2026';

        final result = parser.parseLabel(
          text,
          hasBarcodeDetected: false,
          now: DateTime(2026, 1, 1),
        );

        expect(result.isLikelyFreshProduce, isTrue);
        expect(result.productDescription, 'Atlantic Salmon Fillet');
        expect(result.netWeightValue, closeTo(0.742, 0.0001));
        expect(result.netWeightUnit, Unit.kg);
        expect(result.pricePerWeight, closeTo(24.99, 0.001));
        expect(result.totalPrice, closeTo(18.54, 0.001));
        expect(result.packDate, DateTime(2026, 4, 21));
        expect(result.bestBeforeDate, DateTime(2026, 4, 24));
        expect(result.classification, FreshProduceClassification.fishSeafood);
        expect(result.suggestedCategory, ItemCategory.meat);
        expect(result.extractedFieldCount, greaterThanOrEqualTo(5));
      },
    );

    test('classifies deli labels distinctly', () {
      const text =
          'BLACK FOREST HAM\n0.400 KG @ 12.49/KG\nTOTAL 5.00\nBEST BEFORE 04/20/2026';

      final result = parser.parseLabel(
        text,
        hasBarcodeDetected: false,
        now: DateTime(2026, 1, 1),
      );

      expect(result.classification, FreshProduceClassification.deliPrepared);
      expect(result.suggestedCategory, ItemCategory.other);
    });

    test(
      'marks parse as fallback when fewer than two fields are extracted',
      () {
        const text = 'MYSTERY LABEL\nONLY A NAME';

        final result = parser.parseLabel(
          text,
          hasBarcodeDetected: false,
          now: DateTime(2026, 1, 1),
        );

        expect(result.extractedFieldCount, lessThan(2));
        expect(result.shouldFallbackToGenericOcr, isTrue);
      },
    );
  });
}
