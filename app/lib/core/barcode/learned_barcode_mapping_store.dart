import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/item_model.dart';
import 'local_barcode_catalog.dart';

class LearnedBarcodeMappingStore {
  static const String _storageKey = 'learned_barcode_mappings';

  Future<BarcodeProductSuggestion?> getSuggestion(String rawValue) async {
    final normalized = normalizeBarcodeValue(rawValue);
    if (normalized == null) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonValue = prefs.getString(_storageKey);
    final decoded = _decodeMappings(jsonValue);
    if (decoded.isEmpty) {
      return null;
    }

    final entry = decoded[normalized];
    if (entry is! Map<String, dynamic>) {
      return null;
    }

    final name = entry['name'];
    final categoryName = entry['category'];
    final brand = entry['brand'];
    if (name is! String || categoryName is! String) {
      return null;
    }

    return BarcodeProductSuggestion(
      name: name,
      category: ItemCategory.fromString(categoryName),
      source: 'learned_local',
      brand: brand is String && brand.trim().isNotEmpty ? brand.trim() : null,
    );
  }

  Future<void> saveMapping({
    required String rawValue,
    required String name,
    required ItemCategory category,
    String? brand,
  }) async {
    final normalized = normalizeBarcodeValue(rawValue);
    if (normalized == null) {
      return;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonValue = prefs.getString(_storageKey);
    final decoded = _decodeMappings(jsonValue);

    final normalizedBrand = brand?.trim();
    decoded[normalized] = {
      'name': trimmedName,
      'category': category.name,
      if (normalizedBrand != null && normalizedBrand.isNotEmpty)
        'brand': normalizedBrand,
    };

    await prefs.setString(_storageKey, jsonEncode(decoded));
  }

  Map<String, dynamic> _decodeMappings(String? jsonValue) {
    if (jsonValue == null || jsonValue.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(jsonValue);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
