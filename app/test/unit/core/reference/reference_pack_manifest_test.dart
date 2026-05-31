import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/reference/reference_pack_manifest.dart';

void main() {
  group('ReferencePackManifest.parse', () {
    test('parses valid manifest with supported pack types', () {
      const manifestJson = '''
{
  "schema_version": 1,
  "generated_at": "2026-05-30T00:00:00Z",
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v3",
      "checksum": "abc123",
      "minimum_app_version": "1.0.0",
      "download_url": "https://example.com/barcode-ca-v3.json"
    }
  ]
}
''';

      final manifest = ReferencePackManifest.parse(manifestJson);

      expect(manifest.schemaVersion, 1);
      expect(manifest.generatedAt, isNotNull);
      expect(manifest.packs, hasLength(1));
      expect(manifest.packs.first.type, ReferencePackType.barcodeCatalog);
      expect(manifest.packs.first.region, 'ca');
    });

    test('throws when required fields are missing', () {
      const manifestJson = '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "version": "v3"
    }
  ]
}
''';

      expect(
        () => ReferencePackManifest.parse(manifestJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when pack type is unsupported', () {
      const manifestJson = '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "inventory_snapshot",
      "region": "ca",
      "version": "v1",
      "checksum": "abc123",
      "minimum_app_version": "1.0.0",
      "download_url": "https://example.com/snapshot.json"
    }
  ]
}
''';

      expect(
        () => ReferencePackManifest.parse(manifestJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
