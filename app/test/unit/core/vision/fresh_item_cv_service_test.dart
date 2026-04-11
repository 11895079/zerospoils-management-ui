import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/vision/fresh_item_cv_service.dart';
import 'package:zerospoils/domain/models/item_model.dart';

void main() {
  group('FreshItemCvMapper', () {
    const mapper = FreshItemCvMapper();

    test('maps produce labels into a produce suggestion', () {
      final analysis = mapper.mapAnalysis(const [
        FreshItemCvLabel(label: 'banana', confidence: 0.94),
      ]);

      expect(analysis.suggestions, hasLength(1));
      expect(analysis.suggestions.first.name, 'Banana');
      expect(analysis.suggestions.first.category, ItemCategory.produce);
      expect(analysis.suggestions.first.location, StorageLocation.fridge);
      expect(analysis.suggestions.first.itemType, ItemType.raw);
    });

    test('maps meat and prepared labels distinctly', () {
      final analysis = mapper.mapAnalysis(const [
        FreshItemCvLabel(label: 'meat', confidence: 0.82),
        FreshItemCvLabel(label: 'cooked dish', confidence: 0.88),
      ]);

      expect(analysis.suggestions, hasLength(2));
      expect(analysis.suggestions.first.name, 'Prepared meal');
      expect(analysis.suggestions.first.itemType, ItemType.prepared);
      expect(analysis.suggestions.last.category, ItemCategory.meat);
    });

    test('returns no suggestions for unrelated labels', () {
      final analysis = mapper.mapAnalysis(const [
        FreshItemCvLabel(label: 'table', confidence: 0.99),
      ]);

      expect(analysis.labels, hasLength(1));
      expect(analysis.suggestions, isEmpty);
    });
  });
}
