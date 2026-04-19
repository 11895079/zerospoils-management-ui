import 'dart:convert';

import 'package:flutter/services.dart';

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

bool _passesGtinChecksum(String digits) {
  // GTIN Luhn-style checksum: alternating weights from right (x3, x1...)
  // The last digit is the check digit.
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    final d = int.parse(digits[digits.length - 1 - i]);
    sum += i == 0 ? d : (i.isOdd ? d * 3 : d);
  }
  return sum % 10 == 0;
}

String? normalizeBarcodeValue(String rawValue) {
  final digitsOnly = rawValue.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length < 8 || digitsOnly.length > 14) {
    return null;
  }
  if (!_passesGtinChecksum(digitsOnly)) {
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

/// Catalog that merges the compiled-in seed map with an asset-loaded overlay.
/// The asset JSON is authoritative: any record it contains takes priority over
/// the compiled-in map, so a fresh JSON asset alone can update suggestions OTA.
class LocalBarcodeCatalog {
  LocalBarcodeCatalog._({
    required Map<String, BarcodeProductSuggestion> overlay,
  }) : _overlay = overlay;

  final Map<String, BarcodeProductSuggestion> _overlay;

  static const _assetPath = 'assets/reference-data/barcode_seed_ca.v1.json';

  static Future<LocalBarcodeCatalog> fromAsset([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final jsonStr = await b.loadString(_assetPath);
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final records = decoded['records'] as List<dynamic>;
    final overlay = <String, BarcodeProductSuggestion>{};
    for (final r in records) {
      final map = r as Map<String, dynamic>;
      final barcode = map['barcode'] as String?;
      final name = map['product_name'] as String?;
      if (barcode == null || name == null) continue;
      final catHint = map['category_hint'] as String? ?? '';
      overlay[barcode] = BarcodeProductSuggestion(
        name: name,
        category: ItemCategory.fromString(catHint),
        source: map['source'] as String? ?? 'seed_catalog',
      );
    }
    return LocalBarcodeCatalog._(overlay: overlay);
  }

  /// Look up a raw barcode value (normalizes + validates checksum internally).
  BarcodeProductSuggestion? lookup(String rawValue) {
    final normalized = normalizeBarcodeValue(rawValue);
    if (normalized == null) return null;
    // Asset-loaded overlay takes priority; compiled-in map is the fallback.
    return _overlay[normalized] ?? _seedCatalog[normalized];
  }
}

const Map<String, BarcodeProductSuggestion> _seedCatalog = {
  '0059161402208': BarcodeProductSuggestion(
    name: 'Greek Plain Yogurt',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '0059161701752': BarcodeProductSuggestion(
    name: 'Plain Yogurt',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '0059161701769': BarcodeProductSuggestion(
    name: 'Vanilla Yogurt',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '0059161702032': BarcodeProductSuggestion(
    name: 'Yogourt Nature',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '0059161702049': BarcodeProductSuggestion(
    name: 'Vanilla',
    category: ItemCategory.dairy,
    source: 'seed_catalog',
  ),
  '0064200010122': BarcodeProductSuggestion(
    name: 'Garden Select Tomato and Basil',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0064200010146': BarcodeProductSuggestion(
    name: 'Garden Select Garlic and Onion',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0064200116206': BarcodeProductSuggestion(
    name: 'Penne Rigate',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0064200116442': BarcodeProductSuggestion(
    name: 'Spaghetti',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0064200116978': BarcodeProductSuggestion(
    name: 'Whole Wheat Spaghettini',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0064200160056': BarcodeProductSuggestion(
    name: 'Gluten Free Macaroni',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100083095': BarcodeProductSuggestion(
    name: 'Extra Creamy Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100083293': BarcodeProductSuggestion(
    name: 'Smooth Light Creamy Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100084214': BarcodeProductSuggestion(
    name: 'Smooth Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100084238': BarcodeProductSuggestion(
    name: 'Crunchy Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100084245': BarcodeProductSuggestion(
    name: 'Smooth Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100084276': BarcodeProductSuggestion(
    name: 'Smooth Peanut Butter',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '0068100084665': BarcodeProductSuggestion(
    name: 'Only Peanuts Smooth',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '030000316832': BarcodeProductSuggestion(
    name: 'Instant Oatmeal Flavor Variety',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
  '055000132152': BarcodeProductSuggestion(
    name: 'Instant Coffee',
    category: ItemCategory.pantry,
    source: 'seed_catalog',
  ),
};
