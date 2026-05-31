import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/barcode/local_barcode_catalog.dart';
import 'package:zerospoils/core/reference/reference_pack_keys.dart';

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this._content);

  final String _content;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(_content));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _content;
  }
}

void main() {
  group('LocalBarcodeCatalog precedence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses downloaded pack records before asset/seed records', () async {
      const downloadedPack = {
        'schema_version': 1,
        'records': [
          {
            'barcode': '055000132152',
            'product_name': 'Downloaded Coffee',
            'category_hint': 'pantry',
            'source': 'reference_pack',
          },
        ],
      };

      SharedPreferences.setMockInitialValues({
        ReferencePackKeys.activeBarcodePackRecordsJson: jsonEncode(
          downloadedPack,
        ),
      });

      final assetBundle = _StringAssetBundle(
        jsonEncode({
          'schema_version': 2,
          'records': [
            {
              'barcode': '055000132152',
              'product_name': 'Asset Coffee',
              'category_hint': 'pantry',
              'source': 'seed_catalog',
            },
          ],
        }),
      );

      final catalog = await LocalBarcodeCatalog.fromAsset(assetBundle);
      final suggestion = catalog.lookup('055000132152');

      expect(suggestion, isNotNull);
      expect(suggestion!.name, 'Downloaded Coffee');
      expect(suggestion.source, 'reference_pack');
    });

    test('falls back to asset/seed when downloaded pack is missing', () async {
      final assetBundle = _StringAssetBundle(
        jsonEncode({
          'schema_version': 2,
          'records': [
            {
              'barcode': '055000132152',
              'product_name': 'Asset Coffee',
              'category_hint': 'pantry',
              'source': 'seed_catalog',
            },
          ],
        }),
      );

      final catalog = await LocalBarcodeCatalog.fromAsset(assetBundle);
      final suggestion = catalog.lookup('055000132152');

      expect(suggestion, isNotNull);
      expect(suggestion!.name, 'Asset Coffee');
    });
  });
}
