import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/item_model.dart';
import '../reference/reference_pack_service.dart';

class BarcodeProductSuggestion {
  const BarcodeProductSuggestion({
    required this.name,
    required this.category,
    required this.source,
    this.brand,
  });

  final String name;
  final ItemCategory category;
  final String source;
  final String? brand;
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

/// Maps a category_hint string (including non-enum values from the seed JSON)
/// to an [ItemCategory]. Extended hints like beverages, condiments, snacks,
/// protein, frozen, and bakery are mapped to the closest app category.
ItemCategory _categoryFromHint(String hint) {
  switch (hint.toLowerCase()) {
    case 'produce':
      return ItemCategory.produce;
    case 'dairy':
      return ItemCategory.dairy;
    case 'meat':
    case 'protein':
      return ItemCategory.meat;
    case 'grains':
    case 'bakery':
      return ItemCategory.grains;
    case 'pantry':
    case 'beverages':
    case 'condiments':
    case 'snacks':
      return ItemCategory.pantry;
    case 'frozen':
    default:
      return ItemCategory.other;
  }
}

/// Catalog that merges the compiled-in seed map with an asset-loaded overlay.
/// The asset JSON is authoritative: any record it contains takes priority over
/// the compiled-in map, so a fresh JSON asset alone can update suggestions OTA.
class LocalBarcodeCatalog {
  LocalBarcodeCatalog._({
    required Map<String, BarcodeProductSuggestion> downloaded,
    required Map<String, BarcodeProductSuggestion> overlay,
  }) : _downloaded = downloaded,
       _overlay = overlay;

  final Map<String, BarcodeProductSuggestion> _downloaded;

  final Map<String, BarcodeProductSuggestion> _overlay;

  static const _assetPath = 'assets/reference-data/barcode_seed_ca.v2.json';

  static Future<LocalBarcodeCatalog> fromAsset([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    Map<String, BarcodeProductSuggestion> downloaded = const {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final records = ReferencePackService.activeBarcodeCatalogRecords(prefs);
      downloaded = _recordsToSuggestions(
        records,
        defaultSource: 'reference_pack',
      );
    } catch (_) {
      downloaded = const {};
    }

    try {
      final jsonStr = await b.loadString(_assetPath);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return LocalBarcodeCatalog._(downloaded: downloaded, overlay: const {});
      }

      final records = decoded['records'];
      if (records is! List) {
        return LocalBarcodeCatalog._(downloaded: downloaded, overlay: const {});
      }

      final overlay = _recordsToSuggestions(
        records,
        defaultSource: 'seed_catalog',
      );
      return LocalBarcodeCatalog._(downloaded: downloaded, overlay: overlay);
    } catch (_) {
      return LocalBarcodeCatalog._(downloaded: downloaded, overlay: const {});
    }
  }

  /// Look up a raw barcode value (normalizes + validates checksum internally).
  BarcodeProductSuggestion? lookup(String rawValue) {
    final normalized = normalizeBarcodeValue(rawValue);
    if (normalized == null) return null;
    // Precedence for M3/206:
    // learned/user-defined (handled by caller) -> downloaded pack -> asset -> seed
    return _downloaded[normalized] ??
        _overlay[normalized] ??
        _seedCatalog[normalized];
  }

  static Map<String, BarcodeProductSuggestion> _recordsToSuggestions(
    List<dynamic> records, {
    required String defaultSource,
  }) {
    final result = <String, BarcodeProductSuggestion>{};

    for (final row in records) {
      if (row is! Map<String, dynamic>) continue;

      final barcode = row['barcode'] as String?;
      final name = row['product_name'] as String?;
      final normalizedBarcode = barcode == null
          ? null
          : normalizeBarcodeValue(barcode);

      if (normalizedBarcode == null || name == null || name.isEmpty) {
        continue;
      }

      final catHint = row['category_hint'] as String? ?? '';
      result[normalizedBarcode] = BarcodeProductSuggestion(
        name: name,
        category: _categoryFromHint(catHint),
        source: row['source'] as String? ?? defaultSource,
      );
    }

    return result;
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
