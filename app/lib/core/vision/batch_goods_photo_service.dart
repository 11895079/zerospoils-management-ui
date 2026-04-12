import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fresh_item_cv_service.dart';

class BatchGoodsPhotoSuggestion {
  const BatchGoodsPhotoSuggestion({
    required this.name,
    required this.confidence,
    required this.source,
  });

  final String name;
  final double confidence;
  final String source;
}

abstract class BatchGoodsPhotoService {
  Future<List<BatchGoodsPhotoSuggestion>> analyzePhotoPaths(
    List<String> photoPaths,
  );
}

final batchGoodsPhotoServiceProvider = Provider<BatchGoodsPhotoService>((ref) {
  return MlKitBatchGoodsPhotoService(ref.read(freshItemCvServiceProvider));
});

class MlKitBatchGoodsPhotoService implements BatchGoodsPhotoService {
  MlKitBatchGoodsPhotoService(this._freshItemCvService);

  final FreshItemCvService _freshItemCvService;

  @override
  Future<List<BatchGoodsPhotoSuggestion>> analyzePhotoPaths(
    List<String> photoPaths,
  ) async {
    final bestByName = <String, BatchGoodsPhotoSuggestion>{};

    for (final path in photoPaths) {
      final analysis = await _freshItemCvService.analyzeImage(path);
      for (final suggestion in analysis.suggestions.take(2)) {
        final key = suggestion.name.trim().toLowerCase();
        final candidate = BatchGoodsPhotoSuggestion(
          name: suggestion.name,
          confidence: suggestion.confidence,
          source: suggestion.source,
        );
        final existing = bestByName[key];
        if (existing == null || candidate.confidence > existing.confidence) {
          bestByName[key] = candidate;
        }
      }
    }

    final results = bestByName.values.toList()
      ..sort((left, right) => right.confidence.compareTo(left.confidence));
    return results;
  }
}
