import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/vision/batch_goods_photo_service.dart';
import 'package:zerospoils/core/vision/fresh_item_cv_service.dart';
import 'package:zerospoils/domain/models/item_model.dart';

class FakeFreshItemCvService implements FreshItemCvService {
  FakeFreshItemCvService(this.responses);

  final Map<String, FreshItemCvAnalysis> responses;

  @override
  Future<FreshItemCvAnalysis> analyzeImage(String imagePath) async {
    return responses[imagePath] ??
        const FreshItemCvAnalysis(labels: [], suggestions: []);
  }

  @override
  void dispose() {}
}

void main() {
  test('batch goods photo service deduplicates best suggestions', () async {
    final service = MlKitBatchGoodsPhotoService(
      FakeFreshItemCvService({
        'goods-1.jpg': const FreshItemCvAnalysis(
          labels: [FreshItemCvLabel(label: 'banana', confidence: 0.91)],
          suggestions: [
            FreshItemCvSuggestion(
              name: 'Banana',
              category: ItemCategory.produce,
              location: StorageLocation.fridge,
              itemType: ItemType.raw,
              confidence: 0.91,
              source: 'test',
            ),
          ],
        ),
        'goods-2.jpg': const FreshItemCvAnalysis(
          labels: [FreshItemCvLabel(label: 'banana', confidence: 0.97)],
          suggestions: [
            FreshItemCvSuggestion(
              name: 'Banana',
              category: ItemCategory.produce,
              location: StorageLocation.fridge,
              itemType: ItemType.raw,
              confidence: 0.97,
              source: 'test',
            ),
            FreshItemCvSuggestion(
              name: 'Fresh meat',
              category: ItemCategory.meat,
              location: StorageLocation.fridge,
              itemType: ItemType.raw,
              confidence: 0.72,
              source: 'test',
            ),
          ],
        ),
      }),
    );

    final suggestions = await service.analyzePhotoPaths([
      'goods-1.jpg',
      'goods-2.jpg',
    ]);

    expect(suggestions, hasLength(2));
    expect(suggestions.first.name, 'Banana');
    expect(suggestions.first.confidence, 0.97);
    expect(suggestions.last.name, 'Fresh meat');
  });
}
