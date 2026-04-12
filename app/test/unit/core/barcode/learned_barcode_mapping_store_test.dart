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
      rawValue: '0678000012345',
      name: 'Vanilla Yogurt',
      category: ItemCategory.dairy,
    );

    final suggestion = await store.getSuggestion('0678000012345');

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
    // The seed catalog contains Greek Yogurt for this barcode.
    const seedBarcode = '0678000012345';
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
    const seedBarcode = '0678000012345';
    final learnedSuggestion = await store.getSuggestion(seedBarcode);
    // No learned entry → should be null, allowing seed catalog to be used.
    expect(learnedSuggestion, isNull);

    final seedSuggestion = lookupBarcodeSuggestion(seedBarcode);
    expect(seedSuggestion, isNotNull);
    expect(seedSuggestion?.source, 'seed_catalog');
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
      rawValue: '060383713339',
      name: 'Organic Spinach',
      category: ItemCategory.produce,
    );

    final secondStore = LearnedBarcodeMappingStore();
    final suggestion = await secondStore.getSuggestion('060383713339');
    expect(suggestion?.name, 'Organic Spinach');
    expect(suggestion?.source, 'learned_local');
  });

  test('saveMapping trims empty names and does not persist them', () async {
    await store.saveMapping(
      rawValue: '062639122245',
      name: '   ',
      category: ItemCategory.dairy,
    );

    final suggestion = await store.getSuggestion('062639122245');
    expect(suggestion, isNull);
  });
}
