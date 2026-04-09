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
    if (jsonValue == null || jsonValue.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(jsonValue) as Map<String, dynamic>;
    final entry = decoded[normalized];
    if (entry is! Map<String, dynamic>) {
      return null;
    }

    final name = entry['name'];
    final categoryName = entry['category'];
    if (name is! String || categoryName is! String) {
      return null;
    }

    return BarcodeProductSuggestion(
      name: name,
      category: ItemCategory.fromString(categoryName),
      source: 'learned_local',
    );
  }

  Future<void> saveMapping({
    required String rawValue,
    required String name,
    required ItemCategory category,
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
    final decoded = jsonValue == null || jsonValue.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(jsonValue) as Map<String, dynamic>;

    decoded[normalized] = {'name': trimmedName, 'category': category.name};

    await prefs.setString(_storageKey, jsonEncode(decoded));
  }
}
