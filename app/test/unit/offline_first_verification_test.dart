/// Offline-First Verification Suite (M3/230)
///
/// Verifies that the core data paths in ZeroSpoils work correctly without any
/// network access. Each group targets a distinct slice of offline behaviour:
///
///   1. Item inventory — save / read / delete through Hive.
///   2. Shopping list  — persistence and purchased-item filtering.
///   3. Barcode catalog — learned local mappings + seed lookup, no network.
///   4. Expiry parser  — pure Dart, no network.
///   5. Receipt parser — pure Dart, no network.
///
/// All tests use in-memory or temp-directory Hive so they run fully offline
/// in CI without device hardware.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zerospoils/core/barcode/learned_barcode_mapping_store.dart';
import 'package:zerospoils/core/barcode/local_barcode_catalog.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_line_item.dart';
import 'package:zerospoils/domain/models/shopping_list_item.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';
import 'package:zerospoils/domain/utils/receipt_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Item inventory — Hive persistence
  // ──────────────────────────────────────────────────────────────────────────

  group('Offline-first: item inventory (Hive)', () {
    late HiveItemRepository repository;
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('zs_offline_item_');
      Hive.init(tempDir.path);
      for (final entry in _itemAdapters().entries) {
        if (!Hive.isAdapterRegistered(entry.key)) {
          Hive.registerAdapter(entry.value);
        }
      }
    });

    tearDownAll(() async {
      try {
        await Hive.close();
      } finally {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      repository = HiveItemRepository();
      await repository.init();
      await repository.clear();
    });

    test('item saved offline is readable without any network call', () async {
      final item = _makeItem('offline-1', 'Cheddar Cheese', ItemCategory.dairy);
      await repository.saveItem(item);

      final result = await repository.getItem('offline-1');
      expect(result, isNotNull);
      expect(result!.name, 'Cheddar Cheese');
      expect(result.category, ItemCategory.dairy);
    });

    test(
      'items persist across repository re-instantiation (simulated restart)',
      () async {
        final item = _makeItem(
          'offline-2',
          'Sourdough Bread',
          ItemCategory.grains,
        );
        await repository.saveItem(item);
        await repository.close();

        // Simulate a cold restart by creating a new repository instance
        // against the same Hive directory.
        final secondRepo = HiveItemRepository();
        await secondRepo.init();
        final result = await secondRepo.getItem('offline-2');

        expect(result, isNotNull);
        expect(result!.name, 'Sourdough Bread');
      },
    );

    test('deleted item is no longer returned offline', () async {
      final item = _makeItem('offline-3', 'Old Yogurt', ItemCategory.dairy);
      await repository.saveItem(item);
      await repository.deleteItem('offline-3');

      final result = await repository.getItem('offline-3');
      expect(result, isNull);
    });

    test('getAllItems returns all saved items without network', () async {
      await repository.saveItem(_makeItem('a', 'Apple', ItemCategory.produce));
      await repository.saveItem(_makeItem('b', 'Banana', ItemCategory.produce));
      await repository.saveItem(_makeItem('c', 'Carrot', ItemCategory.produce));

      final all = await repository.getAllItems();
      expect(all.length, 3);
      expect(all.map((i) => i.id), containsAll(['a', 'b', 'c']));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Shopping list — Hive persistence
  // ──────────────────────────────────────────────────────────────────────────

  group('Offline-first: shopping list (Hive)', () {
    late HiveShoppingListRepository repository;

    setUp(() async {
      await setUpTestHive();
      repository = HiveShoppingListRepository();
      await repository.init();
      await repository.clear();
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test(
      'shopping list item saved offline is readable without network',
      () async {
        final item = _makeShoppingItem('sl-1', 'Whole Milk');
        await repository.saveShoppingListItem(item);

        final result = await repository.getItem('sl-1');
        expect(result, isNotNull);
        expect(result!.name, 'Whole Milk');
      },
    );

    test('purchased filter works offline', () async {
      await repository.saveShoppingListItem(_makeShoppingItem('sl-2', 'Eggs'));
      await repository.saveShoppingListItem(
        _makeShoppingItem('sl-3', 'Butter', purchased: true),
      );

      final purchased = await repository.getPurchased();
      expect(purchased.length, 1);
      expect(purchased.first.name, 'Butter');
    });

    test('shopping list is empty after clear — offline safe', () async {
      await repository.saveShoppingListItem(_makeShoppingItem('sl-4', 'Flour'));
      await repository.clear();
      final all = await repository.getAllItems();
      expect(all, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Barcode catalog — local lookups only, no network
  // ──────────────────────────────────────────────────────────────────────────

  group('Offline-first: barcode catalog (local only)', () {
    late LearnedBarcodeMappingStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LearnedBarcodeMappingStore();
    });

    test(
      'seed catalog returns suggestion for known barcode without network',
      () {
        final suggestion = lookupBarcodeSuggestion('0678000012345');
        expect(suggestion, isNotNull);
        expect(suggestion!.source, 'seed_catalog');
      },
    );

    test(
      'seed catalog returns null for unknown barcode (no network fallback)',
      () {
        final suggestion = lookupBarcodeSuggestion('00000000000000');
        expect(suggestion, isNull);
      },
    );

    test(
      'learned mapping stored offline is readable without network',
      () async {
        await store.saveMapping(
          rawValue: '0678000012345',
          name: 'Vanilla Yogurt',
          category: ItemCategory.dairy,
        );

        final suggestion = await store.getSuggestion('0678000012345');
        expect(suggestion, isNotNull);
        expect(suggestion!.name, 'Vanilla Yogurt');
        expect(suggestion.source, 'learned_local');
      },
    );

    test(
      'learned mapping takes precedence over seed catalog offline',
      () async {
        const barcode = '0678000012345';
        await store.saveMapping(
          rawValue: barcode,
          name: 'User Yogurt Override',
          category: ItemCategory.dairy,
        );

        final learned = await store.getSuggestion(barcode);
        final seed = lookupBarcodeSuggestion(barcode);

        // Simulates offline lookup precedence: learned first
        final effective = learned ?? seed;
        expect(effective!.name, 'User Yogurt Override');
        expect(effective.source, 'learned_local');
      },
    );

    test('normalizeBarcodeValue rejects short values', () {
      expect(normalizeBarcodeValue('123'), isNull);
    });

    test('normalizeBarcodeValue accepts 8-14 digit values', () {
      expect(normalizeBarcodeValue('12345678'), isNotNull);
      expect(normalizeBarcodeValue('06783123456789'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Expiry date parser — pure Dart, no network
  // ──────────────────────────────────────────────────────────────────────────

  group('Offline-first: expiry date parser (pure Dart)', () {
    const parser = ExpiryDateParser();

    test('parses EXP-labelled date without network', () {
      final result = parser.parse(
        'Best Before EXP 2027-03-31\nGrade A',
        preferredDateFormat: 'MM/DD/YYYY',
      );
      expect(result, isNotNull);
      expect(result!.date.year, 2027);
      expect(result.date.month, 3);
      expect(result.date.day, 31);
    });

    test('prefers EXP label over MFG/manufactured date', () {
      const text = 'MFG 2025-01-15\nEXP 2026-09-30\nLot 42B';
      final result = parser.parse(text, preferredDateFormat: 'MM/DD/YYYY');
      expect(result, isNotNull);
      expect(result!.date.year, 2026);
      expect(result.date.month, 9);
    });

    test('returns null for text without any date', () {
      final result = parser.parse(
        'No dates here at all',
        preferredFormat: 'MM/DD/YYYY',
      );
      expect(result, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Receipt parser — pure Dart, no network
  // ──────────────────────────────────────────────────────────────────────────

  group('Offline-first: receipt parser (pure Dart)', () {
    final parser = ReceiptParser();

    test('parses receipt items without network access', () {
      const receipt = '''
GROCERY
ORGANIC MILK 4L         5.49
WHOLE WHEAT BREAD       3.29
HST 13%                 1.14
TOTAL                   9.92
''';
      final items = parser.parse(receipt);
      expect(items, isNotEmpty);
      final names = items.map((i) => i.name).toList();
      expect(names, anyElement(contains('MILK')));
      expect(names, anyElement(contains('BREAD')));
    });

    test('excludes HST, totals, and loyalty lines', () {
      final result = parser.parseDetailed('''
ITEM A                  4.99
HST                     0.65
TOTAL                   5.64
POINTS EARNED             50
''');
      final itemNames = result.items.map((i) => i.name.toUpperCase()).toList();
      expect(itemNames, everyElement(isNot(contains('HST'))));
      expect(itemNames, everyElement(isNot(contains('TOTAL'))));
      expect(itemNames, everyElement(isNot(contains('POINTS'))));
    });

    test('classified rows report correct classifications', () {
      final result = parser.parseDetailed('''
PRODUCE
APPLE                   1.49
HST 13%                 0.19
TOTAL                   1.68
''');
      final classes = result.rows.map((r) => r.classification).toList();
      expect(
        classes,
        containsAll([
          ReceiptRowClassification.saleItem,
          ReceiptRowClassification.tax,
          ReceiptRowClassification.total,
        ]),
      );
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Item _makeItem(String id, String name, ItemCategory category) {
  return Item(
    id: id,
    name: name,
    category: category,
    location: StorageLocation.fridge,
    status: ItemStatus.active,
    itemType: ItemType.raw,
    quantity: 1,
    unit: Unit.piece,
    expiryDate: DateTime(2027, 6, 1),
    addedAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

ShoppingListItem _makeShoppingItem(
  String id,
  String name, {
  bool purchased = false,
}) {
  final now = DateTime(2026, 4, 1);
  return ShoppingListItem(
    id: id,
    name: name,
    isPurchased: purchased,
    purchasedAt: purchased ? now : null,
    createdAt: now,
    updatedAt: now,
  );
}

/// Returns a map of typeId → TypeAdapter for the Item model adapters.
Map<int, dynamic> _itemAdapters() => {
  0: ItemAdapter(),
  1: ItemCategoryAdapter(),
  2: StorageLocationAdapter(),
  3: ItemStatusAdapter(),
  4: WasteReasonAdapter(),
  5: ItemTypeAdapter(),
  6: UnitAdapter(),
};
