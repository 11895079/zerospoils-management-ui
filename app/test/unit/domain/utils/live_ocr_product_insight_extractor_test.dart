import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/utils/live_ocr_product_insight_extractor.dart';

void main() {
  group('LiveOcrProductInsightExtractor', () {
    const extractor = LiveOcrProductInsightExtractor();

    test('extracts likely product information from live OCR text', () {
      final insights = extractor.extract('''
Tangy Lemon grass tea
Ingredients: Lemon Grass
STORE IN A COOL AND DRY PLACE
MFG:11.11.25.BND.00871125
EXP:11.11.27
''');

      expect(insights.productName, 'Tangy Lemon grass tea');
      expect(insights.brandName, 'Tangy');
      expect(insights.productType, 'Lemon grass tea');
      expect(insights.storageHint, 'STORE IN A COOL AND DRY PLACE');
      expect(insights.keywords, contains('Lemon Grass'));
    });

    test('returns empty insights for noise-only OCR text', () {
      final insights = extractor.extract('''
11.11.25
00871125
EXP
''');

      expect(insights.productName, isNull);
      expect(insights.brandName, isNull);
      expect(insights.productType, isNull);
      expect(insights.storageHint, isNull);
      expect(insights.keywords, isEmpty);
    });
  });
}
