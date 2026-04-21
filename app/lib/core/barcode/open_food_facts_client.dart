import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/item_model.dart';
import 'local_barcode_catalog.dart';

/// Resolves a barcode against the OpenFoodFacts public API when the barcode is
/// not found in the local seed catalog or learned mappings.
///
/// API: https://world.openfoodfacts.org/api/v2/product/{barcode}.json?fields=...
/// No API key required. OpenFoodFacts data is licensed under ODbL; use may
/// require attribution and compliance with the ODbL terms.
///
/// This is a read-only, best-effort lookup. Network failures return null and
/// do not throw — callers must treat the result as optional.
class OpenFoodFactsClient {
  OpenFoodFactsClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _baseUrl = 'https://world.openfoodfacts.org';
  static const _fields =
      'product_name,generic_name,brands,categories_tags,food_groups_tags';
  static const _timeoutSeconds = 5;

  /// Looks up [barcode] (already normalized, digits-only) against OpenFoodFacts.
  /// Returns a [BarcodeProductSuggestion] on success, or null on miss/error.
  Future<BarcodeProductSuggestion?> lookup(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v2/product/$barcode.json?fields=$_fields',
    );

    try {
      final response = await _http
          .get(uri, headers: {'User-Agent': 'ZeroSpoils/1.0 (Flutter)'})
          .timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null;

      final product = body['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = _extractName(product);
      if (name == null) return null;
      final brand = _extractBrand(product);

      return BarcodeProductSuggestion(
        name: name,
        category: _inferCategory(product),
        source: 'openfoodfacts',
        brand: brand,
      );
    } catch (_) {
      // Network unreachable, timeout, JSON parse error — degrade gracefully.
      return null;
    }
  }

  String? _extractName(Map<String, dynamic> product) {
    final name = product['product_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final generic = product['generic_name'] as String?;
    if (generic != null && generic.trim().isNotEmpty) return generic.trim();
    return null;
  }

  String? _extractBrand(Map<String, dynamic> product) {
    final brands = product['brands'] as String?;
    if (brands == null || brands.trim().isEmpty) return null;
    final primary = brands.split(',').first.trim();
    return primary.isEmpty ? null : primary;
  }

  ItemCategory _inferCategory(Map<String, dynamic> product) {
    final tags = [
      ...(_tagsFrom(product, 'categories_tags')),
      ...(_tagsFrom(product, 'food_groups_tags')),
    ];

    for (final tag in tags) {
      final t = tag.toLowerCase();
      if (t.contains('dairy') ||
          t.contains('milk') ||
          t.contains('yogurt') ||
          t.contains('cheese') ||
          t.contains('butter')) {
        return ItemCategory.dairy;
      }
      if (t.contains('meat') ||
          t.contains('poultry') ||
          t.contains('fish') ||
          t.contains('seafood')) {
        return ItemCategory.meat;
      }
      if (t.contains('fruit') ||
          t.contains('vegetable') ||
          t.contains('produce') ||
          t.contains('fresh')) {
        return ItemCategory.produce;
      }
      if (t.contains('beverage') ||
          t.contains('drink') ||
          t.contains('juice') ||
          t.contains('water') ||
          t.contains('soda')) {
        return ItemCategory.pantry;
      }
      if (t.contains('frozen')) {
        return ItemCategory.other;
      }
      if (t.contains('cereal') ||
          t.contains('grain') ||
          t.contains('bread') ||
          t.contains('pasta') ||
          t.contains('rice') ||
          t.contains('flour')) {
        return ItemCategory.grains;
      }
    }
    return ItemCategory.pantry;
  }

  List<String> _tagsFrom(Map<String, dynamic> product, String key) {
    final raw = product[key];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  /// Closes the underlying HTTP client, releasing any held socket resources.
  void close() => _http.close();
}
