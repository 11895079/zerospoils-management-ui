import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../../domain/models/item_model.dart';

class FreshItemCvLabel {
  const FreshItemCvLabel({required this.label, required this.confidence});

  final String label;
  final double confidence;

  String get normalizedLabel => label.trim().toLowerCase();
}

class FreshItemCvSuggestion {
  const FreshItemCvSuggestion({
    required this.name,
    required this.category,
    required this.location,
    required this.itemType,
    required this.confidence,
    required this.source,
  });

  final String name;
  final ItemCategory category;
  final StorageLocation location;
  final ItemType itemType;
  final double confidence;
  final String source;
}

class FreshItemCvAnalysis {
  const FreshItemCvAnalysis({required this.labels, required this.suggestions});

  final List<FreshItemCvLabel> labels;
  final List<FreshItemCvSuggestion> suggestions;
}

abstract class FreshItemCvService {
  Future<FreshItemCvAnalysis> analyzeImage(String imagePath);

  void dispose();
}

final freshItemCvServiceProvider = Provider<FreshItemCvService>((ref) {
  final service = MlKitFreshItemCvService();
  ref.onDispose(service.dispose);
  return service;
});

class MlKitFreshItemCvService implements FreshItemCvService {
  MlKitFreshItemCvService({ImageLabeler? labeler, FreshItemCvMapper? mapper})
    : _labeler =
          labeler ??
          ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55)),
      _mapper = mapper ?? const FreshItemCvMapper(),
      _ownsLabeler = labeler == null;

  final ImageLabeler _labeler;
  final FreshItemCvMapper _mapper;
  final bool _ownsLabeler;

  @override
  Future<FreshItemCvAnalysis> analyzeImage(String imagePath) async {
    final labels = await _labeler.processImage(
      InputImage.fromFilePath(imagePath),
    );
    final normalizedLabels = labels
        .map(
          (label) => FreshItemCvLabel(
            label: label.label,
            confidence: label.confidence,
          ),
        )
        .toList();
    return _mapper.mapAnalysis(normalizedLabels);
  }

  @override
  void dispose() {
    if (_ownsLabeler) {
      _labeler.close();
    }
  }
}

class FreshItemCvMapper {
  const FreshItemCvMapper();

  FreshItemCvAnalysis mapAnalysis(List<FreshItemCvLabel> labels) {
    final sortedLabels = [...labels]
      ..sort((left, right) => right.confidence.compareTo(left.confidence));

    final suggestionsByName = <String, FreshItemCvSuggestion>{};
    for (final label in sortedLabels) {
      final suggestion = _mapLabel(label);
      if (suggestion == null) {
        continue;
      }

      final existing = suggestionsByName[suggestion.name];
      if (existing == null || suggestion.confidence > existing.confidence) {
        suggestionsByName[suggestion.name] = suggestion;
      }
    }

    final suggestions = suggestionsByName.values.toList()
      ..sort((left, right) => right.confidence.compareTo(left.confidence));

    return FreshItemCvAnalysis(labels: sortedLabels, suggestions: suggestions);
  }

  FreshItemCvSuggestion? _mapLabel(FreshItemCvLabel label) {
    final normalized = label.normalizedLabel;

    if (_matchesAny(normalized, const ['banana', 'plantain'])) {
      return _rawSuggestion(
        name: 'Banana',
        category: ItemCategory.produce,
        label: label,
      );
    }
    if (_matchesAny(normalized, const [
      'apple',
      'pear',
      'orange',
      'lemon',
      'lime',
      'avocado',
    ])) {
      return _rawSuggestion(
        name: _titleCase(normalized),
        category: ItemCategory.produce,
        label: label,
      );
    }
    if (_matchesAny(normalized, const [
      'lettuce',
      'tomato',
      'onion',
      'potato',
      'carrot',
      'broccoli',
      'pepper',
      'spinach',
      'cucumber',
      'vegetable',
      'produce',
      'fruit',
    ])) {
      return _rawSuggestion(
        name: _friendlyProduceName(normalized),
        category: ItemCategory.produce,
        label: label,
      );
    }
    if (_matchesAny(normalized, const [
      'milk',
      'cheese',
      'butter',
      'yogurt',
      'egg',
    ])) {
      return FreshItemCvSuggestion(
        name: _friendlyDairyName(normalized),
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        itemType: ItemType.raw,
        confidence: label.confidence,
        source: 'mlkit_image_labeling',
      );
    }
    if (_matchesAny(normalized, const [
      'chicken',
      'beef',
      'pork',
      'steak',
      'turkey',
      'bacon',
      'sausage',
      'lamb',
      'meat',
      'fish',
      'salmon',
      'shrimp',
      'seafood',
    ])) {
      return FreshItemCvSuggestion(
        name: _friendlyMeatName(normalized),
        category: ItemCategory.meat,
        location: StorageLocation.fridge,
        itemType: ItemType.raw,
        confidence: label.confidence,
        source: 'mlkit_image_labeling',
      );
    }
    if (_matchesAny(normalized, const [
      'bread',
      'pasta',
      'rice',
      'cereal',
      'flour',
      'can',
      'canned',
      'jar',
    ])) {
      return FreshItemCvSuggestion(
        name: _friendlyPantryName(normalized),
        category: ItemCategory.pantry,
        location: StorageLocation.pantry,
        itemType: ItemType.raw,
        confidence: label.confidence,
        source: 'mlkit_image_labeling',
      );
    }
    if (_matchesAny(normalized, const [
      'pizza',
      'soup',
      'stew',
      'casserole',
      'pasta dish',
      'sandwich',
      'meal',
      'leftover',
      'cooked',
      'fried',
      'curry',
      'dish',
    ])) {
      return FreshItemCvSuggestion(
        name: _friendlyPreparedName(normalized),
        category: ItemCategory.other,
        location: StorageLocation.fridge,
        itemType: ItemType.prepared,
        confidence: label.confidence,
        source: 'mlkit_image_labeling',
      );
    }

    return null;
  }

  FreshItemCvSuggestion _rawSuggestion({
    required String name,
    required ItemCategory category,
    required FreshItemCvLabel label,
  }) {
    return FreshItemCvSuggestion(
      name: name,
      category: category,
      location: StorageLocation.fridge,
      itemType: ItemType.raw,
      confidence: label.confidence,
      source: 'mlkit_image_labeling',
    );
  }

  bool _matchesAny(String label, List<String> values) {
    for (final value in values) {
      if (label.contains(value)) {
        return true;
      }
    }
    return false;
  }

  String _friendlyProduceName(String label) {
    if (label.contains('fruit')) {
      return 'Fresh fruit';
    }
    if (label.contains('vegetable') || label.contains('produce')) {
      return 'Fresh produce';
    }
    return _titleCase(label);
  }

  String _friendlyDairyName(String label) {
    if (label.contains('yogurt')) {
      return 'Yogurt';
    }
    if (label.contains('egg')) {
      return 'Eggs';
    }
    return _titleCase(label);
  }

  String _friendlyMeatName(String label) {
    if (label.contains('fish') ||
        label.contains('salmon') ||
        label.contains('shrimp') ||
        label.contains('seafood')) {
      return 'Fresh seafood';
    }
    if (label.contains('meat')) {
      return 'Fresh meat';
    }
    return _titleCase(label);
  }

  String _friendlyPantryName(String label) {
    if (label.contains('can') || label.contains('canned')) {
      return 'Canned goods';
    }
    if (label.contains('jar')) {
      return 'Jarred goods';
    }
    return _titleCase(label);
  }

  String _friendlyPreparedName(String label) {
    if (label.contains('leftover')) {
      return 'Leftovers';
    }
    if (label.contains('meal') || label.contains('dish')) {
      return 'Prepared meal';
    }
    return _titleCase(label);
  }

  String _titleCase(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return value;
    }

    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
