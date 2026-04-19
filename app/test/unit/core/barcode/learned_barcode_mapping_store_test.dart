import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/barcode/learned_barcode_mapping_store.dart';
import 'package:zerospoils/core/barcode/local_barcode_catalog.dart';
import 'package:zerospoils/domain/models/item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LearnedBarcodeMappingStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = LearnedBarcodeMappingStore();
  });

  test('saveMapping stores and returns learned barcode suggestions', () async {
    await store.saveMapping(
      rawValue: '055000132152',
      name: 'Vanilla Yogurt',
      category: ItemCategory.dairy,
    );

    final suggestion = await store.getSuggestion('055000132152');

    expect(suggestion, isNotNull);
    expect(suggestion?.name, 'Vanilla Yogurt');
    expect(suggestion?.category, ItemCategory.dairy);
    expect(suggestion?.source, 'learned_local');
  });

  test('saveMapping ignores invalid barcode values', () async {
    await store.saveMapping(
      rawValue: 'abc',
      name: 'Should Not Save',
      category: ItemCategory.other,
    );

    final suggestion = await store.getSuggestion('abc');
    expect(suggestion, isNull);
  });

  test('learned mapping overrides seed catalog for same barcode', () async {
    // The seed catalog contains Greek Plain Yogurt for this barcode.
    const seedBarcode = '0059161402208';
    final seedSuggestion = lookupBarcodeSuggestion(seedBarcode);
    expect(seedSuggestion, isNotNull);

    // Save a user-confirmed override.
    await store.saveMapping(
      rawValue: seedBarcode,
      name: 'Vanilla Yogurt Override',
      category: ItemCategory.dairy,
    );

    // Simulate lookup precedence: learned first, seed second.
    final learnedSuggestion = await store.getSuggestion(seedBarcode);
    final effectiveSuggestion = learnedSuggestion ?? seedSuggestion;

    expect(effectiveSuggestion?.name, 'Vanilla Yogurt Override');
    expect(effectiveSuggestion?.source, 'learned_local');
  });

  test('falls back to seed catalog when no learned mapping exists', () async {
    const seedBarcode = '0059161402208';
    final learnedSuggestion = await store.getSuggestion(seedBarcode);
    // No learned entry → should be null, allowing seed catalog to be used.
    expect(learnedSuggestion, isNull);

    final seedSuggestion = lookupBarcodeSuggestion(seedBarcode);
    expect(seedSuggestion, isNotNull);
    expect(seedSuggestion?.source, 'seed_catalog');
  });

  test('seed catalog resolves confirmed Nescafe coffee barcode', () {
    const coffeeBarcode = '055000132152';
    final suggestion = lookupBarcodeSuggestion(coffeeBarcode);
    expect(suggestion, isNotNull);
    expect(suggestion?.name, 'Instant Coffee');
    expect(suggestion?.category, ItemCategory.pantry);
    expect(suggestion?.source, 'seed_catalog');
  });

  test(
    'returns null for unknown barcodes not in learned or seed catalog',
    () async {
      const unknownBarcode = '09999999999999';
      final learned = await store.getSuggestion(unknownBarcode);
      final seed = lookupBarcodeSuggestion(unknownBarcode);
      expect(learned, isNull);
      expect(seed, isNull);
    },
  );

  test('saved mapping persists across store instances', () async {
    await store.saveMapping(
      rawValue: '0068100083095',
      name: 'Organic Spinach',
      category: ItemCategory.produce,
    );

    final secondStore = LearnedBarcodeMappingStore();
    final suggestion = await secondStore.getSuggestion('0068100083095');
    expect(suggestion?.name, 'Organic Spinach');
    expect(suggestion?.source, 'learned_local');
  });

  test('saveMapping trims empty names and does not persist them', () async {
    await store.saveMapping(
      rawValue: '0059161701752',
      name: '   ',
      category: ItemCategory.dairy,
    );

    final suggestion = await store.getSuggestion('0059161701752');
    expect(suggestion, isNull);
  });

  _catalogTests();
}

// ─── LocalBarcodeCatalog JSON loading tests ───────────────────────────────

class _FakeAssetBundle extends Fake implements AssetBundle {
  _FakeAssetBundle(this._json);
  final String _json;

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _json;
}

void _catalogTests() {
  group('LocalBarcodeCatalog.fromAsset', () {
    test('loads product name and category from JSON', () async {
      final json = jsonEncode({
        'metadata': {'dataset_version': '2026-04-14'},
        'records': [
          {
            'barcode': '055000132152',
            'product_name': 'Instant Coffee',
            'category_hint': 'pantry',
            'source': 'openfoodfacts-manual-curation',
          },
        ],
      });
      final catalog = await LocalBarcodeCatalog.fromAsset(
        _FakeAssetBundle(json),
      );
      final result = catalog.lookup('055000132152');
      expect(result, isNotNull);
      expect(result!.name, 'Instant Coffee');
      expect(result.category, ItemCategory.pantry);
      expect(result.source, 'openfoodfacts-manual-curation');
    });

    test(
      'falls back to compiled-in map when barcode absent from JSON',
      () async {
        final json = jsonEncode({'metadata': {}, 'records': []});
        final catalog = await LocalBarcodeCatalog.fromAsset(
          _FakeAssetBundle(json),
        );
        // 0059161402208 is in the compiled-in _seedCatalog
        final result = catalog.lookup('0059161402208');
        expect(result, isNotNull);
        expect(result!.name, 'Greek Plain Yogurt');
      },
    );

    test('JSON record overrides compiled-in entry for same barcode', () async {
      final json = jsonEncode({
        'metadata': {},
        'records': [
          {
            'barcode': '0059161402208',
            'product_name': 'Updated Yogurt Name',
            'category_hint': 'dairy',
            'source': 'ota_update',
          },
        ],
      });
      final catalog = await LocalBarcodeCatalog.fromAsset(
        _FakeAssetBundle(json),
      );
      final result = catalog.lookup('0059161402208');
      expect(result!.name, 'Updated Yogurt Name');
      expect(result.source, 'ota_update');
    });

    test('lookup returns null for unknown barcode', () async {
      final json = jsonEncode({'metadata': {}, 'records': []});
      final catalog = await LocalBarcodeCatalog.fromAsset(
        _FakeAssetBundle(json),
      );
      expect(catalog.lookup('00000000000000'), isNull);
    });
  });
}
