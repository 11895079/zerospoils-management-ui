import '../../domain/models/item_model.dart';

class BarcodeProductSuggestion {
  const BarcodeProductSuggestion({
    required this.name,
    required this.category,
    required this.source,
  });

  final String name;
  final ItemCategory category;
  final String source;
}

String? normalizeBarcodeValue(String rawValue) {
  final digitsOnly = rawValue.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length < 8 || digitsOnly.length > 14) {
    return null;
  }
  return digitsOnly;
}

BarcodeProductSuggestion? lookupBarcodeSuggestion(String rawValue) {
  final normalized = normalizeBarcodeValue(rawValue);
  if (normalized == null) {
    return null;
  }

  return _seedCatalog[normalized];
}

const Map<String, BarcodeProductSuggestion> _seedCatalog = {
  '0678000012345': BarcodeProductSuggestion(
    name: 'Greek Yogurt',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '062639122245': BarcodeProductSuggestion(
    name: 'Whole Milk',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '060383713339': BarcodeProductSuggestion(
    name: 'Baby Spinach',
    category: ItemCategory.produce,
    source: 'seed_catalog',
  ),
};
