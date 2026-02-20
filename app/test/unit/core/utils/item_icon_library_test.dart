library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/utils/item_icon_library.dart';
import 'package:zerospoils/domain/models/item_model.dart';

void main() {
  group('ItemIconLibrary', () {
    test('returns apple icon for apple items', () {
      expect(ItemIconLibrary.getIconForItem('Apple'), Icons.apple);
      expect(ItemIconLibrary.getIconForItem('apple'), Icons.apple);
      expect(ItemIconLibrary.getIconForItem('Apples'), Icons.apple);
    });

    test('returns correct icon for common items', () {
      expect(ItemIconLibrary.getIconForItem('Chicken'), Icons.set_meal);
      expect(ItemIconLibrary.getIconForItem('Milk'), Icons.local_drink);
      expect(ItemIconLibrary.getIconForItem('Bread'), Icons.bakery_dining);
      expect(ItemIconLibrary.getIconForItem('Eggs'), Icons.egg);
      expect(ItemIconLibrary.getIconForItem('Pasta'), Icons.ramen_dining);
    });

    test('returns international food icons', () {
      expect(ItemIconLibrary.getIconForItem('Amala'), Icons.ramen_dining);
      expect(ItemIconLibrary.getIconForItem('Dhal'), Icons.ramen_dining);
      expect(ItemIconLibrary.getIconForItem('Ramen'), Icons.ramen_dining);
      expect(ItemIconLibrary.getIconForItem('Curry'), Icons.ramen_dining);
    });

    test('handles whitespace in item names', () {
      expect(ItemIconLibrary.getIconForItem('  apple  '), Icons.apple);
      expect(ItemIconLibrary.getIconForItem('bell pepper'), Icons.circle);
    });

    test('performs substring matching for partial names', () {
      expect(
        ItemIconLibrary.getIconForItem('cherry tomatoes'),
        Icons.circle, // matches "tomato"
      );
      expect(
        ItemIconLibrary.getIconForItem('red onion'),
        Icons.circle, // matches "onion"
      );
    });

    test('falls back to category icon when item not found', () {
      expect(
        ItemIconLibrary.getIconForItem(
          'UnknownFruit',
          category: ItemCategory.produce,
        ),
        Icons.eco,
      );
      expect(
        ItemIconLibrary.getIconForItem(
          'UnknownDairy',
          category: ItemCategory.dairy,
        ),
        Icons.local_drink,
      );
      expect(
        ItemIconLibrary.getIconForItem(
          'UnknownMeat',
          category: ItemCategory.meat,
        ),
        Icons.set_meal,
      );
      expect(
        ItemIconLibrary.getIconForItem(
          'UnknownGrain',
          category: ItemCategory.grains,
        ),
        Icons.grain,
      );
      expect(
        ItemIconLibrary.getIconForItem(
          'UnknownPantry',
          category: ItemCategory.pantry,
        ),
        Icons.kitchen,
      );
    });

    test('falls back to generic icon when no category provided', () {
      expect(
        ItemIconLibrary.getIconForItem('CompletelyUnknownItem'),
        ItemIconLibrary.genericIcon,
      );
    });

    test('returns correct icon for each category', () {
      expect(ItemIconLibrary.getCategoryIcon(ItemCategory.produce), Icons.eco);
      expect(
        ItemIconLibrary.getCategoryIcon(ItemCategory.dairy),
        Icons.local_drink,
      );
      expect(
        ItemIconLibrary.getCategoryIcon(ItemCategory.meat),
        Icons.set_meal,
      );
      expect(ItemIconLibrary.getCategoryIcon(ItemCategory.grains), Icons.grain);
      expect(
        ItemIconLibrary.getCategoryIcon(ItemCategory.pantry),
        Icons.kitchen,
      );
      expect(
        ItemIconLibrary.getCategoryIcon(ItemCategory.other),
        ItemIconLibrary.genericIcon,
      );
    });

    test('library has reasonable size', () {
      expect(ItemIconLibrary.librarySize, greaterThan(200));
    });

    test('mappedItems returns all keys', () {
      final mapped = ItemIconLibrary.mappedItems;
      expect(mapped, isNotEmpty);
      expect(mapped, contains('apple'));
      expect(mapped, contains('chicken'));
      expect(mapped, contains('milk'));
    });

    test('case insensitive matching works', () {
      expect(ItemIconLibrary.getIconForItem('APPLE'), Icons.apple);
      expect(ItemIconLibrary.getIconForItem('ChIcKeN'), Icons.set_meal);
      expect(ItemIconLibrary.getIconForItem('BANANA'), Icons.set_meal);
    });

    test('handles plural and singular forms', () {
      expect(
        ItemIconLibrary.getIconForItem('apple'),
        ItemIconLibrary.getIconForItem('apples'),
      );
      expect(
        ItemIconLibrary.getIconForItem('egg'),
        ItemIconLibrary.getIconForItem('eggs'),
      );
    });
  });
}
