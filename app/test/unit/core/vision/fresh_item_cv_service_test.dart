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

    test('prefers a specific banana suggestion over generic fruit labels', () {
      final analysis = mapper.mapAnalysis(const [
        FreshItemCvLabel(label: 'fruit', confidence: 0.91),
        FreshItemCvLabel(label: 'banana', confidence: 0.46),
      ]);

      expect(analysis.suggestions, hasLength(1));
      expect(analysis.suggestions.first.name, 'Banana');
      expect(analysis.suggestions.first.category, ItemCategory.produce);
    });

    test(
      'maps grapes specifically instead of falling back to fresh produce',
      () {
        final analysis = mapper.mapAnalysis(const [
          FreshItemCvLabel(label: 'fruit', confidence: 0.88),
          FreshItemCvLabel(label: 'grapes', confidence: 0.73),
          FreshItemCvLabel(label: 'produce', confidence: 0.69),
        ]);

        expect(analysis.suggestions, hasLength(1));
        expect(analysis.suggestions.first.name, 'Grapes');
        expect(analysis.suggestions.first.category, ItemCategory.produce);
      },
    );

    test('returns no suggestions for unrelated labels', () {
      final analysis = mapper.mapAnalysis(const [
        FreshItemCvLabel(label: 'table', confidence: 0.99),
      ]);

      expect(analysis.labels, hasLength(1));
      expect(analysis.suggestions, isEmpty);
    });
  });
}
