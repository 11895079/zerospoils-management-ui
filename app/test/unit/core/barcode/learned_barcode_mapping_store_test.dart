import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/barcode/learned_barcode_mapping_store.dart';
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
}
