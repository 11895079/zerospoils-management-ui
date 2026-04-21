import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zerospoils/core/barcode/open_food_facts_client.dart';
import 'package:zerospoils/domain/models/item_model.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

MockClient _mockWith(int status, Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

Map<String, dynamic> _successBody({
  required String productName,
  List<String> categoryTags = const [],
}) => {
  'status': 1,
  'product': {
    'product_name': productName,
    'categories_tags': categoryTags,
    'food_groups_tags': <String>[],
  },
};

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('OpenFoodFactsClient', () {
    test('returns suggestion for a known barcode (status 1)', () async {
      final client = OpenFoodFactsClient(
        httpClient: _mockWith(
          200,
          {
            'status': 1,
            'product': {
              'product_name': 'Instant Coffee',
              'brands': 'Nescafe',
              'categories_tags': <String>[],
              'food_groups_tags': <String>[],
            },
          },
        ),
      );
      final result = await client.lookup('055000132152');
      expect(result, isNotNull);
      expect(result!.name, 'Instant Coffee');
      expect(result.brand, 'Nescafe');
      expect(result.source, 'openfoodfacts');
    });

    test(
      'returns null when OpenFoodFacts status is 0 (product not found)',
      () async {
        final client = OpenFoodFactsClient(
          httpClient: _mockWith(200, {'status': 0, 'product': null}),
        );
        expect(await client.lookup('00000000000000'), isNull);
      },
    );

    test('returns null on non-200 HTTP status', () async {
      final client = OpenFoodFactsClient(httpClient: _mockWith(404, {}));
      expect(await client.lookup('055000132152'), isNull);
    });

    test('returns null on network error (does not throw)', () async {
      final client = OpenFoodFactsClient(
        httpClient: MockClient((_) async => throw Exception('no internet')),
      );
      expect(await client.lookup('055000132152'), isNull);
    });

    test('infers dairy category from categories_tags', () async {
      final client = OpenFoodFactsClient(
        httpClient: _mockWith(
          200,
          _successBody(
            productName: 'Greek Yogurt',
            categoryTags: ['en:dairy', 'en:yogurts'],
          ),
        ),
      );
      final result = await client.lookup('0059161402208');
      expect(result!.category, ItemCategory.dairy);
    });

    test('infers produce category from categories_tags', () async {
      final client = OpenFoodFactsClient(
        httpClient: _mockWith(
          200,
          _successBody(
            productName: 'Baby Spinach',
            categoryTags: ['en:vegetables', 'en:fresh-vegetables'],
          ),
        ),
      );
      final result = await client.lookup('0068100083095');
      expect(result!.category, ItemCategory.produce);
    });

    test('defaults to pantry when no recognizable category tags', () async {
      final client = OpenFoodFactsClient(
        httpClient: _mockWith(
          200,
          _successBody(productName: 'Mystery Food', categoryTags: []),
        ),
      );
      final result = await client.lookup('055000132152');
      expect(result!.category, ItemCategory.pantry);
    });

    test('falls back to generic_name when product_name is empty', () async {
      final client = OpenFoodFactsClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': '',
                'generic_name': 'Instant Noodles',
                'categories_tags': <String>[],
                'food_groups_tags': <String>[],
              },
            }),
            200,
          ),
        ),
      );
      final result = await client.lookup('055000132152');
      expect(result!.name, 'Instant Noodles');
    });

    test(
      'returns null when both product_name and generic_name are empty',
      () async {
        final client = OpenFoodFactsClient(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'status': 1,
                'product': {
                  'product_name': '',
                  'generic_name': '  ',
                  'categories_tags': <String>[],
                  'food_groups_tags': <String>[],
                },
              }),
              200,
            ),
          ),
        );
        expect(await client.lookup('055000132152'), isNull);
      },
    );
  });
}
